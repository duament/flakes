{ lib, ... }:

{
  boot.initrd = {
    availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-amd" ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-label/system_luks";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

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
      options = [ "subvol=@/swap" "compress=zstd" "discard=async" "noatime" ];
    };

  swapDevices = [{ device = "/swap/swapfile"; }];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  hardware.video.hidpi.enable = lib.mkDefault true;
}
