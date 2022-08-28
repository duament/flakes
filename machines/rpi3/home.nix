{ pkgs, ... }: {
  home.packages = with pkgs; [
    duf
    ncdu
    mtr
    wireguard-tools
    usbutils
    iperf
  ];

  programs.fish = {
    enable = true;
    shellAbbrs = {
      s = "systemctl";
      sls = "systemctl list-units --type=service";
      suls = "systemctl --user list-units --type=service";
      sus = "sudo systemctl";
      j = "journalctl";
      jb = "journalctl -b 0";
      jp = "journalctl -b 0 -p 4";
      v = "nvim";
      dl = "curl -LJO";
      se = "sudoedit";
    };
    shellAliases = {
      l = "exa -lag --time-style=long-iso";
      ll = "exa -lg --time-style=long-iso";
      lg = "exa -lag --git --time-style=long-iso";
    };
  };

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
  };

  programs.git = {
    enable = true;
    userEmail = "i@rvf6.com";
    userName = "Rvfg";
    signing = {
      signByDefault = true;
      key = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
    };
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.exa.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.htop = {
    enable = true;
    settings = {
      hide_userland_threads = 1;
      detailed_cpu_time = 1;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.stateVersion = "22.11";
}
