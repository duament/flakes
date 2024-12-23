{
  config,
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
  boot.kernelParams = [ ];

  presets.fs = {
    enable = true;
    efiDevice = "/dev/disk/by-label/router-efi";
    device = "/dev/disk/by-label/router-system";
    swap = "swap";
  };
}
