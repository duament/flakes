{ config, pkgs, ... }: {
  imports = [
    ../../modules/common-home.nix
    ../../modules/ssh
  ];

  home.packages = with pkgs; [
    checksec
    compsize
    gcc
    gdb
    ncdu
    python3
    wireguard-tools
  ];

  programs.git = {
    enable = true;
    userEmail = "i@rvf6.com";
    userName = "Rvfg";
    #signing = {
    #  signByDefault = true;
    #  key = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
    #};
    #extraConfig = {
    #  init.defaultBranch = "main";
    #  gcrypt = {
    #    participants = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
    #    publish-participants = true;
    #  };
    #};
  };

  programs.gpg.enable = true;
  programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";

  home.stateVersion = "22.11";
}
