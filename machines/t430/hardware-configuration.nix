{ lib, ... }:
let
  sshPub = import ../../lib/ssh-pubkeys.nix;
in {
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
        authorizedKeys = [ sshPub.canokey sshPub.a4b sshPub.ed25519 ];
        hostKeys = [ ../../crypt/initrd_ssh_host_ed25519_key ];
      };
    };
  };
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "ip=dhcp" ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=NixOS" "compress=zstd" "discard=async" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=NixOS/nix" "compress=zstd" "discard=async" "noatime" ];
    };

  fileSystems."/swap" =
    { device = "/dev/disk/by-label/system";
      fsType = "btrfs";
      options = [ "subvol=swap" "compress=zstd" "discard=async" "noatime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  hardware.video.hidpi.enable = lib.mkDefault true;
}
