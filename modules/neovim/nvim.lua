vim.opt.number = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true

require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
  },
  indent = {
    enable = true,
  }
}

require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onelight',
    section_separators = '',
    component_separators = ''
  }
}

require('which-key').setup {
}
