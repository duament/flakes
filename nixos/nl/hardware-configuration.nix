{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams =
    [
    ];

  presets.fs = {
    enable = true;
    efiDevice = null;
    swap = "@swap";
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [
        "subvol=NixOS/boot"
        "compress=zstd"
        "discard=async"
      ];
    };
  };
}
