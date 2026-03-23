return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    search = {
      multi_window = true,
      forward = true,
      wrap = true,
      mode = "exact",
      incremental = false,
      exclude = {
        "notify",
        "cmp_menu",
        "noice",
        "flash_prompt",
        function(win)
          return not vim.api.nvim_win_get_config(win).focusable
        end,
      },
      trigger = "",
      max_length = false,
    },
    -- ラベル数を大幅増加: 4文字から26文字へ
    -- QWERTYキーボード最適化、ホームポジション優先
    labels = "asdfghjklqwertyuiopzxcvbnm",
    jump = {
      jumplist = true,
      pos = "start",
      history = false,
      register = false,
      nohlsearch = false,
      autojump = false,
      inclusive = nil,
      offset = nil,
    },
    label = {
      uppercase = true,  -- 大文字も使用して実質52文字に
      exclude = "",
      current = true,
      after = true,
      before = false,
      style = "overlay",
      reuse = "lowercase",  -- 小文字ラベルの再利用でラベル数増加
      distance = true,
      min_pattern_length = 0,
      rainbow = {
        enabled = false,
        shade = 5,
      },
      format = function(opts)
        return { { opts.match.label, opts.hl_group } }
      end,
    },
    highlight = {
      backdrop = true,
      matches = true,
      priority = 5000,
      groups = {
        match = "FlashMatch",
        current = "FlashCurrent",
        backdrop = "FlashBackdrop",
        label = "FlashLabel",
      },
    },
    action = nil,
    pattern = "",
    continue = false,
    config = nil,
    modes = {
      search = {
        enabled = false,
        highlight = { backdrop = false },
        jump = { history = true, register = true, nohlsearch = true },
        search = {},
      },
      char = { enabled = false },
    },
    prompt = {
      enabled = true,
      prefix = { { "⚡", "FlashPromptIcon" } },
      win_config = {
        relative = "editor",
        width = 1,
        height = 1,
        row = -1,
        col = 0,
        zindex = 1000,
      },
    },
  },
  keys = (function()
    -- 単語境界matcher（CamelCase・日本語境界検出）
    local function word_boundary_matcher(win)
      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local matches = {}

      for lnum, line in ipairs(lines) do
        local col = 1
        while col <= #line do
          local char = line:sub(col, col)
          local prev_char = col > 1 and line:sub(col - 1, col - 1) or ""
          local should_match = false

          -- 基本的な英数字単語境界
          if char:match("%w") and not prev_char:match("%w") then
            should_match = true
          end

          -- CamelCase境界
          if char:match("%u") and prev_char:match("%l") then
            should_match = true
          end

          -- 数字境界
          if char:match("%d") and not prev_char:match("%d") then
            should_match = true
          elseif not char:match("%d") and prev_char:match("%d") and char:match("%w") then
            should_match = true
          end

          -- 日本語文字境界（UTF-8対応）
          local char_byte = char:byte()
          local prev_char_byte = prev_char:byte() or 0

          -- ASCII文字から日本語文字への境界
          if char_byte and char_byte > 127 and prev_char_byte <= 127 then
            should_match = true
          end

          -- 日本語文字からASCII文字への境界
          if char_byte and char_byte <= 127 and prev_char_byte > 127 and char:match("%w") then
            should_match = true
          end

          if should_match then
            table.insert(matches, {
              win = win,
              pos = { lnum, col - 1 },
              end_pos = { lnum, col - 1 },
            })
          end

          col = col + 1
        end
      end

      return matches
    end

    -- 2文字ラベル: 1段階目（1文字目を強調）
    local function format_first(opts)
      return {
        { opts.match.label1, "FlashLabelInactive" },
        { opts.match.label2, "FlashLabelActive" },
      }
    end

    -- 2文字ラベル: 2段階目（2文字目を強調）
    local function format_second(opts)
      return {
        { opts.match.label1, "FlashLabelActive" },
        { opts.match.label2, "FlashLabelInactive" },
      }
    end

    -- 2文字ラベルlabeler（マッチ数がラベル数を超えたら自動拡張）
    local function two_char_labeler(matches, state)
      local labels = state:labels()
      for m, match in ipairs(matches) do
        match.label1 = labels[math.floor((m - 1) / #labels) + 1]
        match.label2 = labels[(m - 1) % #labels + 1]
        match.label = match.label1
      end
    end

    -- F/T migemoローマ字ラベル: accumulated(dim) + next_char(bright)
    local function migemo_format_label(opts)
      local accumulated = opts.match._accumulated or ""
      local label = opts.match.label or ""
      if accumulated == "" then
        return { { label, opts.hl_group } }
      end
      return {
        { accumulated, "FlashLabelInactive" },
        { label, "FlashLabelActive" },
      }
    end

    -- F/T 共通のmigemo検索ジャンプ関数（ローマ字ラベル N段階絞り込み）
    local function migemo_search_jump(offset)
      return function()
        local Flash = require("flash")
        local romaji_label = require("vw.migemo")

        -- ハイライト設定（f/tと共通）
        vim.api.nvim_set_hl(0, "FlashLabelActive", { fg = "#ff007c", bg = "#3b2940", bold = true })
        vim.api.nvim_set_hl(0, "FlashLabelInactive", { fg = "#b05070", bg = "#2a2030" })

        -- 1段階目の検索入力を保持
        local current_search = ""

        -- ローマ字ラベル計算（全段階共通）
        local function assign_romaji_labels(matches, state, accumulated)
          local labels = state:labels()
          local fallback_idx = 0
          for _, match in ipairs(matches) do
            local buf = vim.api.nvim_win_get_buf(match.win)
            local line = vim.api.nvim_buf_get_lines(buf, match.pos[1] - 1, match.pos[1], false)[1] or ""
            local col = match.pos[2] + 1
            local text = line:sub(col)

            local suffix = romaji_label.compute_suffix(text, accumulated)
            if suffix and #suffix >= 1 then
              match.label = suffix:sub(1, 1)
              match._accumulated = accumulated
            else
              -- 漢字等/ローマ字の余りなし: 通常ラベルにフォールバック
              fallback_idx = fallback_idx + 1
              match.label = labels[fallback_idx] or "?"
              match._accumulated = ""
            end
          end
        end

        -- 再帰的ジャンプ: label重複時はさらに絞り込み
        local function do_jump_stage(accumulated, prev_matches)
          local jump_opts = {
            highlight = { backdrop = true, matches = prev_matches and false or nil },
            label = {
              after = false,
              before = { 0, 0 },
              uppercase = false,
              format = migemo_format_label,
            },
            labeler = function(matches, state)
              local acc = prev_matches and accumulated or current_search
              assign_romaji_labels(matches, state, acc)
            end,
            action = function(match, state)
              local same_label = vim.tbl_filter(function(m)
                return m.label == match.label
              end, state.results)

              if #same_label == 1 then
                -- 一意 → 即ジャンプ
                vim.api.nvim_win_set_cursor(match.win, { match.pos[1], match.pos[2] + (offset or 0) })
                return
              end

              -- 重複 → さらに絞り込み
              state:hide()
              local new_acc = (match._accumulated ~= "" and match._accumulated or current_search) .. match.label
              do_jump_stage(new_acc, same_label)
            end,
            jump = { pos = "start", offset = offset, autojump = true },
          }

          if prev_matches then
            -- 2段階目以降: 前段の結果からフィルタ
            jump_opts.matcher = function(win)
              return vim.tbl_filter(function(m) return m.win == win end, prev_matches)
            end
          else
            -- 1段階目: cmigemo検索
            jump_opts.search = {
              mode = function(input)
                if not input or input == "" then return input end
                current_search = input
                local migemo = require("vw.migemo")
                if not migemo.is_available() then return input end
                local pattern = migemo.query(input)
                if pattern and pattern ~= input then
                  return input .. "\\|" .. pattern
                end
                return input
              end,
            }
          end

          Flash.jump(jump_opts)
        end

        do_jump_stage("", nil)
      end
    end

    -- f/t 共通のジャンプ関数
    local function word_boundary_jump(offset)
      return function()
        local Flash = require("flash")

        -- ハイライト設定
        vim.api.nvim_set_hl(0, "FlashLabelActive", { fg = "#ff007c", bg = "#3b2940", bold = true })
        vim.api.nvim_set_hl(0, "FlashLabelInactive", { fg = "#b05070", bg = "#2a2030" })

        Flash.jump({
          labels = "asdfghjklqwertyuiopzxcvbnm",
          matcher = word_boundary_matcher,
          label = {
            after = false,
            before = { 0, 0 },
            uppercase = false,
            format = format_first,
          },
          action = function(match, state)
            state:hide()
            Flash.jump({
              highlight = { backdrop = true, matches = false },
              label = { format = format_second },
              matcher = function(win)
                return vim.tbl_filter(function(m)
                  return m.label1 == match.label and m.win == win
                end, state.results)
              end,
              labeler = function(inner_matches)
                for _, m in ipairs(inner_matches) do
                  m.label = m.label2
                end
              end,
              jump = { pos = "start", offset = offset },
            })
          end,
          labeler = two_char_labeler,
          jump = { pos = "start", offset = offset },
        })
      end
    end

    return {
      {
        "f",
        mode = { "n", "x", "o" },
        word_boundary_jump(0),
        desc = "Flash Word Boundary Jump",
      },
      {
        "t",
        mode = { "n", "x", "o" },
        word_boundary_jump(-1),
        desc = "Flash Word Boundary Jump (before)",
      },
      {
        "F",
        mode = { "n", "x", "o" },
        migemo_search_jump(0),
        desc = "Flash Migemo Search",
      },
      {
        "T",
        mode = { "n", "x", "o" },
        migemo_search_jump(-1),
        desc = "Flash Migemo Search (before)",
      },
    }
  end)(),
}