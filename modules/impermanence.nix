{ config, lib, pkgs, self, ... }:
let
  cfg = config.presets.impermanence;
in
{
  options = {
    presets.impermanence.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/" = {
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
      users.rvfg = {
        directories = [
          "projects"
          "files"
          ".cache"
          ".local"
        ];
        files = [
          ".ssh/known_hosts"
        ];
      };
    };
  };
}
