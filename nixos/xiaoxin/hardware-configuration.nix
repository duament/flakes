{ lib, ... }:

{
  boot.initrd = {
    availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [ "kvm-amd" ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-label/system_luks";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  presets.fs = {
    enable = true;
    swap = "@/swap";
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
