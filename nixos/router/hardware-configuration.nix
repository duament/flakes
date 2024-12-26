{
  config,
  pkgs,
  self,
  ...
}:
{
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelModules = [ "kvm-intel" ];
    luks.devices."cryptroot" = {
      device = "/dev/disk/by-label/router-luks";
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
    "nmi_watchdog=0"
    "snd_hda_intel.power_save=1"
  ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/router-efi";
    device = "/dev/disk/by-label/router-system";
    swap = "swap";
  };

  hardware.cpu.intel.updateMicrocode = true;
  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.runCommandNoCC "firmware" { } ''
      install -dm755 $out/lib/firmware/i915/
      install -Dm644 ${pkgs.linux-firmware}/lib/firmware/i915/* $out/lib/firmware/i915/
    '')
  ];
}
