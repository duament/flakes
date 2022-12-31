{ config, lib, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
in
{
  options = {
    presets.git.enable =  mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = {
    home.file.".ssh/allowed_signers".text = concatMapStrings (x: "i@rvf6.com ${x}\n") (with sshPub; [ ybk canokey ]);

    programs.git = {
      enable = true;
      userEmail = "i@rvf6.com";
      userName = "Rvfg";
      signing = {
        signByDefault = true;
        key = "~/.ssh/id_ybk.pub";
      };
      extraConfig = {
        init.defaultBranch = "main";
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };
}
