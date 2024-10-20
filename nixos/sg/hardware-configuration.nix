{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  presets.fs = {
    enable = true;
    efiDevice = null;
    swap = "swap";
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=NixOS/boot" "compress=zstd" "discard=async" ];
    };
  };
}
