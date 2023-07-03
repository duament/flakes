{ config, lib, self, ... }:
with lib;
let
  sshPub = self.data.sshPub;
  keys = [ "ybk" "canokey" "a4b" "ed25519" ];
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
        value.text = ''
          ${host}.rvf6.com ${sshPub."${host}-init"}
        '';
      }) [ "rpi3" ]) // {
      ".ssh/known_hosts_t430_init".text = ''
        192.168.2.8 ${sshPub."t430-init"}
      '';
    };

    programs.ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 10;
      extraConfig = ''
        CheckHostIP no
      '';
      includes = [ "config.d/*" ];
      matchBlocks = builtins.listToAttrs
        (map
          (host: {
            name = host;
            value = {
              user = "rvfg";
              hostname = "${host}.rvf6.com";
              identityFile = sshIdentities;
              identitiesOnly = true;
              forwardAgent = true;
            };
          }) [ "nl" "or2" "or3" "az" "rpi3" "t430" "work" ]) // builtins.listToAttrs (map
        (host: {
          name = host;
          value = {
            user = "duama";
            hostname = "${host}.rvf6.com";
            identityFile = sshIdentities;
            identitiesOnly = true;
            forwardAgent = true;
          };
        }) [ "or1" ]) // builtins.listToAttrs (map
        (host: {
          name = host;
          value = {
            user = "root";
            hostname = "${host}.rvf6.com";
            identitiesOnly = true;
            identityFile = sshIdentities;
          };
        }) [ "owrt" "k2" "k1" ]) // builtins.listToAttrs (map
        (host: {
          name = "${host}-init";
          value = {
            user = "root";
            hostname = "${host}.rvf6.com";
            identityFile = sshIdentities;
            identitiesOnly = true;
            extraOptions.UserKnownHostsFile = "~/.ssh/known_hosts_${host}_init";
          };
        }) [ "rpi3" ]) // {
        "t430-init" = {
          user = "root";
          hostname = "192.168.2.8";
          identityFile = sshIdentities;
          identitiesOnly = true;
          extraOptions.UserKnownHostsFile = "~/.ssh/known_hosts_t430_init";
        };
      } // {
        "github.com" = {
          identityFile = sshIdentities;
          identitiesOnly = true;
        };
      };
    };
  };
}
