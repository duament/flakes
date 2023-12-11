{ pkgs, ... }:
{
  home.packages = with pkgs; [
    binutils
    duf
    file
    jo
    jq
    mtr
    ncdu
    nix-output-monitor
    ripgrep
  ];

  presets.btop.enable = true;

  programs.nix-index.enable = true;

  programs.eza.enable = true;

  programs.git.enable = true;

  programs.htop = {
    enable = true;
    settings = {
      hide_userland_threads = 1;
      detailed_cpu_time = 1;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'latte'
          set -g @catppuccin_status_left_separator '█'
        '';
      }
    ];
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
  };

  home.sessionVariables = {
    LESS = "FRS";
    SYSTEMD_COLORS = "16";
  };

  home.stateVersion = "22.11";
}
