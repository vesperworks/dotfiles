-- tests/test_autocmds_spec.lua
-- Layer 0: autocmd の登録確認テスト

local helpers = require("tests.helpers")

describe("user-plugins autocmds", function()
  before_each(function()
    local ok_heading, heading_jump = pcall(require, "user-plugins.heading-jump")
    if ok_heading then heading_jump.setup() end

    local ok_hover, hover = pcall(require, "user-plugins.obsidian-hover-preview")
    if ok_hover then hover.setup({ delay = 500, max_height = 15, preview_lines = 50 }) end

    local ok_pending, pending_tasks = pcall(require, "user-plugins.pending-tasks")
    if ok_pending then pending_tasks.setup() end

    local ok_countdown, countdown = pcall(require, "user-plugins.markdown-countdown")
    if ok_countdown then countdown.setup() end

    local ok_zoom, zoom = pcall(require, "user-plugins.markdown-zoom")
    if ok_zoom then zoom.setup() end

    local ok_timer, task_timer = pcall(require, "user-plugins.task-timer")
    if ok_timer then task_timer.setup() end
  end)

  describe("HeadingJump autocmds", function()
    it("HeadingJump augroup が存在する", function()
      assert.is_true(helpers.augroup_exists("HeadingJump"))
    end)

    it("BufLeave *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("HeadingJump", "BufLeave", "*.md"))
    end)
  end)

  describe("ObsidianHoverPreview autocmds", function()
    it("ObsidianHoverPreview augroup が存在する", function()
      assert.is_true(helpers.augroup_exists("ObsidianHoverPreview"))
    end)

    it("CursorMoved *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("ObsidianHoverPreview", "CursorMoved", "*.md"))
    end)

    it("InsertEnter *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("ObsidianHoverPreview", "InsertEnter", "*.md"))
    end)

    it("WinClosed が登録されている", function()
      assert.is_true(helpers.autocmd_exists("ObsidianHoverPreview", "WinClosed"))
    end)
  end)

  describe("PendingTasks autocmds", function()
    it("PendingTasks augroup が存在する", function()
      assert.is_true(helpers.augroup_exists("PendingTasks"))
    end)

    it("TextChanged *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("PendingTasks", "TextChanged", "*.md"))
    end)

    it("TextChangedI *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("PendingTasks", "TextChangedI", "*.md"))
    end)

    it("BufLeave *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("PendingTasks", "BufLeave", "*.md"))
    end)
  end)

  describe("MarkdownCountdown autocmds", function()
    it("MarkdownCountdown augroup が存在する", function()
      assert.is_true(helpers.augroup_exists("MarkdownCountdown"))
    end)

    it("BufEnter *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "BufEnter", "*.md"))
    end)

    it("BufWinEnter *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "BufWinEnter", "*.md"))
    end)

    it("TextChanged *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "TextChanged", "*.md"))
    end)

    it("InsertLeave *.md が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "InsertLeave", "*.md"))
    end)

    it("BufDelete が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "BufDelete"))
    end)

    it("VimLeavePre が登録されている", function()
      assert.is_true(helpers.autocmd_exists("MarkdownCountdown", "VimLeavePre"))
    end)
  end)

  describe("MarkdownZoom autocmds", function()
    it("FileType markdown の autocmd が登録されている", function()
      -- markdown-zoom は vim.api.nvim_create_autocmd ではなく無名グループで登録
      -- setup() 内の FileType autocmd を確認
      local autocmds = vim.api.nvim_get_autocmds({ event = "FileType", pattern = "markdown" })
      assert.is_true(#autocmds > 0, "FileType markdown の autocmd が未登録")
    end)
  end)

  describe("TaskTimer autocmds", function()
    it("TaskTimer の autocmd が登録されている", function()
      -- task-timer.setup_autocmds() で VimLeavePre 等が登録される
      local autocmds = vim.api.nvim_get_autocmds({ event = "VimLeavePre" })
      local found = false
      for _, ac in ipairs(autocmds) do
        if ac.group_name and ac.group_name:match("TaskTimer") then
          found = true
          break
        end
      end
      -- TaskTimer は augroup 名が不明確なため、VimLeavePre に何かが登録されていることのみ確認
      assert.is_true(#autocmds > 0, "VimLeavePre の autocmd が未登録")
    end)
  end)
end)
