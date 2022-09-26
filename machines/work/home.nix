{ config, pkgs, ... }:
let
  sshPub = import ../../lib/ssh-pubkeys.nix;
in {
  imports = [
    ../../home-modules/common.nix
    ../../home-modules/ssh.nix
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

  home.file.".ssh/allowed_signers".text = "i@rvf6.com ${sshPub.canokey}";

  programs.git = {
    enable = true;
    userEmail = "i@rvf6.com";
    userName = "Rvfg";
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_canokey.pub";
    };
    extraConfig = {
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
  };

  programs.gpg.enable = true;
  programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";

  home.stateVersion = "22.11";
}
