# auto-cursorline.nvim

## Setting

This plugin is configured via the `setup` function.

```lua
require('auto_cursorline').setup({
  wait_ms = 1000,
  disabled_filetypes = { 'neo-tree' },
  disabled_filetypes_no_cursorline = {},
  disable_in_diff = true,
})
```

### `wait_ms`

It waits this value milliseconds before showing cursorline again after movement. Default: 1000.

### `disabled_filetypes`

Filetypes to disable this plugin's functionality without disabling cursorline. Default: `{ 'neo-tree' }`

### `disabled_filetypes_no_cursorline`

Filetypes to disable cursorline completely. Default: `{}`

### `disable_in_diff`

Disable this plugin in diff mode. Default: `true`

### Window-local suppression

Set `vim.w.auto_cursorline_disabled = true` to temporarily suppress cursorline
in the current window. Both window entry and the delayed callback honor this
flag. Call `require('auto_cursorline').cursor_moved()` after changing it for an
immediate refresh; setting it to `nil` restores the normal delayed behavior.

```lua
vim.w.auto_cursorline_disabled = true
require('auto_cursorline').cursor_moved()
```

This lets renderers such as Inkstone keep enlarged terminal text stable while
the cursor is on it, without disabling cursorline for ordinary body rows.

### Window-local row decoration

Set `vim.w.auto_cursorline_extmark = true` to keep the usual delay while drawing
`CursorLine` and `CursorLineNr` with a window-scoped row mark. The native
`cursorline` option stays off, avoiding window-wide option redraws over terminal
text overlays. Call `cursor_moved()` to refresh after changing the flag.
Inkstone manages and restores this flag automatically for typography windows.

This mode requires Neovim's namespace window scoping API. Older Neovim versions
and explicit `cursorlineopt=screenline` retain native behavior to preserve their
wrapped-screen-line semantics. Removing the flag restores normal native delay.

### Tests

Run `nvim --headless --clean -u NONE -l tests/run.lua` from this repository.
The tests cover normal delay, suppression, queued callbacks and existing
filetype/diff/disable behavior, including restoration from row-decoration mode.
