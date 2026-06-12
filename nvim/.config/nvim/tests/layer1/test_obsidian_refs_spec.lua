-- tests/layer1/test_obsidian_refs_spec.lua
-- Layer 1: blink-obsidian-refs（[[ノート名]] 補完）のテスト

describe("blink-obsidian-refs", function()
  local refs = require("vw.blink-obsidian-refs")

  describe("_find_ref_context", function()
    it("[[ 直後（query 空）で有効", function()
      local start, query = refs._find_ref_context("メモ [[")
      assert.is_not_nil(start)
      assert.are.equal("", query)
    end)

    it("[[ + ASCII query を切り出す", function()
      local start, query = refs._find_ref_context("[[note")
      assert.are.equal(3, start)
      assert.are.equal("note", query)
    end)

    it("[[ + 日本語 query を切り出す", function()
      local _, query = refs._find_ref_context("リンク [[日本語ノート")
      assert.are.equal("日本語ノート", query)
    end)

    it("embed の ![[ も有効", function()
      local _, query = refs._find_ref_context("![[ノート")
      assert.are.equal("ノート", query)
    end)

    it("# を含む場合は headings の領分なので無効", function()
      assert.is_nil(refs._find_ref_context("[[note#"))
      assert.is_nil(refs._find_ref_context("[[note#見出し"))
    end)

    it("]] で閉じ済みなら無効", function()
      assert.is_nil(refs._find_ref_context("[[note]] のあと"))
    end)

    it("[[ が無ければ無効", function()
      assert.is_nil(refs._find_ref_context("ただのテキスト"))
    end)
  end)

  describe("_parse_file_list", function()
    it("rg --files 出力から name/dir を抽出して整列する", function()
      local stdout = table.concat({
        "/vault/Inbox/メモ.md",
        "/vault/ルート直下ノート.md",
        "/vault/Projects/2026/計画.md",
        "/vault/画像.png",
      }, "\n") .. "\n"
      local notes = refs._parse_file_list(stdout, "/vault")
      -- table.sort はバイト順: メ(E383A1) < ル(E383AB) < 計(E8A888)
      assert.are.same({
        { name = "メモ", dir = "Inbox" },
        { name = "ルート直下ノート", dir = "" },
        { name = "計画", dir = "Projects/2026" },
      }, notes)
    end)

    it("空出力で空リスト", function()
      assert.are.same({}, refs._parse_file_list("", "/vault"))
    end)
  end)

  describe("get_completions", function()
    local function complete(line_text, buf_lines, cache)
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, buf_lines or { line_text })
      refs._set_note_cache(cache or {
        { name = "日本語ノート", dir = "" },
        { name = "english-note", dir = "Inbox" },
      })
      local result
      local source = refs.new()
      source:get_completions(
        { line = line_text, cursor = { #(buf_lines or { line_text }), #line_text }, bufnr = bufnr },
        function(r) result = r end
      )
      vim.api.nvim_buf_delete(bufnr, { force = true })
      return result
    end

    it("[[ 直後（0 文字）で全ノートが候補に出る", function()
      local result = complete("[[")
      assert.are.equal(2, #result.items)
    end)

    it("日本語 query で plain find 絞り込みできる", function()
      local result = complete("[[日本")
      assert.are.equal(1, #result.items)
      assert.are.equal("日本語ノート", result.items[1].label)
    end)

    it("確定で ]] が自動付与され、日本語行でも範囲がズレない", function()
      local line = "あい [[日本"
      local result = complete(line)
      assert.are.equal(1, #result.items)
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line })
      vim.lsp.util.apply_text_edits({ result.items[1].textEdit }, bufnr, "utf-16")
      local applied = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
      assert.are.equal("あい [[日本語ノート]]", applied)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("カーソル直後に ]] が既にあれば閉じを重複させない", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "[[日本]]" })
      refs._set_note_cache({ { name = "日本語ノート", dir = "" } })
      local result
      local source = refs.new()
      -- カーソルは "[[日本" の直後（]] の手前）
      source:get_completions(
        { line = "[[日本]]", cursor = { 1, #"[[日本" }, bufnr = bufnr },
        function(r) result = r end
      )
      assert.are.equal("日本語ノート", result.items[1].insertText)
      vim.lsp.util.apply_text_edits({ result.items[1].textEdit }, bufnr, "utf-16")
      assert.are.equal("[[日本語ノート]]", vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1])
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("コードフェンス内では候補を出さない", function()
      local result = complete("[[note", { "```", "[[note" })
      assert.are.equal(0, #result.items)
    end)
  end)
end)
