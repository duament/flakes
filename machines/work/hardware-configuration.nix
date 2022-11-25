{ ... }:

{
  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/64d2448d-4531-4aee-a4fb-6f37130e9f2a";
      fsType = "btrfs";
      options = [ "compress=zstd" "discard=async" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/64d2448d-4531-4aee-a4fb-6f37130e9f2a";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" "discard=async" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/ACCD-56DE";
      fsType = "vfat";
    };

  swapDevices = [{ device = "/swap/swapfile"; }];

  virtualisation.hypervGuest.enable = true;
}
