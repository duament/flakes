{ lib, ... }:

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
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdmqOuypyBe2tF0fQ3R5vp9YkUg1e0lREno2ezJJE86"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIL6r8qfrXMqjnUBhxuBSMt0cfjHo+Vhvqtod8vvwoQk4AAAABHNzaDo= canokey"
        ];
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      };
    };
  };
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

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

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
