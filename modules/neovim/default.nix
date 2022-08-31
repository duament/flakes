{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      #nvim-lspconfig
      #nvim-cmp
      #cmp-nvim-lsp
      luasnip
      editorconfig-nvim
      lualine-nvim
      which-key-nvim
      #lualine-lsp-progress
      (nvim-treesitter.withPlugins (
        plugins: with plugins; [
          tree-sitter-nix
          tree-sitter-lua
          tree-sitter-rust
          tree-sitter-go
          tree-sitter-c
          tree-sitter-cpp
          tree-sitter-cmake
          tree-sitter-fish
          tree-sitter-json
          tree-sitter-toml
        ]
      ))
    ];
    extraConfig = ''
      lua << EOT
      ${builtins.readFile ./nvim.lua}
      EOT
    '';
  };
}
