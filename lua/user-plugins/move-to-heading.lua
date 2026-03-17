local M = {}

-- Move selection to heading (generic function)
-- to_bottom: if true, move to bottom of section; if false, move right after heading
local function move_selection_to_heading(pattern, to_bottom)
  local v_start = vim.fn.line("v")
  local v_end = vim.fn.line(".")
  if v_start > v_end then
    v_start, v_end = v_end, v_start
  end
  local line_count = v_end - v_start + 1

  -- Search for target heading
  local target_line = nil
  for i = 1, vim.fn.line('$') do
    local line = vim.fn.getline(i)
    if line:match(pattern) then
      target_line = i
      break
    end
  end

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local dest
  if target_line then
    if to_bottom then
      -- Find next heading or end of file
      local next_heading = nil
      for i = target_line + 1, vim.fn.line('$') do
        if vim.fn.getline(i):match("^#+ ") then
          next_heading = i
          break
        end
      end
      dest = (next_heading and next_heading - 1) or vim.fn.line('$')
    else
      dest = target_line  -- Right after the heading
    end
  else
    dest = 0
  end

  -- Move selection
  vim.cmd(string.format(":%d,%dmove %d", v_start, v_end, dest))

  -- Add blank line before moved content
  local new_start = dest + 1
  vim.fn.append(new_start - 1, "")

  -- Re-select and fix indentation
  local new_end = new_start + line_count
  vim.cmd(string.format("normal! %dGV%dG=", new_start + 1, new_end))

  -- Return cursor to original position (one line above)
  local return_line
  if dest >= v_end then
    return_line = v_start - 1
  else
    return_line = v_start - 1 + line_count + 1
  end
  if return_line < 1 then return_line = 1 end
  vim.api.nvim_win_set_cursor(0, {return_line, 0})
end

function M.setup_keymaps()
  vim.keymap.set("v", "<leader>mn", function() move_selection_to_heading("^# NEXT", false) end, { desc = "Move to # NEXT", silent = true })
  vim.keymap.set("v", "<leader>mw", function() move_selection_to_heading("^## WANTS", false) end, { desc = "Move to ## WANTS", silent = true })
  vim.keymap.set("v", "<leader>md", function() move_selection_to_heading("^# DONE", true) end, { desc = "Move to # DONE (bottom)", silent = true })
  vim.keymap.set("v", "<leader>ms", function() move_selection_to_heading("^## SHOULD", false) end, { desc = "Move to ## SHOULD", silent = true })
  vim.keymap.set("v", "<leader>mm", function() move_selection_to_heading("^## MUST", false) end, { desc = "Move to ## MUST", silent = true })
  vim.keymap.set("v", "<leader>mb", function() move_selection_to_heading("^# BACKLOG", false) end, { desc = "Move to # BACKLOG", silent = true })
  vim.keymap.set("v", "<leader>mi", function() move_selection_to_heading("^# WIP", false) end, { desc = "Move to # WIP", silent = true })
end

return M
