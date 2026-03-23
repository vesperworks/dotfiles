-- tests/test_heading_jump_spec.lua
-- Layer 2: heading-jump フローティングウィンドウの統合テスト

local helpers = require("tests.helpers")

describe("heading_jump", function()
  local heading_jump

  before_each(function()
    heading_jump = require("user-plugins.heading-jump")
    heading_jump.setup()
    -- 前回の状態をクリア
    heading_jump.state.visible = false
    heading_jump.state.win = nil
    heading_jump.state.buf = nil
  end)

  after_each(function()
    if heading_jump.state.visible then
      heading_jump.close_window()
    end
  end)

  describe("collect_headings", function()
    it("バッファ内の見出しを収集する", function()
      local buf = helpers.create_buf({
        "# Heading 1",
        "content",
        "## Heading 2",
        "### Heading 3",
      })
      local headings = heading_jump.collect_headings()
      assert.are.equal(3, #headings)
      assert.are.equal(1, headings[1].level)
      assert.are.equal(2, headings[2].level)
      assert.are.equal(3, headings[3].level)
      assert.are.equal("Heading 1", headings[1].text)
      helpers.cleanup_buf(buf)
    end)

    it("見出しがないバッファでは空リストを返す", function()
      local buf = helpers.create_buf({ "普通のテキスト", "もう一行" })
      local headings = heading_jump.collect_headings()
      assert.are.equal(0, #headings)
      helpers.cleanup_buf(buf)
    end)

    it("行番号が正しく記録される", function()
      local buf = helpers.create_buf({
        "intro",
        "# First",
        "gap",
        "## Second",
      })
      local headings = heading_jump.collect_headings()
      assert.are.equal(2, headings[1].lnum)
      assert.are.equal(4, headings[2].lnum)
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("toggle (フローティングウィンドウ)", function()
    it("toggle でウィンドウが開く", function()
      local buf = helpers.create_buf({
        "# Heading 1",
        "content",
        "## Heading 2",
      })
      heading_jump.toggle()
      assert.is_true(heading_jump.state.visible)
      assert.is_true(vim.api.nvim_win_is_valid(heading_jump.state.win))
      helpers.cleanup_buf(buf)
    end)

    it("再度 toggle でウィンドウが閉じる", function()
      local buf = helpers.create_buf({
        "# Heading 1",
        "content",
      })
      heading_jump.toggle()
      assert.is_true(heading_jump.state.visible)
      heading_jump.toggle()
      assert.is_false(heading_jump.state.visible)
      helpers.cleanup_buf(buf)
    end)

    it("見出しがないバッファでは開かない", function()
      local buf = helpers.create_buf({ "テキストのみ" })
      heading_jump.toggle()
      assert.is_false(heading_jump.state.visible)
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("ウィンドウ内キーマップ", function()
    it("バッファローカルキーマップが正しく登録される", function()
      local buf = helpers.create_buf({
        "# Heading 1",
        "## Heading 2",
      })
      heading_jump.toggle()
      assert.is_not_nil(heading_jump.state.buf)

      local maps = vim.api.nvim_buf_get_keymap(heading_jump.state.buf, "n")
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
      assert.is_true(lhs_set["i"], "i が未登録")
      -- 数字キー 1-9
      for i = 1, 9 do
        assert.is_true(lhs_set[tostring(i)], i .. " が未登録")
      end
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("jump_to_heading", function()
    it("指定した見出し行にジャンプする", function()
      local buf = helpers.create_buf({
        "# First",
        "aaa",
        "## Second",
        "bbb",
        "### Third",
      })
      heading_jump.toggle()

      heading_jump.jump_to_heading(2)

      -- ウィンドウが閉じる
      assert.is_false(heading_jump.state.visible)
      -- カーソルが ## Second (3行目) に移動（ジャンプ後はカレントウィンドウが元バッファ）
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(3, cursor[1])
      helpers.cleanup_buf(buf)
    end)

    it("範囲外のインデックスでは何もしない", function()
      local buf = helpers.create_buf({
        "# Only One",
        "content",
      })
      heading_jump.toggle()

      -- 存在しないインデックス
      heading_jump.jump_to_heading(99)
      -- ウィンドウは閉じない（ジャンプ失敗）
      -- 実装次第だが、エラーにはならないことを確認
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("find_parent_heading_index", function()
    it("カーソル位置から親見出しのインデックスを返す", function()
      local buf = helpers.create_buf({
        "# First",
        "aaa",
        "## Second",
        "bbb",
        "### Third",
      })
      heading_jump.collect_headings()

      -- 2行目 (aaa) → 親は # First (index 1)
      assert.are.equal(1, heading_jump.find_parent_heading_index(2))
      -- 4行目 (bbb) → 親は ## Second (index 2)
      assert.are.equal(2, heading_jump.find_parent_heading_index(4))
      -- 5行目 (### Third) → 自分自身 (index 3)
      assert.are.equal(3, heading_jump.find_parent_heading_index(5))
      helpers.cleanup_buf(buf)
    end)
  end)

  describe("feedkeys でキー入力シミュレーション", function()
    it("数字キーで対応する見出しにジャンプする", function()
      local buf = helpers.create_buf({
        "# First",
        "aaa",
        "## Second",
        "bbb",
        "### Third",
      })
      heading_jump.toggle()

      -- ウィンドウにフォーカスしてキー入力
      vim.api.nvim_set_current_win(heading_jump.state.win)
      vim.api.nvim_feedkeys("3", "x", false)

      -- ### Third (5行目) にジャンプ
      assert.is_false(heading_jump.state.visible)
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(5, cursor[1])
      helpers.cleanup_buf(buf)
    end)
  end)
end)
