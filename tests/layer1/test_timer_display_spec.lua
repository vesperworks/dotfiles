-- tests/test_timer_display_spec.lua
-- Layer 1: タイマー表示の純粋ロジックテスト

describe("timer_display", function()
  local display

  before_each(function()
    display = require("user-plugins.task-timer-display")
  end)

  describe("format_elapsed_time", function()
    it("60秒未満は秒表示", function()
      local start_time = os.time() - 30
      local result = display.format_elapsed_time(start_time)
      assert.matches("^%(%d+s%)$", result)
    end)

    it("60秒以上は分表示", function()
      local start_time = os.time() - 120
      local result = display.format_elapsed_time(start_time)
      assert.matches("^%(%d+m%)$", result)
    end)

    it("3600秒以上は時間+分表示", function()
      local start_time = os.time() - 3700
      local result = display.format_elapsed_time(start_time)
      assert.matches("^%(%d+h%d+m%)$", result)
    end)

    it("負の値は (--) を返す", function()
      local start_time = os.time() + 100
      local result = display.format_elapsed_time(start_time)
      assert.are.equal("(--)", result)
    end)
  end)

  describe("generate_task_id", function()
    it("ファイル名::ハッシュ12文字 の形式で返す", function()
      local result = display.generate_task_id("/path/to/test.md", "- [>] タスク内容")
      assert.matches("^test%.md::%x+$", result)
      -- ハッシュ部分が12文字
      local hash = result:match("::(%x+)$")
      assert.are.equal(12, #hash)
    end)

    it("同じ入力で同じIDを返す（決定的）", function()
      local id1 = display.generate_task_id("/path/test.md", "- [>] タスク")
      local id2 = display.generate_task_id("/path/test.md", "- [>] タスク")
      assert.are.equal(id1, id2)
    end)

    it("チェックボックス状態が違っても同じタスクは同じID", function()
      local id1 = display.generate_task_id("/path/test.md", "- [ ] タスク内容")
      local id2 = display.generate_task_id("/path/test.md", "- [>] タスク内容")
      assert.are.equal(id1, id2)
    end)
  end)
end)
