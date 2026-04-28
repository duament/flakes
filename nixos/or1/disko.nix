{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            efi = {
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
