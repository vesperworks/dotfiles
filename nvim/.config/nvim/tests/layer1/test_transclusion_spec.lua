-- tests/layer1/test_transclusion_spec.lua
-- Layer 1: transclusion の heading セクション切り出し + _obsidian キャッシュのテスト

describe("transclusion", function()
  local tr = require("vw.transclusion")

  describe("slice_section", function()
    local lines = {
      "# Top",
      "intro",
      "## Section A",
      "body a1",
      "body a2",
      "### Sub A1",
      "sub body",
      "## Section B",
      "body b",
      "# Another Top",
      "tail",
    }

    it("heading 一致でセクションを切り出す", function()
      local out = tr._slice_section(lines, "Section A")
      assert.are.same({ "## Section A", "body a1", "body a2", "### Sub A1", "sub body" }, out)
    end)

    it("次の同レベル以上の heading 直前で停止する", function()
      local out = tr._slice_section(lines, "Top")
      assert.are.same({ "# Top", "intro", "## Section A", "body a1", "body a2",
        "### Sub A1", "sub body", "## Section B", "body b" }, out)
    end)

    it("末尾セクションはファイル末尾まで切り出す", function()
      local out = tr._slice_section(lines, "Another Top")
      assert.are.same({ "# Another Top", "tail" }, out)
    end)

    it("該当 heading が無ければ nil（全体フォールバックしない）", function()
      assert.is_nil(tr._slice_section(lines, "Nonexistent"))
    end)

    it("heading 空文字なら全体を返す", function()
      assert.are.same(lines, tr._slice_section(lines, ""))
    end)

    it("空白・大文字小文字の揺れを正規化して一致する", function()
      local out = tr._slice_section(lines, "  section  a ")
      assert.are.same({ "## Section A", "body a1", "body a2", "### Sub A1", "sub body" }, out)
    end)
  end)

  describe("normalize_heading", function()
    it("連続空白を 1 つにし lower 化する", function()
      assert.are.equal("foo bar", tr._normalize_heading("  Foo   BAR "))
    end)
  end)
end)

describe("_obsidian", function()
  local ob = require("vw._obsidian")
  local tmpdir

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    ob.clear_cache()
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    ob.clear_cache()
  end)

  it("extract_headings が level と text を返す", function()
    local hs = ob.extract_headings({ "# A", "text", "## B sub", "#not-heading" })
    assert.are.same({ { level = 1, text = "A" }, { level = 2, text = "B sub" } }, hs)
  end)

  it("read_file_cached が mtime 不変ならキャッシュを返す", function()
    local path = tmpdir .. "/note.md"
    vim.fn.writefile({ "hello" }, path)
    local first = ob.read_file_cached(path)
    local second = ob.read_file_cached(path)
    assert.are.same({ "hello" }, first)
    -- mtime が同じならテーブル参照ごと同一（再読み込みしていない）
    assert.are.equal(first, second)
  end)

  it("read_file_cached が存在しないパスで nil を返す", function()
    assert.is_nil(ob.read_file_cached(tmpdir .. "/missing.md"))
  end)

  it("resolve_path が絶対パス（拡張子なし→.md 補完なしの直接一致）を解決する", function()
    local path = tmpdir .. "/direct.md"
    vim.fn.writefile({ "x" }, path)
    assert.are.equal(path, ob.resolve_path(path))
  end)

  it("resolve_path が解決失敗で nil を返す", function()
    assert.is_nil(ob.resolve_path(tmpdir .. "/no-such-note.md"))
  end)

  it("resolve_path のキャッシュはファイル削除で無効化される", function()
    local path = tmpdir .. "/temp.md"
    vim.fn.writefile({ "x" }, path)
    assert.are.equal(path, ob.resolve_path(path))
    vim.fn.delete(path)
    -- キャッシュ済みでも filereadable で stale を検出して再解決（→ 失敗）する
    assert.is_nil(ob.resolve_path(path))
  end)

  it("解決失敗はネガティブキャッシュされ vault 全走査が繰り返されない (FM-9)", function()
    vim.env.OBSIDIAN_VAULT_PATH = tmpdir
    local find_calls = 0
    local orig_find = vim.fs.find
    vim.fs.find = function(...)
      find_calls = find_calls + 1
      return orig_find(...)
    end

    -- 1 回目: 解決失敗、basename 探索（vim.fs.find）まで落ちる
    assert.is_nil(ob.resolve_path("存在しないノート"))
    assert.are.equal(1, find_calls)
    -- 2 回目（TTL 内）: ネガティブキャッシュにヒットし全走査しない
    assert.is_nil(ob.resolve_path("存在しないノート"))
    assert.are.equal(1, find_calls)

    -- clear_cache 後は再解決される（新規ノート即時反映の経路）
    ob.clear_cache()
    vim.fn.writefile({ "x" }, tmpdir .. "/存在しないノート.md")
    assert.are.equal(tmpdir .. "/存在しないノート.md", ob.resolve_path("存在しないノート"))

    vim.fs.find = orig_find
    vim.env.OBSIDIAN_VAULT_PATH = nil
  end)
end)
