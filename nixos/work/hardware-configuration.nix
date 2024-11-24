{ ... }:

{
  boot.initrd.availableKernelModules = [
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  presets.fs = {
    enable = true;
    prefix = "";
    swap = "swap";
  };

  virtualisation.hypervGuest.enable = true;
}
