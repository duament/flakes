{ config, lib, pkgs, ... }:
let
  sshPub = import ../../lib/ssh-pubkeys.nix;
in
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
        authorizedKeys = with sshPub; [ ybk canokey a4b ed25519 ];
        hostKeys = [ config.sops.secrets.initrd_ssh_host_ed25519_key.path ];
      };
    };
    postMountCommands = "rm -rf /run/secrets";
    systemd.enable = false;
  };
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "ip=dhcp" ];

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

  hardware.video.hidpi.enable = lib.mkDefault true;

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
