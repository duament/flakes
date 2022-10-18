{ pkgs, ... }:
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
          tree-sitter-bash
          tree-sitter-beancount
          tree-sitter-c
          tree-sitter-cmake
          tree-sitter-comment
          tree-sitter-cpp
          tree-sitter-dockerfile
          tree-sitter-fish
          tree-sitter-go
          tree-sitter-gomod
          tree-sitter-json
          tree-sitter-latex
          tree-sitter-lua
          tree-sitter-markdown
          tree-sitter-nix
          tree-sitter-rust
          tree-sitter-rst
          tree-sitter-toml
          tree-sitter-yaml
        ]
      ))
    ];
    extraConfig = ''
      lua << EOT
      ${builtins.readFile ./nvim.lua}
      EOT

      colorscheme onenord
    '';
  };
}
