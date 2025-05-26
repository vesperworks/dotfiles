return {
  "keaising/im-select.nvim",
  config = function()
    require("im_select").setup({
      default_command     = "im-select",

      -- Normalモードなどで戻すIME（英語IME）
      default_im_select   = "com.apple.keylayout.ABC",

      -- 「デフォルトIME（英語）に戻す」タイミング：Normalモードなど
        set_default_events = { "VimEnter", "InsertLeave", "CmdlineEnter" }, 

      -- 「前回のIME（例：日本語）に戻す」タイミング：Insertモードに入るとき
      set_previous_events = { "InsertEnter", "CmdlineLeave" },
      })
  end,
}
