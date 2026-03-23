-- tests/test_fold_spec.lua
-- Layer 1: Markdown折りたたみの foldexpr テスト

local helpers = require("tests.helpers")

describe("fold", function()
  local fold

  before_each(function()
    fold = require("user-plugins.markdown-fold")
  end)

  describe("foldexpr", function()
    it("H1 見出しは >1 を返す", function()
      local buf = helpers.create_buf({ "# Heading 1", "content" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.v.lnum = 1
      assert.are.equal(">1", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("H2 見出しは >2 を返す", function()
      local buf = helpers.create_buf({ "## Heading 2", "content" })
      vim.v.lnum = 1
      assert.are.equal(">2", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("H6 見出しは >6 を返す", function()
      local buf = helpers.create_buf({ "###### Heading 6", "content" })
      vim.v.lnum = 1
      assert.are.equal(">6", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("Callout開始行は >7 を返す", function()
      local buf = helpers.create_buf({ "> [!note] メモ", "> 内容" })
      vim.v.lnum = 1
      assert.are.equal(">7", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("Callout本体行は 7 を返す（次行も本体の場合）", function()
      local buf = helpers.create_buf({ "> [!note]", "> 内容1", "> 内容2" })
      vim.v.lnum = 2
      assert.are.equal(7, fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("Callout最終行は <7 を返す", function()
      local buf = helpers.create_buf({ "> [!note]", "> 内容", "通常テキスト" })
      vim.v.lnum = 2
      assert.are.equal("<7", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("通常行は = を返す", function()
      local buf = helpers.create_buf({ "# Heading", "通常テキスト", "次の行" })
      vim.v.lnum = 2
      assert.are.equal("=", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)

    it("#の後にスペースがない行はヘッダーとみなさない", function()
      local buf = helpers.create_buf({ "#tag ではない", "content" })
      vim.v.lnum = 1
      assert.are.equal("=", fold.foldexpr())
      helpers.cleanup_buf(buf)
    end)
  end)
end)
