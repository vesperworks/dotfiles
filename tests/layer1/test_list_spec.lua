-- tests/test_list_spec.lua
-- Layer 1: リストアイテム挿入・削除テスト

local helpers = require("tests.helpers")

describe("list", function()
  local markdown_helper

  before_each(function()
    markdown_helper = require("user-plugins.markdown-helper")
  end)

  describe("insert_list_item", function()
    it("プレーンテキストに * を追加する", function()
      local buf = helpers.create_buf({ "アイテム" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.insert_list_item("*")
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal("* アイテム", lines[1])
      helpers.cleanup_buf(buf)
    end)

    it("プレーンテキストに - を追加する", function()
      local buf = helpers.create_buf({ "アイテム" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.insert_list_item("-")
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal("- アイテム", lines[1])
      helpers.cleanup_buf(buf)
    end)

    it("既存のリストマーカーを削除する", function()
      local buf = helpers.create_buf({ "* アイテム" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.insert_list_item("*")
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal("アイテム", lines[1])
      helpers.cleanup_buf(buf)
    end)

    it("インデント付きでも動作する", function()
      local buf = helpers.create_buf({ "  コンテンツ" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.insert_list_item("-")
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal("  - コンテンツ", lines[1])
      helpers.cleanup_buf(buf)
    end)
  end)
end)
