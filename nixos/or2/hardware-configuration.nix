{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
  ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/boot";
    swap = "swap";
  };
}
