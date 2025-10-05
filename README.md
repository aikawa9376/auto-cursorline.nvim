# auto-cursorline.nvim

## Setting

This plugin is configured via the `setup` function.

```lua
require('auto_cursorline').setup({
  wait_ms = 1000,
  disabled_filetypes = { 'neo-tree' },
  disable_in_diff = true,
})
```

### `wait_ms`

It waits this value milliseconds before hiding cursorline. Default: 1000.

### `disabled_filetypes`

Filetypes to disable this plugin. Default: `{ 'neo-tree' }`

### `disable_in_diff`

Disable this plugin in diff mode. Default: `true`
