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
    systemd.network.networks."80-ethernet" = {
      matchConfig = { Type = "ether"; };
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

  hardware.enableRedistributableFirmware = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  hardware.deviceTree = {
    enable = true;
    filter = "*-rpi-3-b-plus.dtb";
    overlays = [
      {
        name = "irled";
        dtsText = ''
          /dts-v1/;
          /plugin/;
          / {
            compatible = "raspberrypi";
            fragment@0 {
              target-path = "/";
              __overlay__ {
                irled@0 {
                  compatible = "gpio-ir-tx";
                  gpios = <&gpio 24 0>;
                };
              };
            };
          };
        '';
      }
    ];
  };
}
