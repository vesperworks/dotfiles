return {
  "okuuva/auto-save.nvim",
   enabled = false,
  event = { "FocusLost", "InsertLeave" }, -- フォーカスを失う or 挿入モードを抜けたとき
  opts = {
    debounce_delay = 5000, -- 5秒以内の連続変更は保存しない
    write_all_buffers = false,

    -- 保存条件：Capture/ 以下のファイルのみ
    condition = function(buf)
      local filename = vim.api.nvim_buf_get_name(buf)
      if vim.bo[buf].modified == false then
        return false
      end
      return filename:find("/Documents/MainVault/Capture/") ~= nil
    end,
  },
}
