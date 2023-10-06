{ pkgs, ... }:
let
  luaConfig = pkgs.substituteAll {
    src = ./nvim.lua;
    gopls = "${pkgs.gopls}/bin/gopls";
    rust_analyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
    nil = "${pkgs.nil}/bin/nil";
    beancount_language_server = "${pkgs.beancount-language-server}/bin/beancount-language-server";
    typescript_language_server = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      cmp-nvim-lsp
      cmp_luasnip
      cmp-buffer
      cmp-path
      editorconfig-nvim
      git-blame-nvim
      indent-blankline-nvim
      lualine-lsp-progress
      lualine-nvim
      luasnip
      nvim-cmp
      nvim-lspconfig
      nvim-tree-lua
      # onenord-nvim
      (pkgs.vimUtils.buildVimPlugin {
        pname = "onenord.nvim";
        version = "2023-10-06";
        src = pkgs.fetchFromGitHub {
          owner = "duament";
          repo = "onenord.nvim";
          rev = "f9950f6a171067ac6e3544463a9cec472e91331f";
          sha256 = "sha256-LZGjONVJ4UJ7ZVvenYOuvZFc1g7ejE80/VAIwWhtoHg=";
        };
        meta.homepage = "https://github.com/rmehri01/onenord.nvim/";
      })
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
  };

  xdg.configFile."nvim/init.lua".text = ''
    dofile("${luaConfig}")
  '';
}
