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
      char = {
        enabled = true,
        config = function(opts)
          opts.autohide = opts.autohide or (vim.fn.mode(true):find("no") and vim.v.operator == "y")
          opts.jump_labels = opts.jump_labels
            and vim.v.count == 0
            and vim.fn.mode(true):find("no")
            and vim.v.operator ~= "y"
        end,
        autohide = false,
        jump_labels = false,
        multi_line = true,
        label = { exclude = "hjkliardc" },
        keys = { "t", "T", ";", "," },
        char_actions = function(motion)
          return {
            [";"] = "next",
            [","] = "prev",
            [motion:lower()] = "next",
            [motion:upper()] = "prev",
          }
        end,
        search = { wrap = false },
        highlight = { backdrop = true },
        jump = { register = false },
      },
      treesitter = {
        labels = "asdfghjklqwertyuiopzxcvbnm",
        jump = { pos = "range" },
        search = { incremental = false },
        label = { before = true, after = true, style = "inline" },
        highlight = {
          backdrop = false,
          matches = false,
        },
      },
      treesitter_search = {
        jump = { pos = "range" },
        search = { multi_window = true, wrap = true, incremental = false },
        remote_op = { restore = true },
        label = { before = true, after = true, style = "inline" },
      },
      remote = {
        remote_op = { restore = true, motion = true },
      },
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
    remote_op = {
      restore = false,
      motion = false,
    },
  },
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter",
    },
    {
      "f",
      mode = { "n", "x", "o" },
      function()
        local flash = require("flash")
        
        flash.jump({
          -- ラベル数を大幅増加
          labels = "asdfghjklqwertyuiopzxcvbnm",
          matcher = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local matches = {}
            
            for lnum, line in ipairs(lines) do
              local col = 1
              while col <= #line do
                local char = line:sub(col, col)
                local prev_char = col > 1 and line:sub(col-1, col-1) or ""
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
                    pos = { lnum, col - 1 },  -- (1,0)-indexed
                    end_pos = { lnum, col - 1 },
                  })
                end
                
                col = col + 1
              end
            end
            
            return matches
          end,
        })
      end,
      desc = "Flash Multi-language Word Motion",
    },
    {
      "gr",
      mode = { "n", "x", "o" },
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash",
    },
    {
      "gR",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter_search()
      end,
      desc = "Treesitter Search",
    },
    {
      "<c-s>",
      mode = { "c" },
      function()
        require("flash").toggle()
      end,
      desc = "Toggle Flash Search",
    },
    -- 真の2文字ラベル機能
    {
      "<leader>s",
      mode = { "n", "x", "o" },
      function()
        local Flash = require("flash")

        -- 強調（次に押すキー）: ピンク背景 + 白文字
        vim.api.nvim_set_hl(0, "FlashLabelActive", { fg = "#ffffff", bg = "#ff007c", bold = true })
        -- 非強調: 白背景 + ピンク文字
        vim.api.nvim_set_hl(0, "FlashLabelInactive", { fg = "#ff007c", bg = "#ffffff", bold = true })

        -- 1段階目用: 1文字目を強調（白背景で目立たせる）
        local function formatFirst(opts)
          return {
            { opts.match.label1, "FlashLabelInactive" },  -- 白背景（押すキー）
            { opts.match.label2, "FlashLabelActive" },    -- ピンク背景
          }
        end

        -- 2段階目用: 2文字目を強調（色反転）
        local function formatSecond(opts)
          return {
            { opts.match.label1, "FlashLabelActive" },    -- ピンク背景
            { opts.match.label2, "FlashLabelInactive" },  -- 白背景（押すキー）
          }
        end

        Flash.jump({
          search = { mode = "search" },
          highlight = { backdrop = true },
          label = {
            after = false,
            before = { 0, 0 },
            uppercase = false,
            format = formatFirst
          },
          pattern = [[\<]],
          action = function(match, state)
            state:hide()
            Flash.jump({
              search = { max_length = 0 },
              highlight = { backdrop = true, matches = false },
              label = { format = formatSecond },
              matcher = function(win)
                return vim.tbl_filter(function(m)
                  return m.label == match.label and m.win == win
                end, state.results)
              end,
              labeler = function(matches)
                for _, m in ipairs(matches) do
                  m.label = m.label2
                end
              end,
            })
          end,
          labeler = function(matches, state)
            local labels = state:labels()
            for m, match in ipairs(matches) do
              match.label1 = labels[math.floor((m - 1) / #labels) + 1]
              match.label2 = labels[(m - 1) % #labels + 1]
              match.label = match.label1
            end
          end,
        })
      end,
      desc = "Flash 2-char Labels",
    },
  },
}