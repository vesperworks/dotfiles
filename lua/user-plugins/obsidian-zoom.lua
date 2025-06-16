-- obsidian-zoom.lua
-- Obsidian Zoom風の機能: dropbar.nvimと連携したMarkdownリストズーム

local M = {}

-- ズーム状態を管理するテーブル
local zoom_state = {
  is_zoomed = false,
  original_folds = nil,
  zoom_range = nil,
  breadcrumb_stack = {}, -- パンくずリストのスタック
  original_scrolloff = nil, -- 元のscrolloff値を保存
  augroup = nil, -- 自動中央寄せ用autocmdグループ
}

-- 見出しレベルを取得
local function get_heading_level(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local _, _, hashes = line:find("^(#+)")
  if hashes then
    return #hashes
  end
  -- setext heading の場合
  if line:match("^=+%s*$") then
    return 1
  elseif line:match("^-+%s*$") then
    return 2
  end
  return 0
end

-- 見出しセクションの終了行を取得
local function get_heading_section_end(bufnr, start_row, level)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  
  for line_num = start_row + 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1] or ""
    local line_level = get_heading_level(bufnr, line_num - 1)
    
    -- 同じかより高いレベルの見出しが見つかったら、その手前で終了
    if line_level > 0 and line_level <= level then
      return line_num - 1 -- 見出しの手前の行を返す
    end
  end
  
  return total_lines
end

-- 見出しズーム範囲を取得（修正版：現在の見出しレベル以下のみ）
local function get_heading_zoom_range(bufnr, cursor_row)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    return nil
  end
  
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- 現在位置から上位の見出しを探す
  local headings = {}
  
  -- Tree-sitterクエリで見出しを取得
  local query_text = [[
    (atx_heading (atx_h1_marker) @h1)
    (atx_heading (atx_h2_marker) @h2)
    (atx_heading (atx_h3_marker) @h3)
    (atx_heading (atx_h4_marker) @h4)
    (atx_heading (atx_h5_marker) @h5)
    (atx_heading (atx_h6_marker) @h6)
    (atx_heading) @heading
  ]]
  
  local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_text)
  if not ok then
    -- シンプルなクエリにフォールバック
    query = vim.treesitter.query.parse("markdown", "(atx_heading) @heading")
  end
  
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local start_row, _, end_row, _ = node:range()
    if start_row <= cursor_row then
      local level = get_heading_level(bufnr, start_row)
      if level > 0 then  -- 有効な見出しのみ追加
        local text = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
        
        table.insert(headings, {
          level = level,
          start_row = start_row + 1, -- 1-indexed
          text = text:gsub("^#+%s*", ""):gsub("^=%s*", ""):gsub("^-+%s*", ""),
          node = node
        })
      end
    end
  end
  
  if #headings == 0 then
    return nil
  end
  
  -- 最も近い見出しを取得（カーソル位置の見出し）
  local current_heading = headings[#headings]
  
  -- 現在の見出しレベル以下のみでズーム範囲を設定
  local start_row = current_heading.start_row
  local end_row = get_heading_section_end(bufnr, current_heading.start_row, current_heading.level)
  
  -- パンくずリストは現在の見出しのみ
  local breadcrumb = {
    { text = current_heading.text }
  }
  
  return {
    start_row = start_row,
    end_row = end_row,
    breadcrumb = breadcrumb,
    type = "heading"
  }
end

-- Treesitterを使ってMarkdownのリスト構造を解析
local function get_list_hierarchy(bufnr, cursor_row)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cursor_row = cursor_row or vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    return nil
  end
  
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- 現在のカーソル位置のノードを取得
  local node = root:descendant_for_range(cursor_row, 0, cursor_row, -1)
  
  -- リスト階層を構築
  local hierarchy = {}
  local current_node = node
  
  while current_node do
    local node_type = current_node:type()
    if node_type == "list_item" then
      local start_row, _, end_row, _ = current_node:range()
      local text = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
      
      -- インデントレベルを計算
      local indent_level = 0
      for char in text:gmatch(".") do
        if char == " " then
          indent_level = indent_level + 1
        elseif char == "\t" then
          indent_level = indent_level + 4
        else
          break
        end
      end
      
      table.insert(hierarchy, 1, {
        text = text:match("^%s*[-*+]%s*(.*)") or text,
        start_row = start_row + 1, -- 1-indexed
        end_row = end_row + 1,     -- 1-indexed
        indent_level = indent_level,
        node = current_node,
      })
    end
    current_node = current_node:parent()
  end
  
  return hierarchy
end

-- リスト項目の実際の終了行を取得（子項目含む、次のリストは含まない）
local function get_list_item_end(bufnr, list_item)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    return list_item.end_row
  end
  
  local tree = parser:parse()[1] 
  if not tree then
    return list_item.end_row
  end
  
  local root = tree:root()
  
  local _, _, item_end, _ = list_item.node:range()
  
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local current_indent = list_item.indent_level
  
  for line_num = item_end + 2, total_lines do
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1] or ""
    
    -- 空行はスキップ
    if line_text:match("^%s*$") then
      goto continue
    end
    
    -- リスト項目かチェック
    if line_text:match("^%s*[-*+]%s") then
      local line_indent = 0
      for char in line_text:gmatch(".") do
        if char == " " then
          line_indent = line_indent + 1
        elseif char == "\t" then
          line_indent = line_indent + 4
        else
          break
        end
      end
      
      -- 同じかより浅いインデントのリスト項目が見つかったら終了
      if line_indent <= current_indent then
        return line_num - 1
      end
    else
      -- リスト項目でない行が見つかったら終了
      return line_num - 1
    end
    
    ::continue::
  end
  
  return total_lines
end

-- リストズーム範囲を取得（修正版：リストが所属する親見出しセクション全体）
local function get_list_zoom_range(bufnr, hierarchy)
  if not hierarchy or #hierarchy == 0 then
    return nil
  end
  
  -- 現在のリスト項目を取得（カーソル位置の項目）
  local current_item = hierarchy[#hierarchy]
  
  -- リストが所属する親見出しを探す
  local parent_heading = nil
  local cursor_row = current_item.start_row - 1 -- 0-indexed
  
  -- カーソル位置より上の見出しを探す
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if parser then
    local tree = parser:parse()[1]
    local root = tree:root()
    
    local query_text = [[
      (atx_heading) @heading
    ]]
    
    local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_text)
    if ok then
      local headings = {}
      
      for id, node in query:iter_captures(root, bufnr, 0, -1) do
        local start_row, _, end_row, _ = node:range()
        if start_row < cursor_row then  -- カーソル位置より上の見出しのみ
          local level = get_heading_level(bufnr, start_row)
          if level > 0 then
            local text = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
            
            table.insert(headings, {
              level = level,
              start_row = start_row + 1, -- 1-indexed
              text = text:gsub("^#+%s*", ""):gsub("^=%s*", ""):gsub("^-+%s*", ""),
              node = node
            })
          end
        end
      end
      
      -- 最も近い（最後の）見出しを親見出しとする
      if #headings > 0 then
        parent_heading = headings[#headings]
      end
    end
  end
  
  if parent_heading then
    -- 親見出しセクション全体をズーム範囲にする
    local start_row = parent_heading.start_row
    local end_row = get_heading_section_end(bufnr, parent_heading.start_row, parent_heading.level)
    
    -- パンくずリストは親見出し + 現在のリスト項目
    local breadcrumb = {
      { text = parent_heading.text }
    }
    -- 現在のリスト階層も追加
    for i, item in ipairs(hierarchy) do
      table.insert(breadcrumb, { text = item.text })
    end
    
    return {
      start_row = start_row,
      end_row = end_row,
      breadcrumb = breadcrumb,
      type = "list_with_heading"
    }
  else
    -- 親見出しが見つからない場合は従来通り
    local current_item = hierarchy[#hierarchy]
    local start_row = current_item.start_row
    local end_row = get_list_item_end(bufnr, current_item)
    
    local breadcrumb = {}
    for i, item in ipairs(hierarchy) do
      table.insert(breadcrumb, { text = item.text })
    end
    
    return {
      start_row = start_row,
      end_row = end_row,
      breadcrumb = breadcrumb,
      type = "list"
    }
  end
end

-- 親リストの範囲を取得（Obsidian Zoom風）
local function get_zoom_range(bufnr, cursor_row)
  local hierarchy = get_list_hierarchy(bufnr, cursor_row)
  
  -- リスト内の場合
  if hierarchy and #hierarchy > 0 then
    return get_list_zoom_range(bufnr, hierarchy)
  end
  
  -- リスト外の場合は見出しでズーム
  return get_heading_zoom_range(bufnr, cursor_row)
end

-- ズーム実行（Obsidian風, 中央寄せ機能付き）
function M.zoom_current_list()
  local bufnr = vim.api.nvim_get_current_buf()
  
  if zoom_state.is_zoomed then
    return
  end
  
  local range = get_zoom_range(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1)
  if not range then
    return
  end
  
  local start_line, end_line = range.start_row, range.end_row
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- 既存のfoldを保存
  zoom_state.original_folds = vim.fn.winsaveview()
  
  -- 全てのfoldを削除
  vim.cmd("normal! zE")
  
  -- ズーム範囲以外をfold
  if start_line > 1 then
    vim.cmd(string.format("1,%d fold", start_line - 1))
  end
  
  if end_line < total_lines then
    vim.cmd(string.format("%d,%d fold", end_line + 1, total_lines))
  end
  
  -- 中央寄せ機能を設定
  local original_scrolloff = vim.opt_local.scrolloff:get()
  zoom_state.original_scrolloff = original_scrolloff
  vim.opt_local.scrolloff = 999
  
  -- カーソル移動時に自動中央寄せを設定
  local augroup = vim.api.nvim_create_augroup("ZoomCenterMode", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      if zoom_state.is_zoomed then
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        if zoom_state.zoom_range and 
           cursor_line >= zoom_state.zoom_range.start_row and 
           cursor_line <= zoom_state.zoom_range.end_row then
          vim.cmd("normal! zz")
        end
      end
    end,
  })
  zoom_state.augroup = augroup
  
  -- カーソルを範囲の最初に移動
  vim.api.nvim_win_set_cursor(0, {start_line, 0})
  vim.cmd("normal! zz")
  
  -- 状態を保存
  zoom_state.is_zoomed = true
  zoom_state.zoom_range = range
  zoom_state.breadcrumb_stack = range.breadcrumb
end

-- ズーム解除
function M.unzoom()
  if not zoom_state.is_zoomed then
    return
  end
  
  -- 全てのfoldを削除
  vim.cmd("normal! zR")
  
  -- 自動中央寄せのautocmdを削除
  if zoom_state.augroup then
    vim.api.nvim_del_augroup_by_id(zoom_state.augroup)
    zoom_state.augroup = nil
  end
  
  -- scrolloffを元に戻す
  if zoom_state.original_scrolloff then
    vim.opt_local.scrolloff = zoom_state.original_scrolloff
  end
  
  -- 元のview状態を復元（可能であれば）
  if zoom_state.original_folds then
    vim.fn.winrestview(zoom_state.original_folds)
  end
  
  -- 状態をリセット
  zoom_state.is_zoomed = false
  zoom_state.original_folds = nil
  zoom_state.zoom_range = nil
  zoom_state.breadcrumb_stack = {}
  zoom_state.original_scrolloff = nil
  zoom_state.augroup = nil
end

-- パンくずリスト表示
function M.show_current_breadcrumb()
  if zoom_state.is_zoomed and zoom_state.breadcrumb_stack then
    local breadcrumb_parts = {}
    for i, item in ipairs(zoom_state.breadcrumb_stack) do
      table.insert(breadcrumb_parts, item.text:sub(1, 30))
    end
    
    local breadcrumb_text = table.concat(breadcrumb_parts, " › ")
    vim.notify("📍 " .. breadcrumb_text, vim.log.levels.INFO)
  else
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local range = get_zoom_range(bufnr, cursor_row)
    if range and range.breadcrumb then
      local breadcrumb_parts = {}
      for i, item in ipairs(range.breadcrumb) do
        table.insert(breadcrumb_parts, item.text:sub(1, 30))
      end
      
      local breadcrumb_text = table.concat(breadcrumb_parts, " › ")
      vim.notify("📍 " .. breadcrumb_text, vim.log.levels.INFO)
    end
  end
end

-- ズーム状態を取得
function M.get_zoom_state()
  return zoom_state
end

-- 自動コマンドでMarkdownファイルでのみ有効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- キーマップを設定
    vim.keymap.set("n", "<leader>zz", M.zoom_current_list, { 
      buffer = true, 
      desc = "Obsidian風ズーム（リスト/見出し）" 
    })
    vim.keymap.set("n", "<leader>ZZ", M.unzoom, { 
      buffer = true, 
      desc = "ズーム解除" 
    })
    vim.keymap.set("n", "<leader>zb", M.show_current_breadcrumb, { 
      buffer = true, 
      desc = "パンくずリスト表示" 
    })
  end,
})

return M
