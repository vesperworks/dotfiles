-- noice.nvim: コマンドライン・メッセージ・通知のモダンUI
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
    messages = {
      enabled = true,
    },
    popupmenu = {
      enabled = true,
      backend = "nui",
    },
    notify = {
      enabled = true,
    },
    lsp = {
      progress = { enabled = true },
      hover = { enabled = true },
      signature = { enabled = true },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,         -- / 検索を下部に表示
      command_palette = true,       -- コマンドラインとポップアップの位置調整
      long_message_to_split = true, -- 長いメッセージを分割表示
      inc_rename = false,
      lsp_doc_border = true,
    },
  },
}
