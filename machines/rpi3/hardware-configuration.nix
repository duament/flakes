{ config, lib, self, ... }:
{
  boot.initrd = {
    availableKernelModules = [ "usbhid" "usb_storage" "lan78xx" ];
    kernelModules = [ ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-label/system_luks";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        inherit (self.data.sshPub) authorizedKeys;
        hostKeys = [ config.sops.secrets.initrd_ssh_host_ed25519_key.path ];
      };
    };
    preLVMCommands = lib.mkOrder 400 "sleep 3";
    postMountCommands = "rm -rf /run/secrets";
    systemd.enable = false;
  };
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
    "ip=dhcp"
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
      options = [ "subvol=NixOS/nix" "compress=zstd" "discard=async" "noatime" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=swap" "compress=zstd" "discard=async" "noatime" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = [{ device = "/swap/swapfile"; }];

  hardware.enableRedistributableFirmware = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
