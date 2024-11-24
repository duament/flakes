{
  config,
  lib,
  self,
  ...
}:
{
  boot.initrd = {
    availableKernelModules = [
      "usbhid"
      "usb_storage"
      "lan78xx"
    ];
    kernelModules = [ ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-label/system_luks";
      allowDiscards = true;
      bypassWorkqueues = true;
      keyFile = "/sysroot/efi/key";
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
    systemd.network.networks."80-ethernet" = {
      matchConfig = {
        Type = "ether";
      };
      DHCP = "yes";
      dhcpV6Config.UseDelegatedPrefix = false;
    };
    systemd.services.initrd-nixos-activation.serviceConfig.ExecStartPre = "-/bin/rm -rf /run/secrets";
  };
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/boot";
    swap = "swap";
  };
  fileSystems."/efi".neededForBoot = true;

  hardware.enableRedistributableFirmware = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
