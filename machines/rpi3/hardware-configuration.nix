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

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/boot";
    swap = "swap";
  };

  hardware.enableRedistributableFirmware = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
