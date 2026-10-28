-- nvim --headless --clean -u NONE -l tests/run.lua
local path = debug.getinfo(1, 'S').source:sub(2)
vim.opt.rtp:prepend(vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(path, ':p'))))
local auto = require('auto_cursorline')
local passed = 0
local function test(name, callback)
  auto.win_leave()
  vim.w.auto_cursorline_disabled = nil
  vim.w.auto_cursorline_extmark = nil
  vim.bo.filetype, vim.wo.diff = '', false
  auto.setup({ wait_ms = 20, disable = false, disable_in_diff = true,
    disabled_filetypes = { 'neo-tree' }, disabled_filetypes_no_cursorline = {} })
  callback()
  auto.win_leave()
  passed = passed + 1
  print('PASS: ' .. name)
end

test('body cursorline returns after the normal delay', function()
  auto.cursor_moved()
  assert(not vim.wo.cursorline)
  assert(vim.wait(200, function() return vim.wo.cursorline end, 5))
end)

test('window suppression applies to movement and window entry', function()
  vim.w.auto_cursorline_disabled = true
  auto.cursor_moved()
  auto.win_enter()
  vim.wait(50)
  assert(not vim.wo.cursorline)
  vim.w.auto_cursorline_disabled = nil
  auto.cursor_moved()
  assert(vim.wait(200, function() return vim.wo.cursorline end, 5))
end)

test('a pending timer rechecks the window suppression flag', function()
  auto.cursor_moved()
  vim.w.auto_cursorline_disabled = true
  vim.wait(50)
  assert(not vim.wo.cursorline)
end)

test('suppression cancels an already pending timer', function()
  auto.cursor_moved()
  assert(#vim.fn.timer_info() == 1)
  vim.w.auto_cursorline_disabled = true
  auto.cursor_moved()
  assert(#vim.fn.timer_info() == 0)
  assert(not vim.wo.cursorline)
end)

test('disabled filetypes retain their own cursorline setting', function()
  vim.bo.filetype = 'neo-tree'
  vim.wo.cursorline = true
  auto.win_enter()
  auto.cursor_moved()
  assert(vim.wo.cursorline)
end)

test('delayed callbacks respect disable and diff settings', function()
  auto.cursor_moved()
  auto.setup({ disable = true })
  vim.wait(50)
  assert(not vim.wo.cursorline)
  auto.setup({ disable = false })
  auto.cursor_moved()
  vim.wo.diff = true
  vim.wait(50)
  assert(not vim.wo.cursorline)
end)

test('row decorations preserve delay without native cursorline toggles', function()
  vim.w.auto_cursorline_extmark = true
  auto.cursor_moved()
  vim.wait(50)
  assert(not vim.wo.cursorline)
  auto.win_enter()
  assert(not vim.wo.cursorline)
  auto.win_leave()
  vim.w.auto_cursorline_extmark = nil
  auto.cursor_moved()
  assert(vim.wait(200, function() return vim.wo.cursorline end, 5))
end)

test('pending callbacks recheck row decoration mode', function()
  auto.cursor_moved()
  vim.w.auto_cursorline_extmark = true
  vim.wait(50)
  assert(not vim.wo.cursorline)
  vim.w.auto_cursorline_extmark = nil
end)

vim.w.auto_cursorline_disabled = nil
print(('auto-cursorline: %d contracts passed'):format(passed))
vim.cmd('qa!')
