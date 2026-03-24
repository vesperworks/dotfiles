return {
  -- dropbar.nvim - パンくずリスト付きIDE風breadcrumbs
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPost",
    config = function()
      local dropbar = require('dropbar')
      
      -- Markdown用のカスタム設定
      dropbar.setup({
        bar = {
          hover = true,
          sources = function(buf, _)
            local sources = require('dropbar.sources')
            local utils = require('dropbar.utils')
            if vim.bo[buf].ft == 'markdown' then
              return {
                sources.path,
                sources.markdown,
                sources.treesitter,
              }
            end
            return {
              sources.path,
              utils.source.fallback({
                sources.lsp,
                sources.treesitter,
              }),
            }
          end,
        },
        menu = {
          -- パンくずリストメニューの設定
          quick_navigation = true,
          entry = {
            padding = {
              left = 1,
              right = 1,
            },
          },
          keymaps = {
            ['q'] = '<C-w>q',
            ['<Esc>'] = '<C-w>q',
            ['<CR>'] = function()
              local menu = require('dropbar.utils').menu.get_current()
              if menu then
                local cursor = vim.api.nvim_win_get_cursor(menu.win)
                menu:click_on(cursor[1], nil, 1, 'l')
              end
            end,
          },
        },
      })
      
    end,
    keys = {
      { "<leader>dp", function() require('dropbar.api').pick() end, desc = "パンくずリストナビ" },
    },
  },

  -- zen-mode.nvim - 安定したZenモード
  {
    "folke/zen-mode.nvim",
    dependencies = { "joshuadanpeterson/typewriter.nvim" },
    keys = {
      { "<leader>z", function()
        -- Zen Mode + Typewriter を同時トグル
        vim.cmd("ZenMode")
        -- TWToggle はプラグインがロードされている場合のみ実行
        if vim.fn.exists(":TWToggle") == 2 then
          vim.cmd("TWToggle")
        end
      end, desc = "Zen + Typewriter トグル" },
      { "<leader>zm", "<cmd>ZenMode<cr>", desc = "Zen Mode トグル" },
      { "<leader>Z", function()
        -- Zen Writing Mode: 新規ファイル作成 → Zen Mode起動
        local vault_path = vim.env.OBSIDIAN_VAULT_PATH or
          "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault"
        local date = os.date("%Y%m%d")
        local time = os.date("%H%M")
        local filename = string.format("zen%s-%s.md", date, time)
        local full_path = vim.fn.expand(vault_path) .. "/Inbox/" .. filename

        -- ディレクトリ作成（存在しない場合）
        vim.fn.mkdir(vim.fn.fnamemodify(full_path, ":h"), "p")

        -- ファイルを開く
        vim.cmd("edit " .. vim.fn.fnameescape(full_path))

        -- 新規ファイルの場合、テンプレート挿入
        if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
          local daily_link = string.format("[[%s]]", os.date("%Y-%m-%d"))
          vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# ", "", daily_link })
          -- カーソルを1行目の # の後ろに配置
          vim.api.nvim_win_set_cursor(0, { 1, 2 })
        end

        -- Zen Mode + Typewriter 起動
        vim.cmd("ZenMode")
        if vim.fn.exists(":TWToggle") == 2 then
          vim.cmd("TWToggle")
        end
      end, desc = "Zen Writing Mode" },
    },
    config = function()
      -- render-markdown の heading 背景設定を保存
      local saved_backgrounds = nil

      require("zen-mode").setup({
        window = {
          backdrop = 0.95, -- シェード背景
          width = 80, -- 幅（より真ん中寄り）
          height = 1, -- 高さ (1 = 100%)
          options = {
            signcolumn = "no", -- サインカラム無効
            number = false, -- 行番号無効
            relativenumber = false, -- 相対行番号無効
            cursorline = false, -- カーソル行ハイライト無効
            cursorcolumn = false, -- カーソル列ハイライト無効
            foldcolumn = "0", -- fold列無効
            list = false, -- 空白文字無効
          },
        },
        plugins = {
          options = {
            enabled = true,
            ruler = false, -- ルーラー無効
            showcmd = false, -- コマンド表示無効
          },
          twilight = { enabled = true }, -- twilight連携
          gitsigns = { enabled = false }, -- gitsigns無効
          tmux = { enabled = false }, -- tmux連携無効
          kitty = {
            enabled = false,
            font = "+4", -- フォントサイズ増加
          },
        },
        on_open = function()
          -- Zen Mode 開始時: heading 背景を無効化
          local ok, rm = pcall(require, 'render-markdown')
          if ok then
            local config = rm.get_config and rm.get_config()
            if config and config.heading then
              saved_backgrounds = config.heading.backgrounds
              rm.setup({ heading = { backgrounds = {} } })
            end
          end
          -- 冒頭に30行の空行を挿入（カーソル中央化のため）
          local padding_lines = {}
          for i = 1, 30 do
            padding_lines[i] = "·"  -- 薄い記号で識別可能に
          end
          vim.api.nvim_buf_set_lines(0, 0, 0, false, padding_lines)
          -- カーソルを31行目に移動
          vim.api.nvim_win_set_cursor(0, { 31, 0 })
          -- Alacritty透明度を0.05に変更（IPC経由、symlinkを壊さない）
          local wid = vim.env.ALACRITTY_WINDOW_ID
          local w_flag = wid and ("-w " .. wid) or "-w -1"
          vim.fn.system(string.format(
            "/Applications/Alacritty.app/Contents/MacOS/alacritty msg config %s 'window.opacity=0.05'",
            w_flag
          ))
        end,
        on_close = function()
          -- Zen Mode 終了時: heading 背景を復元
          local ok, rm = pcall(require, 'render-markdown')
          if ok and saved_backgrounds then
            rm.setup({ heading = { backgrounds = saved_backgrounds } })
            saved_backgrounds = nil
          end
          -- 冒頭の30行を削除
          vim.api.nvim_buf_set_lines(0, 0, 30, false, {})
          -- Alacritty透明度を0.8に戻す（IPC経由）
          local wid = vim.env.ALACRITTY_WINDOW_ID
          local w_flag = wid and ("-w " .. wid) or "-w -1"
          vim.fn.system(string.format(
            "/Applications/Alacritty.app/Contents/MacOS/alacritty msg config %s 'window.opacity=0.8'",
            w_flag
          ))
        end,
      })
    end,
  },

  -- twilight.nvim ─ 周辺減光
  { "folke/twilight.nvim", opts = { context = 1, dimming = { alpha = 0.5 } } },

  -- typewriter.nvim ─ カーソル常時センター
  {
    "joshuadanpeterson/typewriter.nvim",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    },
    keys = {
      { "<leader>zt", "<cmd>TWToggle<cr>", desc = "Typewriter トグル" },
    },
    opts = {
      keep_cursor_position = true,
      enable_notifications = false,
      enable_horizontal_scroll = false, -- 横軸の動きを無効化
    },
  },
}
