{ config, lib, ... }:
let
  cfg = config.presets.fs;
in
{
  options = {
    presets.fs.enable = lib.mkEnableOption "";

    presets.fs.efiDevice = lib.mkOption {
      type = with lib.types; nullOr str;
      default = "/dev/disk/by-label/efi";
    };

    presets.fs.device = lib.mkOption {
      type = with lib.types; nullOr str;
      default = "/dev/disk/by-label/system";
    };

    presets.fs.prefix = lib.mkOption {
      type = lib.types.str;
      default = "NixOS/";
    };

    presets.fs.swap = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = lib.mkMerge [
      (lib.mkIf (cfg.efiDevice != null) {
        "/efi" = {
          device = cfg.efiDevice;
          fsType = "vfat";
          options = [ "umask=0077" "noexec" "nosuid" "nodev" "noauto" "rw" "x-systemd.automount" "x-systemd.idle-timeout=120" ];
        };
      })

      (lib.mkIf (cfg.device != null) {
        "/persist" = {
          device = cfg.device;
          fsType = "btrfs";
          options = [ "subvol=${cfg.prefix}persist" "compress=zstd" "discard=async" ];
          neededForBoot = true;
        };
      })

      (lib.mkIf (cfg.device != null) {
        "/nix" = {
          device = cfg.device;
          fsType = "btrfs";
          options = [ "subvol=${cfg.prefix}nix" "compress=zstd" "noatime" "discard=async" ];
        };
      })

      (lib.mkIf (cfg.device != null && cfg.swap != null) {
        "/swap" = {
          device = cfg.device;
          fsType = "btrfs";
          options = [ "subvol=${cfg.swap}" "compress=zstd" "noatime" "discard=async" ];
        };
      })
    ];

    swapDevices = lib.mkIf (cfg.device != null && cfg.swap != null) [
      { device = "/swap/swapfile"; }
    ];
  };
}
