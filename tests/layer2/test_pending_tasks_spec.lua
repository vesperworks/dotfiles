-- tests/test_pending_tasks_spec.lua
-- Layer 2: pending-tasks フローティングウィンドウの統合テスト

local helpers = require("tests.helpers")

describe("pending_tasks", function()
  local pending_tasks

  before_each(function()
    pending_tasks = require("user-plugins.pending-tasks")
    pending_tasks.setup()
    -- 前回の状態をクリア
    if pending_tasks.state.visible then
      pending_tasks.close_window()
    end
  end)

  after_each(function()
    if pending_tasks.state.visible then
      pending_tasks.close_window()
    end
  end)

  describe("collect_pending_tasks", function()
    it("[>] タスクを収集する", function()
      local buf = helpers.create_buf({
        "# TODO",
        "- [>] 実行中タスク",
        "- [ ] 未着手タスク",
        "- [/] 中断タスク",
      })
      local tasks = pending_tasks.collect_pending_tasks()
      -- [>] と [/] が収集される
      assert.is_true(#tasks >= 1)
      helpers.cleanup_buf(buf)
    end)

    it("タスクがないバッファでは空リストを返す", function()
      local buf = helpers.create_buf({
        "# README",
        "普通のテキスト",
      })
      local tasks = pending_tasks.collect_pending_tasks()
      assert.are.equal(0, #tasks)
      helpers.cleanup_buf(buf)
    end)

    it("[>] タスクの行番号が正しい", function()
      local buf = helpers.create_buf({
        "intro",
        "- [>] タスクA",
        "gap",
        "- [>] タスクB",
      })
      local tasks = pending_tasks.collect_pending_tasks()
      assert.is_true(#tasks >= 2)
      assert.are.equal(2, tasks[1].lnum)
      assert.are.equal(4, tasks[2].lnum)
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("toggle (フローティングウィンドウ)", function()
    it("toggle でウィンドウが開く", function()
      local buf = helpers.create_buf({
        "- [>] 実行中タスク",
      })
      pending_tasks.toggle()
      assert.is_true(pending_tasks.state.visible)
      assert.is_true(vim.api.nvim_win_is_valid(pending_tasks.state.win))
      helpers.cleanup_buf(buf)
    end)

    it("再度 toggle でウィンドウが閉じる", function()
      local buf = helpers.create_buf({
        "- [>] 実行中タスク",
      })
      pending_tasks.toggle()
      assert.is_true(pending_tasks.state.visible)
      pending_tasks.toggle()
      assert.is_false(pending_tasks.state.visible)
      helpers.cleanup_buf(buf)
    end)

    it("タスクがないバッファでは開かない", function()
      local buf = helpers.create_buf({
        "# 見出し",
        "テキストのみ",
      })
      pending_tasks.toggle()
      assert.is_false(pending_tasks.state.visible)
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("ウィンドウ内キーマップ", function()
    it("バッファローカルキーマップが正しく登録される", function()
      local buf = helpers.create_buf({
        "- [>] 実行中タスク",
        "- [/] 中断タスク",
      })
      pending_tasks.toggle()
      assert.is_not_nil(pending_tasks.state.buf)

      local maps = vim.api.nvim_buf_get_keymap(pending_tasks.state.buf, "n")
      local lhs_set = {}
      for _, m in ipairs(maps) do
        lhs_set[m.lhs] = true
      end

      -- 必須キーマップの確認
      assert.is_true(lhs_set["q"], "q が未登録")
      assert.is_true(lhs_set["<Esc>"], "<Esc> が未登録")
      assert.is_true(lhs_set["<CR>"], "<CR> が未登録")
      assert.is_true(lhs_set["j"], "j が未登録")
      assert.is_true(lhs_set["k"], "k が未登録")
      assert.is_true(lhs_set["/"], "/ が未登録")
      -- 数字キー 1-9
      for i = 1, 9 do
        assert.is_true(lhs_set[tostring(i)], i .. " が未登録")
      end
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("jump_to_task", function()
    it("指定したタスク行にジャンプする", function()
      local buf = helpers.create_buf({
        "# Header",
        "intro",
        "- [>] タスクA",
        "gap",
        "- [>] タスクB",
      })
      pending_tasks.toggle()
      local source_buf = pending_tasks.state.source_buf

      pending_tasks.jump_to_task(2)

      -- ウィンドウが閉じる
      assert.is_false(pending_tasks.state.visible)
      -- カーソルが タスクB (5行目) に移動
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(5, cursor[1])
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("close_window", function()
    it("ウィンドウを閉じて状態をリセットする", function()
      local buf = helpers.create_buf({
        "- [>] タスク",
      })
      pending_tasks.toggle()
      assert.is_true(pending_tasks.state.visible)

      pending_tasks.close_window()
      assert.is_false(pending_tasks.state.visible)
      assert.is_nil(pending_tasks.state.win)
      assert.is_nil(pending_tasks.state.buf)
      helpers.cleanup_buf(buf)
    end)
  end)
end)
