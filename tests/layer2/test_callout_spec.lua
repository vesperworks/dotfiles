-- tests/test_callout_spec.lua
-- Layer 1+2: Callout の純粋ロジック + UI テスト

local helpers = require("tests.helpers")

describe("callout", function()
  local markdown_helper

  before_each(function()
    markdown_helper = require("user-plugins.markdown-helper")
  end)

  describe("remove_callout", function()
    it("Calloutヘッダー行を削除し、本体の > を除去する", function()
      local buf = helpers.create_buf({
        "> [!note]",
        "> 内容テキスト",
        "> 2行目",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.remove_callout(1, 3)
      local lines = helpers.get_buf_lines(buf)
      -- ヘッダー行は削除、本体行は > が除去される
      assert.are.equal(2, #lines)
      assert.are.equal("内容テキスト", lines[1])
      assert.are.equal("2行目", lines[2])
      helpers.cleanup_buf(buf)
    end)

    it("インデント付きCalloutも正しく解除する", function()
      local buf = helpers.create_buf({
        "  > [!warning]",
        "  > 警告内容",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.remove_callout(1, 2)
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal(1, #lines)
      assert.are.equal("  警告内容", lines[1])
      helpers.cleanup_buf(buf)
    end)

    it("通常の > quote も解除する", function()
      local buf = helpers.create_buf({
        "> 引用テキスト",
        "> 続き",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.remove_callout(1, 2)
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal(2, #lines)
      assert.are.equal("引用テキスト", lines[1])
      assert.are.equal("続き", lines[2])
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("insert_callout (既存callout解除)", function()
    it("既にcalloutがある行では解除する（ノーマルモードは1行のみ処理）", function()
      local buf = helpers.create_buf({
        "> 引用テキスト",
        "通常行",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      markdown_helper.insert_callout()
      local lines = helpers.get_buf_lines(buf)
      -- 1行目の > が除去される
      assert.are.equal("引用テキスト", lines[1])
      assert.are.equal("通常行", lines[2])
      helpers.cleanup_buf(buf)
    end)

    it("remove_callout で複数行のcalloutを解除する", function()
      local buf = helpers.create_buf({
        "> [!note]",
        "> コンテンツ",
      })
      markdown_helper.remove_callout(1, 2)
      local lines = helpers.get_buf_lines(buf)
      assert.are.equal(1, #lines)
      assert.are.equal("コンテンツ", lines[1])
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("show_selection_buffer (Callout選択UI)", function()
    it("フローティングウィンドウが生成される", function()
      local buf = helpers.create_buf({ "テスト行" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      local callback_result = nil
      local options = {
        { "note", "Note", "n" },
        { "warning", "Warning", "w" },
        { "tip", "Tip", "t" },
      }
      markdown_helper.show_selection_buffer(options, "テスト", "note", function(result)
        callback_result = result
      end)

      -- フローティングウィンドウが存在するか
      local float_win = nil
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(w)
        if config.relative and config.relative ~= "" then
          float_win = w
          break
        end
      end
      assert.is_not_nil(float_win, "フローティングウィンドウが生成されていない")

      -- ウィンドウを閉じてクリーンアップ
      if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_win_close(float_win, true)
      end
      helpers.cleanup_buf(buf)
    end)

    it("選択肢がバッファに正しく表示される", function()
      local buf = helpers.create_buf({ "テスト行" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      local options = {
        { "note", "Note", "n" },
        { "warning", "Warning", "w" },
      }
      markdown_helper.show_selection_buffer(options, "プロンプト", "note", function() end)

      -- フローティングウィンドウのバッファ内容を確認（閉じる前に読む）
      local float_win = nil
      local lines = nil
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(w)
        if config.relative and config.relative ~= "" then
          float_win = w
          local float_buf_id = vim.api.nvim_win_get_buf(w)
          lines = vim.api.nvim_buf_get_lines(float_buf_id, 0, -1, false)
          break
        end
      end
      assert.is_not_nil(float_win, "フローティングウィンドウが未生成")
      assert.is_not_nil(lines)

      -- プロンプト行がある
      assert.are.equal("プロンプト", lines[1])
      -- 選択肢が含まれる
      local content = table.concat(lines, "\n")
      assert.is_truthy(content:find("n: Note"))
      assert.is_truthy(content:find("w: Warning"))

      -- クリーンアップ
      if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_win_close(float_win, true)
      end

      helpers.cleanup_buf(buf)
    end)

    it("Insert モードのキーマップが登録される", function()
      local buf = helpers.create_buf({ "テスト行" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      local options = {
        { "note", "Note", "n" },
      }
      markdown_helper.show_selection_buffer(options, "テスト", "note", function() end)

      -- defer_fn の 10ms を待つ
      vim.wait(50, function() return false end)

      -- フローティングウィンドウのバッファを見つける
      local float_win = nil
      local float_buf_id = nil
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(w)
        if config.relative and config.relative ~= "" then
          float_win = w
          float_buf_id = vim.api.nvim_win_get_buf(w)
          break
        end
      end

      if float_buf_id then
        local insert_maps = vim.api.nvim_buf_get_keymap(float_buf_id, "i")
        local lhs_set = {}
        for _, m in ipairs(insert_maps) do
          lhs_set[m.lhs] = true
        end
        -- CR と Esc が登録されている
        assert.is_true(lhs_set["<CR>"], "<CR> が未登録")
        assert.is_true(lhs_set["<Esc>"], "<Esc> が未登録")
      end

      -- クリーンアップ
      if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_win_close(float_win, true)
      end
      helpers.cleanup_buf(buf)
    end)
  end)
end)
