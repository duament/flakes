{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
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

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=@swap" "compress=zstd" "noatime" "discard=async" ];
    };

  swapDevices = [{ device = "/swap/swapfile"; }];
}
