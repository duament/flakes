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

  home.file.".ssh/allowed_signers".text = "i@rvf6.com ${builtins.readFile ../../modules/ssh/id_canokey.pub}";

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
