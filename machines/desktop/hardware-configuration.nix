{ lib, ... }:

{
  boot.initrd = {
    availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-uuid/1c243edd-9a38-485e-8be4-b864d9736e1e";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/75dffd2b-9f67-4428-9fc4-67298fea3528";
      fsType = "btrfs";
      options = [ "subvol=NixOS" "compress=zstd" "discard=async" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/75dffd2b-9f67-4428-9fc4-67298fea3528";
      fsType = "btrfs";
      options = [ "subvol=NixOS/nix" "compress=zstd" "noatime" "discard=async" ];
    };

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  hardware.video.hidpi.enable = lib.mkDefault true;
}
