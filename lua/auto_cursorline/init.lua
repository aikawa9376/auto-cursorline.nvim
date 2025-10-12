
local M = {}

local config = {
  wait_ms = 1000,
  disable = false,
  disabled_filetypes = { 'neo-tree' },
  disable_in_diff = true,
}

local status = {
  DISABLED = 0,
  CURSOR = 1,
  WINDOW = 2,
}

local current_status = status.DISABLED
local timer_id = 0

local function is_disabled_filetype()
  for _, ft in ipairs(config.disabled_filetypes) do
    if vim.bo.filetype == ft then
      return true
    end
  end
  return false
end

local function timer_stop()
  if timer_id ~= 0 then
    vim.fn.timer_stop(timer_id)
    timer_id = 0
  end
end

local function enable()
  if not is_disabled_filetype() and not (config.disable_in_diff and vim.wo.diff) then
    vim.wo.cursorline = true
    current_status = status.CURSOR
  end
  timer_id = 0
end

local function timer_start()
  timer_id = vim.fn.timer_start(config.wait_ms, function() enable() end)
end

function M.cursor_moved()
  if config.disable or is_disabled_filetype() then
    vim.wo.cursorline = false
    current_status = status.DISABLED
    return
  end
  if current_status == status.WINDOW then
    current_status = status.CURSOR
    return
  end
  timer_stop()
  timer_start()
  if current_status == status.CURSOR then
    vim.wo.cursorline = false
    current_status = status.DISABLED
  end
end

function M.win_enter()
  if is_disabled_filetype() or (config.disable_in_diff and vim.wo.diff) then
    vim.wo.cursorline = false
    current_status = status.DISABLED
    timer_stop()
  else
    vim.wo.cursorline = true
    current_status = status.WINDOW
    timer_stop()
  end
end

function M.win_leave()
  vim.wo.cursorline = false
  timer_stop()
  if not is_disabled_filetype() then
    current_status = status.DISABLED
  end
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend('force', config, opts)

  vim.api.nvim_create_augroup('auto-cursorline', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = 'auto-cursorline',
    pattern = '*',
    callback = function() M.cursor_moved() end,
  })
  vim.api.nvim_create_autocmd('WinEnter', {
    group = 'auto-cursorline',
    pattern = '*',
    callback = function() M.win_enter() end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = 'auto-cursorline',
    pattern = '*',
    callback = function() M.win_leave() end,
  })
end

return M
