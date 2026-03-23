-- lua/vw/extract.lua
-- 選択範囲のノート抽出・ファイル送信

local util = require("vw._util")

local M = {}

--- マークダウンファイルをダウンロードフォルダ等にコピーする
function M.send_file_to()
  local src = vim.fn.expand("%:p")
  if src == "" or vim.bo.filetype ~= "markdown" then
    vim.notify("マークダウンファイルが開かれていません", vim.log.levels.WARN)
    return
  end
  local filename = vim.fn.expand("%:t")
  local default_dest = vim.fn.expand("~/Downloads/") .. filename

  vim.ui.input({ prompt = "Send to: ", default = default_dest }, function(dest)
    if not dest or dest == "" then return end
    dest = vim.fn.expand(dest)
    if dest == src then
      vim.notify("コピー元と同じパスです", vim.log.levels.WARN)
      return
    end
    local result = vim.fn.system({ "cp", src, dest })
    if vim.v.shell_error == 0 then
      vim.notify("送信完了: " .. dest, vim.log.levels.INFO)
    else
      vim.notify("送信失敗: " .. result, vim.log.levels.ERROR)
    end
  end)
end

--- 選択範囲を新規ノートとして抽出する
function M.extract_to_note()
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\022' then
    vim.notify("Visual modeで範囲を選択してください", vim.log.levels.WARN)
    return
  end

  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then
    vim.notify("選択範囲が空です", vim.log.levels.WARN)
    return
  end

  local first_line = lines[1]
  local title = first_line:gsub("^#+ ", ""):gsub("^%s+", ""):gsub("%s+$", "")

  if title == "" then
    vim.notify("タイトルが空です", vim.log.levels.WARN)
    return
  end

  local vault_path = vim.env.OBSIDIAN_VAULT_PATH or
    "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault"
  vault_path = vim.fn.expand(vault_path)
  local filename = title .. ".md"
  local full_path = vault_path .. "/" .. filename

  if vim.fn.filereadable(full_path) == 1 then
    vim.notify("ファイルが既に存在します: " .. filename, vim.log.levels.ERROR)
    return
  end

  local daily_link = string.format("[[%s]]", os.date("%Y-%m-%d"))
  local new_file_lines = {
    "# " .. title,
    "",
  }

  for i = 2, #lines do
    table.insert(new_file_lines, lines[i])
  end

  table.insert(new_file_lines, "")
  table.insert(new_file_lines, daily_link)

  local file = io.open(full_path, "w")
  if file then
    file:write(table.concat(new_file_lines, "\n"))
    file:close()
  else
    vim.notify("ファイルを作成できませんでした: " .. full_path, vim.log.levels.ERROR)
    return
  end

  local wikilink = "[[" .. title .. "]]"
  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, { wikilink })

  vim.notify("ノートを作成しました: " .. filename, vim.log.levels.INFO)
end

--- キーマップを設定
function M.setup()
  local opts = { noremap = true, silent = true }

  vim.keymap.set('v', '<leader>a', M.extract_to_note,
    vim.tbl_extend('force', opts, { desc = "Extract selection to new note" }))

  vim.keymap.set('n', '<leader>fs', M.send_file_to,
    vim.tbl_extend('force', opts, { desc = "Send file to Downloads" }))

  -- Wikilink surround
  vim.keymap.set('v', '<leader>[', 'c[[<C-r>"]]<Esc>',
    vim.tbl_extend('force', opts, { desc = "Wrap selection in [[wikilink]]" }))
end

return M
