{ pkgs, ... }:
{
  home.packages = with pkgs; [
    binutils
    duf
    file
    jo
    mtr
    ncdu
    ripgrep
    tmux
  ];

  programs.exa.enable = true;

  programs.git.enable = true;

  programs.htop = {
    enable = true;
    settings = {
      hide_userland_threads = 1;
      detailed_cpu_time = 1;
    };
  };

  programs.jq.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    LESS = "FRS";
    SYSTEMD_COLORS = "16";
  };

  home.stateVersion = "22.11";
}
