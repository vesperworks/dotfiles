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
