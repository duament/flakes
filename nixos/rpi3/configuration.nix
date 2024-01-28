{ ... }:
{
  presets.nogui.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    initrd_ssh_host_ed25519_key = { };
  };

  boot.loader.generationsDir.copyKernels = true;
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "rpi3";

  systemd.network.networks."10-enu1u1u1" = {
    matchConfig = { PermanentMACAddress = "b8:27:eb:f0:2e:8e"; };
    DHCP = "yes";
    dhcpV6Config = { PrefixDelegationHint = "::/63"; };
  };

  services.uu = {
    enable = true;
    vlan = {
      enable = true;
      parentName = "10-enu1u1u1";
    };
  };

  home-manager.users.rvfg = import ./home.nix;
}
