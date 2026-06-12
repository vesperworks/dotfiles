-- tests/test_timer_display_spec.lua
-- Layer 1: タイマー表示の純粋ロジックテスト

describe("timer_display", function()
  local display

  before_each(function()
    display = require("vw.timer.display")
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

  describe("update_buffer_display", function()
    local function make_md_buffer(name, lines)
      local bufnr = vim.api.nvim_create_buf(false, false)
      vim.api.nvim_buf_set_name(bufnr, name)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.bo[bufnr].filetype = "markdown"
      return bufnr
    end

    local function extmark_count(bufnr)
      local ns = vim.api.nvim_create_namespace("task_timer")
      return #vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    end

    it("対応するタイマーがある実行中タスクに extmark を付与する", function()
      local bufnr = make_md_buffer("/tmp/vw-test-display.md", { "- [>] 進行中タスク" })
      local task_id = display.generate_task_id("/tmp/vw-test-display.md", "- [>] 進行中タスク")
      local timers = { [task_id] = { start_time = os.time() - 10, file_path = "/tmp/vw-test-display.md" } }

      display.update_buffer_display(bufnr, timers)
      assert.are.equal(1, extmark_count(bufnr))
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("タイマーが空なら extmark を付与しない", function()
      local bufnr = make_md_buffer("/tmp/vw-test-empty.md", { "- [>] 進行中タスク" })
      display.update_buffer_display(bufnr, {})
      assert.are.equal(0, extmark_count(bufnr))
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("タイマーが空になったら残留 extmark がクリアされる", function()
      local bufnr = make_md_buffer("/tmp/vw-test-clear.md", { "- [>] 進行中タスク" })
      local task_id = display.generate_task_id("/tmp/vw-test-clear.md", "- [>] 進行中タスク")
      local timers = { [task_id] = { start_time = os.time() - 10, file_path = "/tmp/vw-test-clear.md" } }

      display.update_all_displays(timers)
      assert.are.equal(1, extmark_count(bufnr))

      -- 空になった直後の update_all_displays で一掃される
      display.update_all_displays({})
      assert.are.equal(0, extmark_count(bufnr))
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)
end)
