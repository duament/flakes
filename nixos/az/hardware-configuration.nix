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

  presets.fs.enable = true;

  fileSystems."/mnt/resource" = {
    device = "/dev/disk/by-label/resource";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };

  swapDevices = [
    {
      device = "/mnt/resource/swapfile";
      options = [
        "nofail"
        "x-systemd.automount"
      ];
    }
  ];

  virtualisation.hypervGuest.enable = true;
}
