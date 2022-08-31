{ pkgs, ... }: {
  imports = [
    ../../modules/fish.nix
    ../../modules/neovim
    ../../modules/starship_async_fish.nix
  ];

  home.packages = with pkgs; [
    duf
    ncdu
    mtr
    wireguard-tools
    usbutils
    iperf
  ];

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
