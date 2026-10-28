local M = {}

local config = {
  wait_ms = 1000,
  disable = false,
  disabled_filetypes = { 'neo-tree' },
  disabled_filetypes_no_cursorline = {},
  disable_in_diff = true,
}

local status = {
  DISABLED = 0,
  CURSOR = 1,
  WINDOW = 2,
}

local current_status = status.DISABLED
local timer_id = 0
local ns = vim.api.nvim_create_namespace("auto-cursorline")
local highlighted = {}

local function is_disabled_filetype()
  for _, ft in ipairs(config.disabled_filetypes) do
    if vim.bo.filetype == ft then
      return true
    end
  end
  return false
end

local function is_disabled_filetype_no_cursorline()
  for _, ft in ipairs(config.disabled_filetypes_no_cursorline) do
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

local function forced_off()
  return config.disable or vim.w.auto_cursorline_disabled == true
    or is_disabled_filetype_no_cursorline() or (config.disable_in_diff and vim.wo.diff)
end

-- Row-local, window-scoped marks avoid native cursorline option redraws.
local scoped_win
local function set_cursorline(value)
  local win = vim.api.nvim_get_current_win()
  local old = highlighted[win]
  if old and vim.api.nvim_buf_is_valid(old.buf) then
    pcall(vim.api.nvim_buf_del_extmark, old.buf, ns, old.id)
  end
  highlighted[win] = nil
  if value == nil then return end
  local extmark = vim.w.auto_cursorline_extmark == true and vim.api.nvim__ns_set
    and not vim.wo.cursorlineopt:find('screenline', 1, true)
  local native = value and not extmark or false
  if vim.wo.cursorline ~= native then vim.wo.cursorline = native end
  if extmark and scoped_win ~= win then
    vim.api.nvim__ns_set(ns, { wins = { win } })
    scoped_win = win
  end
  if value and extmark then
    local buf, row = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(win)[1] - 1
    local option = vim.wo.cursorlineopt
    local id = vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
      priority = 10,
      line_hl_group = option ~= 'number' and 'CursorLine' or nil,
      number_hl_group = (option == 'both' or option:find('number', 1, true))
        and (vim.wo.number or vim.wo.relativenumber) and 'CursorLineNr' or nil,
    })
    highlighted[win] = { buf = buf, row = row, id = id }
  end
end

local function enable()
  if forced_off() then
    set_cursorline(false)
    current_status = status.DISABLED
  elseif not is_disabled_filetype() then
    set_cursorline(true)
    current_status = status.CURSOR
  end
  timer_id = 0
end

local function timer_start()
  timer_id = vim.fn.timer_start(config.wait_ms, function() enable() end)
end

function M.cursor_moved()
  if forced_off() then
    timer_stop()
    set_cursorline(false)
    current_status = status.DISABLED
    return
  end
  if is_disabled_filetype() then
    set_cursorline(nil)
    timer_stop()
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
    set_cursorline(false)
    current_status = status.DISABLED
  end
end

function M.win_enter()
  if forced_off() then
    set_cursorline(false)
    current_status = status.DISABLED
    timer_stop()
  elseif is_disabled_filetype() then
    set_cursorline(nil)
    current_status = status.DISABLED
    timer_stop()
  else
    set_cursorline(true)
    current_status = status.WINDOW
    timer_stop()
  end
end

function M.win_leave()
  set_cursorline(false)
  timer_stop()
  if not is_disabled_filetype_no_cursorline() and not is_disabled_filetype() then
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
  vim.api.nvim_create_autocmd('WinClosed', {
    group = 'auto-cursorline',
    callback = function(args)
      local win = tonumber(args.match)
      local old = highlighted[win]
      if old and vim.api.nvim_buf_is_valid(old.buf) then pcall(vim.api.nvim_buf_del_extmark, old.buf, ns, old.id) end
      highlighted[win] = nil
      if scoped_win == win then scoped_win = nil end
    end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = 'auto-cursorline',
    pattern = '*',
    callback = function() M.win_leave() end,
  })
end

return M
