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
        },
      }
      
      -- 完了済みタスクのハイライトグループを定義
      vim.api.nvim_set_hl(0, 'RenderMarkdownChecked', {
        fg = '#6c7086',  -- 薄いグレー色
        strikethrough = true,  -- 打ち消し線
      })
      
      vim.api.nvim_set_hl(0, 'RenderMarkdownUnchecked', {
        fg = '#cdd6f4',  -- 通常の色
      })
      
      -- 実行中タスクのハイライトグループを定義
      vim.api.nvim_set_hl(0, 'RenderMarkdownInProgress', {
        fg = '#f9e2af',  -- 黄色っぽい色
        italic = true,   -- イタリック
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
      
      -- タスクのハイライトを適用するautocmd
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          -- 完了済みタスクの行全体にハイライトを適用
          vim.fn.matchadd('RenderMarkdownChecked', '^\\s*[*-]\\s*\\[x\\].*$')
          -- 実行中タスクの行全体にハイライトを適用
          vim.fn.matchadd('RenderMarkdownInProgress', '^\\s*[*-]\\s*\\[-\\].*$')
        end,
      })
    end,
  },
}
