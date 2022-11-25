{ modulesPath, ... }:
{
  boot.initrd.availableKernelModules = [ "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "earlyprintk=ttyS0,115200"
  ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=NixOS" "compress=zstd" "discard=async" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=NixOS/nix" "compress=zstd" "noatime" "discard=async" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/mnt/resource" =
    {
      device = "/dev/disk/by-label/resource";
      fsType = "ext4";
      options = [ "nofail" "x-systemd.automount" ];
    };

  swapDevices = [{
    device = "/mnt/resource/swapfile";
    options = [ "nofail" "x-systemd.automount" ];
  }];

  virtualisation.hypervGuest.enable = true;
}
