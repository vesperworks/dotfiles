-- tests/layer1/test_obsidian_tags_spec.lua
-- Layer 1: blink-obsidian-tags の日本語タグ対応（FM-1/FM-3）

describe("blink-obsidian-tags", function()
  local tags = require("vw.blink-obsidian-tags")

  describe("_find_tag_context (FM-3)", function()
    it("行頭の #tag を切り出す", function()
      local pos, query = tags._find_tag_context("#tag")
      assert.are.equal(1, pos)
      assert.are.equal("tag", query)
    end)

    it("半角スペース後の #日本語 を切り出す", function()
      local pos, query = tags._find_tag_context("本文の途中で #日本語")
      assert.is_not_nil(pos)
      assert.are.equal("日本語", query)
    end)

    it("全角スペース後の #タグ を切り出す", function()
      local pos, query = tags._find_tag_context("本文の途中　#タグ")
      assert.is_not_nil(pos)
      assert.are.equal("タグ", query)
    end)

    it("# 単独（query 空）も有効", function()
      local pos, query = tags._find_tag_context("メモ #")
      assert.is_not_nil(pos)
      assert.are.equal("", query)
    end)

    it("# の後に半角スペースがあれば無効", function()
      assert.is_nil(tags._find_tag_context("#tag のあと"))
    end)

    it("# の後に全角スペースがあれば無効", function()
      assert.is_nil(tags._find_tag_context("#タグ　のあと"))
    end)

    it("# が無ければ無効", function()
      assert.is_nil(tags._find_tag_context("ただの日本語テキスト"))
    end)
  end)

  describe("_parse_rg_tags", function()
    it("rg -oN 出力（1 行 1 マッチ）からタグ集合を作る", function()
      local seen = tags._parse_rg_tags("#tag1\n#日本語タグ\n#tag1\n#nested/tag\n")
      assert.is_true(seen["tag1"])
      assert.is_true(seen["日本語タグ"])
      assert.is_true(seen["nested/tag"])
    end)

    it("空出力で空集合", function()
      assert.are.same({}, tags._parse_rg_tags(""))
    end)
  end)

  describe("textEdit UTF-16 変換 (FM-2)", function()
    local ob = require("vw._obsidian")

    it("utf16_col: ASCII のみなら byte == utf16", function()
      assert.are.equal(5, ob.utf16_col("#tag5", 5))
    end)

    it("utf16_col: 日本語（3 byte → 1 unit）を正しく変換する", function()
      -- "あいう " = 3*3+1 = 10 bytes, UTF-16 では 4 units
      local line = "あいう #日本"
      assert.are.equal(4, ob.utf16_col(line, 10))
      -- 行末（"#日本" = 1+6 bytes 追加）
      assert.are.equal(7, ob.utf16_col(line, #line))
    end)

    it("utf16_col: サロゲートペア（絵文字）は 2 units", function()
      assert.are.equal(2, ob.utf16_col("😀x", 4))
    end)

    it("日本語行で補完確定するとカーソル位置のタグだけが置換される", function()
      local line = "あいう #日本"
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line })

      tags._set_tag_cache({ "日本語タグ" })
      local result
      local source = tags.new()
      source:get_completions(
        { line = line, cursor = { 1, #line }, bufnr = bufnr },
        function(r) result = r end
      )

      assert.is_not_nil(result)
      assert.are.equal(1, #result.items)
      -- blink.cmp と同じく LSP 規約（UTF-16）で textEdit を適用
      vim.lsp.util.apply_text_edits({ result.items[1].textEdit }, bufnr, "utf-16")
      local applied = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
      assert.are.equal("あいう #日本語タグ", applied)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe("rg 実機: TAG_RG_PATTERN が日本語タグを抽出する (FM-1)", function()
    it("ASCII / 日本語 / ネストタグを全部拾い、句読点で終端する", function()
      local tmpfile = vim.fn.tempname() .. ".md"
      vim.fn.writefile({
        "# 見出しではなくタグの行",
        "本文 #english-tag と #日本語タグ。",
        "ネスト #親/子タグ も。",
        "コード `x = 1` は無関係",
      }, tmpfile)

      -- 実装と同じ正規表現で rg を実行（同期 wait はテストのみ）
      local result = vim.system(
        { "rg", "--no-config", "-oN", "#[\\w/-]+", tmpfile },
        { text = true }
      ):wait()
      vim.fn.delete(tmpfile)

      assert.are.equal(0, result.code)
      local seen = tags._parse_rg_tags(result.stdout)
      assert.is_true(seen["english-tag"], "ASCII タグ")
      assert.is_true(seen["日本語タグ"], "日本語タグ（FM-1 の核心）")
      assert.is_true(seen["親/子タグ"], "ネスト日本語タグ")
      -- 「。」で終端していること（句読点込みのタグが出来ていない）
      assert.is_nil(seen["日本語タグ。"])
    end)
  end)
end)
