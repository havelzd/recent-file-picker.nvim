# Recent File Picker Nvim
Custom plugin to quickly open recent files in neovim.
Test project to learn lua and neovim plugin development.

## Installation

### Lazy
```
{
    dir = "~/path_to_picker/recent-file-picker.nvim",
    config = function()
        local rfp = require("recent-file-picker")
        vim.keymap.set("n", "<leader>e", "<cmd>RFP<cr>")
        rfp.setup()
    end,
}
```

## Manual
* `RFP<CR>` to open winwod
* `q` to close picker
