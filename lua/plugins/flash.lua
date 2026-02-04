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

    -- F/T 共通のmigemo検索ジャンプ関数
    local function migemo_search_jump(offset)
      return function()
        local Flash = require("flash")

        Flash.jump({
          search = {
            mode = function(input)
              if not input or input == "" then return input end
              local migemo = require("user-plugins.migemo-bridge")
              if not migemo.is_available() then return input end
              local pattern = migemo.query(input)
              if pattern and pattern ~= input then
                return input .. "\\|" .. pattern
              end
              return input
            end,
          },
          jump = { pos = "start", offset = offset },
        })
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
              search = { max_length = 0 },
              highlight = { backdrop = true, matches = false },
              label = { format = format_second },
              matcher = function(win)
                return vim.tbl_filter(function(m)
                  return m.label == match.label and m.win == win
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