{
  config,
  lib,
  self,
  ...
}:
with lib;
let
  sshPub = self.data.sshPub;
  keys = sshPub.authorizedKeyNames;
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
    home.file =
      builtins.listToAttrs (
        map (key: {
          name = ".ssh/id_${key}.pub";
          value.text = sshPub."${key}";
        }) keys
      )
      // builtins.listToAttrs (
        map (host: {
          name = ".ssh/known_hosts_${host}_init";
          value.text = ''
            ${host}.rvf6.com ${sshPub."${host}-init"}
          '';
        }) [ "rpi3" ]
      )
      // {
        ".ssh/known_hosts_t430_init".text = ''
          10.6.0.8 ${sshPub."t430-init"}
        '';
      };

    programs.ssh = {
      enable = true;
      includes = [ "config.d/*" ];
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ServerAliveInterval = 10;
          Compression = true;
          CheckHostIP = false;
        };
      }
      // builtins.listToAttrs (
        map (host: {
          name = host;
          value = {
            User = "rvfg";
            Hostname = "${host}.rvf6.com";
            IdentityFile = sshIdentities;
            IdentitiesOnly = true;
            ForwardAgent = true;
          };
        }) sshPub.hosts
      )
      // builtins.listToAttrs (
        map (host: {
          name = host;
          value = {
            User = "root";
            Hostname = "${host}.rvf6.com";
            IdentitiesOnly = true;
            IdentityFile = sshIdentities;
          };
        }) sshPub.rootHosts
      )
      // builtins.listToAttrs (
        map (host: {
          name = "${host}-init";
          value = {
            User = "root";
            Hostname = "${host}.rvf6.com";
            IdentityFile = sshIdentities;
            IdentitiesOnly = true;
            UserKnownHostsFile = "~/.ssh/known_hosts_${host}_init";
          };
        }) [ "rpi3" ]
      )
      // {
        "t430-init" = {
          User = "root";
          Hostname = "10.6.0.8";
          IdentityFile = sshIdentities;
          IdentitiesOnly = true;
          UserKnownHostsFile = "~/.ssh/known_hosts_t430_init";
        };
      }
      // {
        "github.com" = {
          IdentityFile = sshIdentities;
          IdentitiesOnly = true;
        };
      };
    };
  };
}
