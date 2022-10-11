{ pkgs, ... }:
{
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

  programs.git.enable = true;

  programs.htop = {
    enable = true;
    settings = {
      hide_userland_threads = 1;
      detailed_cpu_time = 1;
    };
  };

  programs.jq.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LESS = "LRS";
    SYSTEMD_COLORS = "16";
  };

  home.stateVersion = "22.11";
}
