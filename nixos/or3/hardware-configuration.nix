{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/boot";
    swap = "swap";
  };
}
