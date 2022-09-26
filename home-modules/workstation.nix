{ pkgs, ... }: {
  imports = [
    ./common.nix
    ./ssh.nix
  ];

  home.packages = with pkgs; [
    ncdu
    tdesktop
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
      gcrypt = {
        participants = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
        publish-participants = true;
      };
    };
  };

  programs.gpg.enable = true;

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
}
