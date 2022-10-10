{ config, lib, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
  keys = [ "canokey" "a4b" "ed25519" ];
  sshIdentities = map (key: "~/.ssh/id_${key}.pub") keys;
in {
  options = {
    presets.ssh.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.ssh.enable {
    home.file = builtins.listToAttrs (map (key: {
      name = ".ssh/id_${key}.pub";
      value.text = sshPub."${key}";
    }) keys);

    programs.ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 10;
      extraConfig = ''
        CheckHostIP no
      '';
      matchBlocks = builtins.listToAttrs (map (host: {
        name = host;
        value = {
          user = "rvfg";
          hostname = "${host}.rvf6.com";
          identityFile = sshIdentities;
          forwardAgent = true;
        };
      }) [ "or3" ]) // builtins.listToAttrs (map (host: {
        name = host;
        value = {
          user = "duama";
          hostname = "${host}.rvf6.com";
          identityFile = sshIdentities;
          forwardAgent = true;
        };
      }) [ "nl" "az" "or1" "or2" ]) // {
        "github.com" = {
          identityFile = sshIdentities;
        };
      };
    };
  };
}
