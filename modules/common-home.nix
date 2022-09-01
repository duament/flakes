{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./fzf
    ./neovim
    ./starship
  ];

  home.packages = with pkgs; [
    dig
    duf
    file
    mtr
    sops
    tcpdump
    unar
  ];

  programs.exa.enable = true;

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
}
