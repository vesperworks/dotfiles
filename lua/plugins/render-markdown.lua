-- plugins/render-markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("render-markdown").setup {
        -- オプション設定（必要に応じて）
        render_modes = { 'n', 'c', 't' },
        
        -- チェックボックスの設定
        checkbox = {
          checked = {
            icon = '✓',
            highlight = 'RenderMarkdownChecked',
          },
          unchecked = {
            icon = '○',
            highlight = 'RenderMarkdownUnchecked',
          },
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
