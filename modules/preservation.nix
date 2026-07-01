{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.presets.preservation;
in
{
  options = {
    presets.preservation.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {

    # Workaround
    boot.initrd.systemd.tmpfiles.settings.preservation."/sysroot/persistent/etc/machine-id".f = {
      argument = "uninitialized";
    };
    systemd.services.systemd-machine-id-commit.unitConfig.ConditionFirstBoot = true;

    fileSystems."/" = mkIf (!config.presets.disko.enable) {
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=2G"
        "mode=755"
      ];
    };

    preservation = {
      enable = true;
      preserveAt."/persist" = {
        directories = [
          "/var"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key.pub";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/var/lib/systemd/random-seed";
            how = "symlink";
            inInitrd = true;
            configureParent = true;
          }
        ];
        users.rvfg = {
          commonMountOptions = [
            "x-gvfs-hide"
          ];
          directories = [
            "projects"
            "files"
            ".cache"
            ".local"
          ];
        };
      };
    };

  };
}
