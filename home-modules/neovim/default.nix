{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.presets.neovim;

  makeLsp = package: binary: if cfg.enableLsp then "${package}/bin/${binary}" else binary;

  luaConfig = pkgs.replaceVarsWith {
    src = ./nvim.lua;
    replacements = {
      gopls = makeLsp pkgs.gopls "gopls";
      rust_analyzer = makeLsp pkgs.rust-analyzer "rust-analyzer";
      nil = makeLsp pkgs.nil "nil";
      nixfmt = makeLsp pkgs.nixfmt-rfc-style "nixfmt";
      beancount_language_server = makeLsp pkgs.beancount-language-server "beancount-language-server";
      typescript_language_server = makeLsp pkgs.nodePackages.typescript-language-server "typescript-language-server";
    };
  };
in
{
  options.presets.neovim = {

    enable = lib.mkEnableOption "neovim" // {
      default = true;
    };

    enableLsp = lib.mkEnableOption "neovim LSP" // {
      default = true;
    };

  };

  config = lib.mkIf cfg.enable {

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        bufferline-nvim
        catppuccin-nvim
        cmp-nvim-lsp
        cmp_luasnip
        cmp-buffer
        cmp-path
        editorconfig-nvim
        fzf-lua
        git-blame-nvim
        indent-blankline-nvim
        lualine-lsp-progress
        lualine-nvim
        luasnip
        nvim-cmp
        nvim-lspconfig
        nvim-tree-lua
        vim-lastplace
        which-key-nvim
        (nvim-treesitter.withPlugins (
          plugins: with plugins; [
            bash
            beancount
            c
            cmake
            comment
            cpp
            css
            dockerfile
            fish
            go
            gomod
            javascript
            json
            latex
            lua
            markdown
            nix
            python
            rust
            rst
            scss
            svelte
            toml
            tsx
            typescript
            yaml
          ]
        ))
      ];
      extraLuaConfig = ''
        dofile("${luaConfig}")
      '';
    };

  };
}
