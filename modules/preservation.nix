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

    # https://nix-community.github.io/preservation/examples.html
    # https://github.com/nix-community/preservation/pull/23
    boot.initrd.systemd.tmpfiles.settings.preservation."/sysroot/persist/etc/machine-id".f = {
      argument = "uninitialized";
    };
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        ""
        "/persist/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        ""
        "systemd-machine-id-setup --commit --root /persist"
      ];
    };

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
          {
            directory = "/var";
            inInitrd = true;
          }
        ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
            how = "symlink";
            configureParent = true;
            createLinkTarget = true;
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
