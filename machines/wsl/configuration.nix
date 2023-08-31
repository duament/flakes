{ lib, pkgs, ... }:
{
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "rvfg";
    startMenuLaunchers = true;
    nativeSystemd = true;
    # docker-native.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kmod
  ];

  presets.nogui.enable = true;
  presets.impermanence.enable = false;
  sops.age.sshKeyPaths = lib.mkForce [ "/etc/ssh/ssh_host_ed25519_key" ];

  system.activationScripts.cgroup2 = lib.stringAfter [ ] ''
    if [ -d /sys/fs/cgroup/unified ]; then
      umount /sys/fs/cgroup/unified || true
      umount /sys/fs/cgroup || true
      mount -o rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot -t cgroup2 cgroup2 /sys/fs/cgroup || true
    fi
  '';

  networking.hostName = "wsl";
  networking.firewall.enable = false;
  networking.useDHCP = false;
  systemd.network.wait-online.enable = false;
  services.resolved.enable = false;

  services.tailscale.enable = true;

  users.users.rvfg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ enflame"
  ];

  home-manager.users.rvfg = import ./home.nix;

  services._3proxy = {
    enable = true;
    denyPrivate = false;
    services = [
      {
        type = "socks";
        bindAddress = "::";
        extraArguments = "-64";
        auth = [ "none" ];
      }
    ];
  };
}
