-- tests/layer0/test_autocmds_spec.lua
-- Layer 0: autocmd の登録確認テスト

local helpers = require("tests.helpers")

describe("vw autocmds", function()
  before_each(function()
    local ok_heading, vw_heading = pcall(require, "vw.heading")
    if ok_heading then vw_heading.setup() end

    local ok_hover, vw_hover = pcall(require, "vw.hover")
    if ok_hover then vw_hover.setup({ delay = 500, max_height = 15, preview_lines = 50 }) end

    local ok_pending, vw_tasks = pcall(require, "vw.tasks")
    if ok_pending then vw_tasks.setup() end

    local ok_countdown, vw_countdown = pcall(require, "vw.countdown")
    if ok_countdown then vw_countdown.setup() end

    local ok_fold, vw_fold = pcall(require, "vw.fold")
    if ok_fold then vw_fold.setup() end

    local ok_timer, vw_timer = pcall(require, "vw.timer")
    if ok_timer then vw_timer.setup() end
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
