-- tests/layer1/test_countdown_spec.lua
-- Layer 1: countdown の extmark 表示テスト（changedtick スキップ最適化の回帰防止）

describe("countdown", function()
  local countdown = require("vw.countdown")
  local ns = vim.api.nvim_create_namespace("markdown_countdown")

  local function make_md_buffer(lines)
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].filetype = "markdown"
    return bufnr
  end

  local function extmark_count(bufnr)
    return #vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
  end

  it("HH:MM 行に extmark（行ハイライト + virt_text）が付く", function()
    local bufnr = make_md_buffer({ "ミーティング 23:59" })
    countdown.update_buffer(bufnr)
    assert.are.equal(2, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("相対時間（30m）行に extmark が付く", function()
    local bufnr = make_md_buffer({ "休憩 30m" })
    countdown.update_buffer(bufnr)
    assert.are.equal(2, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("時刻パターンが無い行には extmark が付かない", function()
    local bufnr = make_md_buffer({ "ただのテキスト", "- [ ] タスク" })
    countdown.update_buffer(bufnr)
    assert.are.equal(0, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("URL 内の数字パターンは無視される", function()
    local bufnr = make_md_buffer({ "https://example.com/12:34/path" })
    countdown.update_buffer(bufnr)
    assert.are.equal(0, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("countdown 行ゼロのバッファは update_all でスキップされても、行追加後は再描画される", function()
    local bufnr = make_md_buffer({ "ただのテキスト" })
    countdown.update_all()
    assert.are.equal(0, extmark_count(bufnr))

    -- スキップ状態に入った後にテキスト変更（changedtick が変わる）
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "締切 23:59" })
    countdown.update_all()
    assert.are.equal(2, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("countdown 行を削除すると extmark が消える", function()
    local bufnr = make_md_buffer({ "締切 23:59" })
    countdown.update_buffer(bufnr)
    assert.are.equal(2, extmark_count(bufnr))

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "ただのテキスト" })
    countdown.update_buffer(bufnr)
    assert.are.equal(0, extmark_count(bufnr))
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)
