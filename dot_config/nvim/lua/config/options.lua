local opts = {
  shiftwidth = 4,
  tabstop = 4,
  expandtab = true,
  number = true,
}

for opt, val in pairs(opts) do
    vim.o[opt] = val
end

local colorscheme = require("helpers.colorscheme")
vim.cmd.colorscheme(colorscheme)
