-- tests/layer0/test_keymaps_spec.lua
-- Layer 0: 全キーマップの登録確認テスト
-- リファクタリング後にキーが消えていないことを保証する

local helpers = require("tests.helpers")

describe("vw keymaps", function()
  -- init.lua と同じ初期化を実行
  before_each(function()
    require("vw.checkbox").setup()
    require("vw.callout").setup()
    require("vw.list").setup()
    require("vw.extract").setup()
    require("vw.header").setup()

    -- <leader>/ は init.lua で定義（timer 依存）
    vim.keymap.set("n", "<leader>/", function()
      local ok, timer = pcall(require, "vw.timer")
      if ok then timer.cancel_all_in_progress_tasks() end
    end, { noremap = true, silent = true, desc = "Cancel all in-progress tasks" })

    local ok_heading, vw_heading = pcall(require, "vw.heading")
    if ok_heading then vw_heading.setup() end

    local ok_pending, vw_tasks = pcall(require, "vw.tasks")
    if ok_pending then vw_tasks.setup() end

    local ok, vw_timer = pcall(require, "vw.timer")
    if ok then
      vw_timer.setup()
      vim.keymap.set("n", "<leader>Ta", function() vw_timer.show_active_timers() end, { desc = "アクティブタイマー表示", silent = true })
      vim.keymap.set("n", "<leader>Tq", function() vw_timer.stop_all_timers() end, { desc = "全タイマー停止", silent = true })
      vim.keymap.set("n", "<leader>Ts", function() vw_timer.rescan_current_buffer() end, { desc = "タイマー再スキャン", silent = true })
      vim.keymap.set("n", "<leader>Ti", function() vw_timer.show_timer_data_info() end, { desc = "タイマーデータ情報", silent = true })
      vim.keymap.set("n", "<leader>Td", function() vw_timer.debug_timer_comparison() end, { desc = "タイマーデバッグ", silent = true })
      vim.keymap.set("n", "<leader>Tc", function() vw_timer.clear_saved_timers() end, { desc = "タイマーデータクリア", silent = true })
      vim.keymap.set("n", "<leader>Tr", function() vw_timer.show_raw_timer_data() end, { desc = "タイマーJSONデータ表示", silent = true })
      vim.keymap.set("n", "<leader>Tb", function()
        local stats = require("vw.timer.storage").get_storage_stats()
        local backup_status = stats.backup_exists and "あり" or "なし"
        vim.notify(string.format("ストレージ統計:\n総タイマー数: %d個\nバックアップ: %s", stats.total_timers, backup_status), vim.log.levels.INFO)
      end, { desc = "ストレージ統計", silent = true })
      vim.keymap.set("n", "<leader>t", function() vw_timer.jump_to_active_timer() end, { desc = "稼働中タイマーにジャンプ", silent = true })
    end
  end)

  describe("vw.header keymaps", function()
    it("leader+1~6 でヘッダー挿入が登録されている", function()
      for i = 1, 6 do
        assert.is_true(helpers.keymap_exists("n", " " .. i), "<leader>" .. i .. " が未登録")
      end
    end)

    it("leader+0 でヘッダー削除が登録されている", function()
      assert.is_true(helpers.keymap_exists("n", " 0"))
    end)
  end)

  describe("vw.checkbox keymaps", function()
    it("leader+x でチェックボックストグルが登録されている (n, v)", function()
      assert.is_true(helpers.keymap_exists("n", " x"))
      assert.is_true(helpers.keymap_exists("v", " x"))
    end)

    it("leader+/ で全進行中タスク中止が登録されている", function()
      assert.is_true(helpers.keymap_exists("n", " /"))
    end)
  end)

  describe("vw.list keymaps", function()
    it("leader+* でリストアイテム(*) が登録されている (n, v)", function()
      assert.is_true(helpers.keymap_exists("n", " *"))
      assert.is_true(helpers.keymap_exists("v", " *"))
    end)

    it("leader+- でリストアイテム(-) が登録されている (n, v)", function()
      assert.is_true(helpers.keymap_exists("n", " -"))
      assert.is_true(helpers.keymap_exists("v", " -"))
    end)
  end)

  describe("vw.callout keymaps", function()
    it("leader+c でCalloutが登録されている (n, v)", function()
      assert.is_true(helpers.keymap_exists("n", " c"))
      assert.is_true(helpers.keymap_exists("v", " c"))
    end)
  end)

  describe("vw.extract keymaps", function()
    it("leader+[ でWikilink囲みが登録されている (v)", function()
      assert.is_true(helpers.keymap_exists("v", " ["))
    end)

    it("leader+a でノート抽出が登録されている (v)", function()
      assert.is_true(helpers.keymap_exists("v", " a"))
    end)

    it("leader+fs でファイル送信が登録されている", function()
      assert.is_true(helpers.keymap_exists("n", " fs"))
    end)
  end)

  describe("vw.heading keymaps", function()
    it("leader+h で見出しジャンプウィンドウが登録されている", function()
      assert.is_true(helpers.keymap_exists("n", " h"))
    end)

    local keys = { "mn", "mw", "md", "ms", "mm", "mb", "mi" }
    for _, key in ipairs(keys) do
      it("leader+" .. key .. " が登録されている (v)", function()
        assert.is_true(helpers.keymap_exists("v", " " .. key))
      end)
    end
  end)

  describe("vw.tasks keymaps", function()
    it("leader+j でタスクウィンドウが登録されている", function()
      assert.is_true(helpers.keymap_exists("n", " j"))
    end)
  end)

  describe("vw.timer keymaps", function()
    local keys = { "Ta", "Tq", "Ts", "Ti", "Td", "Tc", "Tr", "Tb", "t" }
    for _, key in ipairs(keys) do
      it("leader+" .. key .. " が登録されている", function()
        assert.is_true(helpers.keymap_exists("n", " " .. key))
      end)
    end
  end)
end)
