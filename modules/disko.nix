{ config, lib, ... }:
let
  inherit (lib)
    # keep-sorted start
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    # keep-sorted end
    ;
  cfg = config.presets.disko;
in
{
  options.presets.disko = {

    enable = mkEnableOption "";

    biosBoot = mkEnableOption "";

    device = mkOption {
      type = types.str;
      default = "/dev/vda";
    };

  };

  config = mkIf cfg.enable {

    boot.loader =
      if cfg.biosBoot then
        {
          grub.enable = mkDefault true;
        }
      else
        {
          systemd-boot.enable = mkDefault true;
          efi.canTouchEfiVariables = mkDefault true;
        };

    fileSystems."/persist".neededForBoot = true;

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=2G"
          "defaults"
          "mode=755"
        ];
      };
      disk.main = {
        type = "disk";
        imageSize = "2G";
        device = cfg.device;
        content = {
          type = "gpt";
          partitions = {
            boot = mkIf cfg.biosBoot {
              size = "1M";
              type = "EF02"; # for grub MBR
              attributes = [ 0 ]; # partition attribute
            };
            efi = mkIf (!cfg.biosBoot) {
              priority = 1;
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [
                  "umask=0077"
                  "noexec"
                  "nosuid"
                  "nodev"
                  "noauto"
                  "rw"
                  "x-systemd.automount"
                  "x-systemd.idle-timeout=120"
                ];
              };
            };
            system = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  "/NixOS/boot" = mkIf cfg.biosBoot {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/boot";
                  };
                  "/NixOS/persist" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/persist";
                  };
                  "/NixOS/nix" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    swap = {
                      swapfile.size = "1G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

  };
}
