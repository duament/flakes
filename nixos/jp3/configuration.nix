{ ... }:
{

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/nvme0n1";
  };
  presets.nginx.enable = true;
  presets.swanctl-gfw.enableServer = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/jp3-bundle" = { };
    "pki/jp3-pkcs8-key" = { };
  };

  networking.hostName = "jp3";

  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseMTU = true;

  home-manager.users.rvfg = import ./home.nix;

}
