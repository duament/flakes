{ config, lib, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
  keys = [ "canokey" "a4b" "ed25519" ];
  sshIdentities = map (key: "~/.ssh/id_${key}.pub") keys;
in
{
  options = {
    presets.ssh.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.ssh.enable {
    home.file = builtins.listToAttrs
      (map
        (key: {
          name = ".ssh/id_${key}.pub";
          value.text = sshPub."${key}";
        })
        keys) // builtins.listToAttrs (map
      (host: {
        name = ".ssh/known_hosts_${host}_init";
        value.text = "${host}.rvf6.com ${sshPub."${host}-init"}";
      }) [ "rpi3" "t430" ]);

    programs.ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 10;
      extraConfig = ''
        CheckHostIP no
      '';
      matchBlocks = builtins.listToAttrs
        (map
          (host: {
            name = host;
            value = {
              user = "rvfg";
              hostname = "${host}.rvf6.com";
              identityFile = sshIdentities;
              forwardAgent = true;
            };
          }) [ "az" "or3" "rpi3" "t430" "work" ]) // builtins.listToAttrs (map
        (host: {
          name = host;
          value = {
            user = "duama";
            hostname = "${host}.rvf6.com";
            identityFile = sshIdentities;
            forwardAgent = true;
          };
        }) [ "nl" "or1" "or2" ]) // builtins.listToAttrs (map
        (host: {
          name = host;
          value = {
            user = "root";
            hostname = "${host}.rvf6.com";
            identityFile = sshIdentities;
          };
        }) [ "owrt" "k2" "k1" ]) // builtins.listToAttrs (map
        (host: {
          name = "${host}-init";
          value = {
            user = "root";
            hostname = "${host}.rvf6.com";
            identityFile = sshIdentities;
            extraOptions.UserKnownHostsFile = "~/.ssh/known_hosts_${host}_init";
          };
        }) [ "rpi3" "t430" ]) // {
        "github.com" = {
          identityFile = sshIdentities;
        };
      };
    };
  };
}
