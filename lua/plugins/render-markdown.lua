-- plugins/render-markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("render-markdown").setup {
        -- オプション設定
        render_modes = { 'n', 'c', 't' },
        
        -- チェックボックスの設定（文字消失問題を回避するため無効化）
        checkbox = {
          enabled = false,  -- シンプルに無効化
        },
        
        -- Callout設定を追加
        callout = {
          note = { raw = '[!note]', rendered = '󰋽 Note', highlight = 'RenderMarkdownInfo' },
          warning = { raw = '[!warning]', rendered = '⚠ Warning', highlight = 'RenderMarkdownWarn' },
          error = { raw = '[!error]', rendered = '󰅚 Error', highlight = 'RenderMarkdownError' },
          info = { raw = '[!info]', rendered = '󰋽 Info', highlight = 'RenderMarkdownInfo' },
          tip = { raw = '[!tip]', rendered = '💡 Tip', highlight = 'RenderMarkdownHint' },
          success = { raw = '[!success]', rendered = '✅ Success', highlight = 'RenderMarkdownSuccess' },
          question = { raw = '[!question]', rendered = '❓ Question', highlight = 'RenderMarkdownInfo' },
          think = { raw = '[!think]', rendered = '🤔 Think', highlight = 'RenderMarkdownThink' },
          idea = { raw = '[!idea]', rendered = '💡 Idea', highlight = 'RenderMarkdownIdea' },
          quote = { raw = '[!quote]', rendered = '💬 Quote', highlight = 'RenderMarkdownQuote' },
          ai = { raw = '[!ai]', rendered = '🤖 AI', highlight = 'RenderMarkdownAI' },
          plan = { raw = '[!plan]', rendered = '📋 Plan', highlight = 'RenderMarkdownPlan' },
        },
      }
      
      -- タスクステータス用ハイライトグループを定義（TaskStatus*で統一）
      -- 未着手 [ ] - グレー
      vim.api.nvim_set_hl(0, 'TaskStatusTodo', {
        fg = '#6c7086',
      })

      -- 実行中 [>] - オレンジ
      vim.api.nvim_set_hl(0, 'TaskStatusInProgress', {
        fg = '#fab387',
        italic = true,
      })

      -- 中断中 [/] - 目立つ赤
      vim.api.nvim_set_hl(0, 'TaskStatusPaused', {
        fg = '#ff6b6b',
        bold = true,
      })

      -- 成功 [v] - ティール + 打ち消し線
      vim.api.nvim_set_hl(0, 'TaskStatusSuccess', {
        fg = '#70D3C4',
        strikethrough = true,
      })

      -- 失敗 [x] - 暗い赤 + 打ち消し線
      vim.api.nvim_set_hl(0, 'TaskStatusFailed', {
        fg = '#8f4050',
        strikethrough = true,
      })

      -- 中止 [-] - 黄色 + 打ち消し線
      vim.api.nvim_set_hl(0, 'TaskStatusCancelled', {
        fg = '#f9e2af',
        strikethrough = true,
      })
      
      -- Callout用のハイライトグループを定義
      vim.api.nvim_set_hl(0, 'RenderMarkdownInfo', { fg = '#89b4fa', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownWarn', { fg = '#f9e2af', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownError', { fg = '#f38ba8', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownHint', { fg = '#a6e3a1', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownSuccess', { fg = '#a6e3a1', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownThink', { fg = '#fab387', bold = true })  -- オレンジ色
      vim.api.nvim_set_hl(0, 'RenderMarkdownIdea', { fg = '#f9e2af', bold = true })   -- 黄色
      vim.api.nvim_set_hl(0, 'RenderMarkdownQuote', { fg = '#b4befe', bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownAI', { fg = '#94e2d5', bold = true })     -- ティール色
      vim.api.nvim_set_hl(0, 'RenderMarkdownPlan', { fg = '#89dceb', bold = true })   -- 青緑色
      
      -- タスクステータスのextmarkハイライト用namespace
      local ns_id = vim.api.nvim_create_namespace('task_status_highlight')

      -- タスクステータスに応じたハイライトを適用する関数
      local function apply_task_highlights(bufnr)
        if vim.bo[bufnr].filetype ~= 'markdown' then return end

        -- 既存のextmarkをクリア
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        for lnum, line in ipairs(lines) do
          local hl_group = nil
          if line:match('^%s*[*-]%s*%[>%]') then
            hl_group = 'TaskStatusInProgress'
          elseif line:match('^%s*[*-]%s*%[/%]') then
            hl_group = 'TaskStatusPaused'
          elseif line:match('^%s*[*-]%s*%[v%]') then
            hl_group = 'TaskStatusSuccess'
          elseif line:match('^%s*[*-]%s*%[x%]') then
            hl_group = 'TaskStatusFailed'
          elseif line:match('^%s*[*-]%s*%[%-%]') then
            hl_group = 'TaskStatusCancelled'
          end

          if hl_group then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum - 1, 0, {
              end_col = #line,
              hl_group = hl_group,
              hl_mode = 'replace',  -- 既存のハイライトを完全に置き換え
              priority = 10000,
            })
          end
        end
      end

      -- タスクハイライトを適用するautocmd
      vim.api.nvim_create_autocmd({"BufEnter", "TextChanged", "TextChangedI", "InsertLeave"}, {
        pattern = "*.md",
        callback = function(ev)
          apply_task_highlights(ev.buf)
        end,
      })
    end,
  },
}
