{ config, pkgs, self, ... }:
{
  boot.initrd = {
    availableKernelModules = [ "xhci_pci" "usb_storage" "sd_mod" "sdhci_pci" "r8169" ];
    kernelModules = [ "kvm-intel" ];
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
  boot.kernelParams = [ ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/boot";
    swap = "swap";
  };

  hardware.wirelessRegulatoryDatabase = true;
  hardware.firmware = [
    (
      pkgs.runCommandNoCC "firmware" { } ''
        install -dm755 $out/lib/firmware/rtl_bt/
        install -dm755 $out/lib/firmware/rtw88/
        install -dm755 $out/lib/firmware/i915/
        install -Dm644 ${pkgs.linux-firmware}/lib/firmware/rtl_nic/rtl8168h-2.fw $out/lib/firmware/rtl_nic/rtl8168h-2.fw
        install -Dm644 ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8822cu_* $out/lib/firmware/rtl_bt/
        install -Dm644 ${pkgs.linux-firmware}/lib/firmware/rtw88/rtw8822c_* $out/lib/firmware/rtw88/
        install -Dm644 ${pkgs.linux-firmware}/lib/firmware/i915/glk_* $out/lib/firmware/i915/
      ''
    )
  ];
}
