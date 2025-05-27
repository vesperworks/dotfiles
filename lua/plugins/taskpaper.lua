return {
  "davidoc/taskpaper.vim",
  ft = "taskpaper",

  -- ① 先に init でデフォルトマッピングを止める
  init = function()
    vim.g.no_taskpaper_maps = 1   -- plugin 内の \td などを生成しない
  end,

  -- ② config で <leader> 系マッピングを登録
  config = function()
    -- FileType autocmd を使用してバッファローカルマッピングを設定
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "taskpaper",
      callback = function()
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
        end

        -- ── Tag トグル ───────────────────────────────────────
        map("<leader>td", "<cmd>call taskpaper#toggle_tag('done')<CR>",        "Toggle @done")
        map("<leader>tx", "<cmd>call taskpaper#toggle_tag('cancelled')<CR>",   "Toggle @cancelled") 
        map("<leader>tt", "<cmd>call taskpaper#toggle_tag('today')<CR>",       "Toggle @today")

        -- ── 表示／検索系 ───────────────────────────────────
        map("<leader>tT", "<cmd>call taskpaper#search_tag('today')<CR>",       "Show @today only")
        map("<leader>tX", "<cmd>call taskpaper#search_tag('cancelled')<CR>",   "Show @cancelled only")
        map("<leader>t/", "<cmd>call taskpaper#search_keyword()<CR>",          "Search keyword")
        map("<leader>ts", "<cmd>call taskpaper#search_tag()<CR>",              "Search tag")

        -- ── プロジェクト操作 ──────────────────────────────
        map("<leader>tp", "<cmd>call taskpaper#fold_projects()<CR>",           "Fold projects")
        map("<leader>t.", "<cmd>call taskpaper#fold_notes()<CR>",              "Fold notes")
        map("<leader>tP", "<cmd>call taskpaper#focus_project()<CR>",           "Focus current project")  
        map("<leader>tj", "<cmd>call taskpaper#next_project()<CR>",            "Next project")
        map("<leader>tk", "<cmd>call taskpaper#prev_project()<CR>",            "Previous project")
        map("<leader>tg", "<cmd>call taskpaper#go_project()<CR>",              "Go to project…")
        map("<leader>tm", "<cmd>call taskpaper#move_to_project()<CR>",         "Move to project…")

        -- ── その他ユーティリティ ───────────────────────────
        map("<leader>tD", "<cmd>call taskpaper#archive_done()<CR>",            "Archive @done to Archive:")
      end,
    })
  end,
}
