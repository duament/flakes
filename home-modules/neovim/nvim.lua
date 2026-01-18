vim.opt.background = 'light'
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.gitblame_enabled = 0

require("catppuccin").setup({
  transparent_background = true,
  custom_highlights = function(colors)
    local ucolors = require('catppuccin.utils.colors')
    return {
      Pmenu = {
        bg = ucolors.darken(colors.surface0, 0.25, colors.crust),
      },
    }
  end,
})
vim.cmd.colorscheme 'catppuccin'

require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'catppuccin',
    section_separators = '',
    component_separators = ''
  },
}

require('which-key').setup {
}

require("ibl").setup {
  indent = {
    char = '│'
  },
  scope = {
    char = '┃'
  }
}

require("nvim-tree").setup()
vim.keymap.set('n', "<C-t>", function() require("fzf-lua").files() end, { silent = true })
vim.keymap.set('n', "<C-f>", function() require("fzf-lua").grep_project() end, { silent = true })

require("bufferline").setup{
  options = {
    indicator = {
      style = 'underline'
    },
    buffer_close_icon = '🗙',
    close_icon = '🗙',
    left_trunc_marker = '🡰',
    right_trunc_marker = '🡲',
  },
  highlights = require('catppuccin.special.bufferline').get_theme()
}

require("fzf-lua").setup()
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local luasnip = require("luasnip")
local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
  preselect = cmp.PreselectMode.None
})

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local function filter(arr, fn)
  if type(arr) ~= "table" then
    return arr
  end

  local filtered = {}
  for k, v in pairs(arr) do
    if fn(v, k, arr) then
      table.insert(filtered, v)
    end
  end

  return filtered
end

local function filterReactDTS(value)
  return string.match(value.filename, 'react/index.d.ts') == nil
end

local function on_list(options)
  local items = options.items
  if #items > 1 then
    items = filter(items, filterReactDTS)
  end

  vim.fn.setqflist({}, ' ', { title = options.title, items = items, context = options.context })
  if #items > 1 then
    vim.api.nvim_command('copen')
  else
    vim.api.nvim_command('cfirst')
  end
end

local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Inlay hints
  if client.server_capabilities.inlayHintProvider then
    vim.g.inlay_hints_visible = true
    vim.lsp.inlay_hint.enable(true)
  else
    print("no inlay hints available")
  end

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local apply = function()
    vim.lsp.buf.code_action({
      filter = function(a) return a.isPreferred end,
      apply = true
    })
  end
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition{on_list=on_list} end, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
  vim.keymap.set('v', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
  vim.keymap.set('n', '<space>a', apply, bufopts)
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

vim.lsp.config('pylsp', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "pylsp" },
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = { 'E501' },
        },
        ruff = {
          enabled = true,
          formatEnabled = true,
          -- Rules that are ignored when a pyproject.toml or ruff.toml is present:
          lineLength = 150,
          select = { "F", "E", "W", "C90" },
          ignore = { },
          preview = true,
          targetVersion = "py311",
        },
      }
    }
  }
})
vim.lsp.enable('pylsp')

vim.lsp.config('clangd', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "clangd" },
})
vim.lsp.enable('clangd')

vim.lsp.config('gopls', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "@gopls@" },
  settings = {
    gopls = {
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    }
  },
})
vim.lsp.enable('gopls')

vim.lsp.config('rust_analyzer', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "@rust_analyzer@" },
})
vim.lsp.enable('rust_analyzer')

vim.lsp.config('nil_ls', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "@nil@" },
  settings = {
    ['nil'] = {
      formatting = {
        command = { "@nixfmt@" },
      },
    },
  },
})
vim.lsp.enable('nil_ls')

vim.lsp.config('beancount', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "@beancount_language_server@", "--stdio" },
  init_options = {
    journal_file = vim.fn.getcwd() .. "/main.beancount",
  };
})
vim.lsp.enable('beancount')

vim.lsp.config('ts_ls', {
  on_attach = on_attach,
  flags = lsp_flags,
  cmd = { "@typescript_language_server@", "--stdio" },
})
vim.lsp.enable('ts_ls')

vim.lsp.config('svelte', {
  on_attach = on_attach,
  flags = lsp_flags,
})
vim.lsp.enable('svelte')

vim.lsp.config('texlab', {
  on_attach = on_attach,
  flags = lsp_flags,
})
vim.lsp.enable('texlab')
