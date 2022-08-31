{ pkgs, ... }: {
  imports = [
    ../../modules/starship_async_fish.nix
  ];

  home.packages = with pkgs; [
    duf
    ncdu
    mtr
    tdesktop
  ];

  xdg.portal.enable = true;

  programs.fish = {
    enable = true;
    shellAbbrs = {
      s = "systemctl";
      j = "journalctl";
      v = "nvim";
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
    defaultEditor = true;
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

  programs.ssh = let
    sshIdentities = [ "~/.ssh/id_ed25519.pub" "~/.ssh/id_canokey" "~/.ssh/id_a4b" ];
  in {
    enable = true;
    compression = true;
    serverAliveInterval = 10;
    matchBlocks = {
      "nl" = {
        user = "duama";
        hostname = "nl.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
      "az" = {
        user = "duama";
        hostname = "az.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
      "or1" = {
        user = "duama";
        hostname = "or1.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
      "or2" = {
        user = "duama";
        hostname = "or2.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
      "or3" = {
        user = "duama";
        hostname = "or3.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
      "aur.archlinux.org" = {
        user = "aur";
        identityFile = [ "~/.ssh/id_aur.pub" "~/.ssh/id_aur_canokey" ];
      };
      "github.com" = {
        identityFile = [ "~/.ssh/id_ed25519.pub" "~/.ssh/id_github_canokey" ];
      };
    };
    extraConfig = ''
      CheckHostIP no
    '';
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
      gcrypt = {
        participants = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
        publish-participants = true;
      };
    };
  };

  programs.exa.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = true;
    };
  };

  programs.mpv = {
    enable = true;
    config = {
      fullscreen = true;
    };
  };

  home.stateVersion = "22.11";
}
