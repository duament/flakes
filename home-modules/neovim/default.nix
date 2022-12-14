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
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      cmp-nvim-lsp
      cmp_luasnip
      cmp-buffer
      cmp-path
      editorconfig-nvim
      indent-blankline-nvim
      lualine-lsp-progress
      lualine-nvim
      luasnip
      nvim-cmp
      nvim-lspconfig
      onenord-nvim
      which-key-nvim
      (nvim-treesitter.withPlugins (
        plugins: with plugins; [
          bash
          beancount
          c
          cmake
          comment
          cpp
          dockerfile
          fish
          go
          gomod
          json
          latex
          lua
          markdown
          nix
          rust
          rst
          toml
          yaml
        ]
      ))
    ];
  };

  xdg.configFile."nvim/init.lua".text = ''
    dofile("${luaConfig}")
  '';
}
