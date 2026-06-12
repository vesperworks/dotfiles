-- tests/layer1/test_qmd_spec.lua
-- Layer 1: vw.qmd のコレクションキャッシュ + パース関数のテスト

describe("qmd", function()
  local qmd = require("vw.qmd")

  describe("_parse_collection_list", function()
    it("collection list 出力から name 配列を抽出する", function()
      local stdout = table.concat({
        "Collections (2):",
        "",
        "MainVault (qmd://MainVault/)",
        "  Pattern:  **/*.md",
        "  Files:    5232",
        "",
        "vault_daily (qmd://vault_daily/)",
        "  Pattern:  **/*.md",
      }, "\n")
      assert.are.same({ "MainVault", "vault_daily" }, qmd._parse_collection_list(stdout))
    end)

    it("空出力で空配列", function()
      assert.are.same({}, qmd._parse_collection_list(""))
      assert.are.same({}, qmd._parse_collection_list(nil))
    end)
  end)

  describe("_parse_collection_show", function()
    it("Path 行からパスを抽出する", function()
      local stdout = "MainVault\n  Path:     /vault/main\n  Files: 100\n"
      assert.are.equal("/vault/main", qmd._parse_collection_show(stdout))
    end)

    it("Path 行が無ければ nil", function()
      assert.is_nil(qmd._parse_collection_show("no path here"))
    end)
  end)

  describe("コレクションキャッシュ", function()
    it("get_search_paths はメモリキャッシュのみ参照し CLI を呼ばない", function()
      qmd._set_collections(
        { "ColA", "ColB", "ColC" },
        { ColA = "/path/a", ColB = "/path/b" } -- ColC は path 未解決
      )
      local system_calls = 0
      local orig_system = vim.system
      vim.system = function(...) ---@diagnostic disable-line
        system_calls = system_calls + 1
        return orig_system(...)
      end

      -- All: 解決済みパスのみ、順序保持
      assert.are.same({ "/path/a", "/path/b" }, qmd._get_search_paths(nil))
      -- 単一コレクション
      assert.are.same({ "/path/b" }, qmd._get_search_paths("ColB"))
      -- 未解決コレクションは空
      assert.are.same({}, qmd._get_search_paths("ColC"))
      assert.are.equal(0, system_calls, "ホットパスで qmd CLI が起動してはいけない")

      vim.system = orig_system
    end)

    it("JSON キャッシュファイルから names/paths を復元できる", function()
      local raw = vim.json.encode({
        names = { "X", "Y" },
        paths = { X = "/px", Y = "/py" },
      })
      local f = io.open(qmd._collections_file, "w")
      f:write(raw)
      f:close()

      qmd._set_collections({}, {})
      assert.is_true(qmd._load_collections_file())
      assert.are.same({ "/px", "/py" }, qmd._get_search_paths(nil))
    end)
  end)

  describe("_dedup_paths", function()
    it("親ディレクトリに包含されるパスを除外する", function()
      local out = qmd._dedup_paths({
        "/vault/Main",
        "/vault/Main/Daily",
        "/vault/Main/Readwise/Articles",
        "/other/Think",
      })
      assert.are.same({ "/other/Think", "/vault/Main" }, out)
    end)

    it("prefix が似ているだけの兄弟パスは除外しない", function()
      local out = qmd._dedup_paths({ "/vault/Main", "/vault/Main2" })
      assert.are.same({ "/vault/Main", "/vault/Main2" }, out)
    end)

    it("空入力で空", function()
      assert.are.same({}, qmd._dedup_paths({}))
    end)
  end)

  describe("_normalize_rg", function()
    it("rg -c 出力をエントリ化し 20 件に制限する", function()
      local data = {}
      for i = 1, 25 do
        data[i] = ("/vault/note%02d.md:%d"):format(i, i)
      end
      qmd._set_collections({ "V" }, { V = "/vault" })
      local entries = qmd._normalize_rg(data)
      assert.are.equal(20, #entries)
      assert.are.equal("rg", entries[1].source)
      assert.are.equal("note01", entries[1].title)
      assert.are.equal("note01.md", entries[1].display_path)
    end)
  end)

  describe("_merge_results", function()
    it("hybrid > bm25 > rg の優先順で重複除去する", function()
      local rg = { { source = "rg", real_path = "/a", display_path = "a" } }
      local bm25 = { { source = "bm25", real_path = "/a", display_path = "a" },
        { source = "bm25", real_path = "/b", display_path = "b" } }
      local hybrid = { { source = "hybrid", real_path = "/b", display_path = "b" } }
      local merged = qmd._merge_results(rg, bm25, hybrid)
      assert.are.equal(2, #merged)
      assert.are.equal("hybrid", merged[1].source) -- /b は hybrid が勝つ
      assert.are.equal("bm25", merged[2].source)   -- /a は bm25 が勝つ
    end)
  end)

  describe("_parse_qmd_json / _extract_chunk_range", function()
    it("混在出力から JSON 配列を抽出する", function()
      local out = 'Searching...\n[{"file":"qmd://V/n.md","score":0.9}]\n'
      local data = qmd._parse_qmd_json(out)
      assert.are.equal("qmd://V/n.md", data[1].file)
    end)

    it("snippet からチャンク範囲を抽出する", function()
      local range = qmd._extract_chunk_range("@@ -42,10 @@ heading")
      assert.are.same({ start = 42, count = 10 }, range)
    end)
  end)
end)
