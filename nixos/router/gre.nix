{ lib, ... }:
let
  inherit (lib) mkBefore;
in
{

  networking.nftables.masquerade = [ "oifname gre-jp" ];
  networking.nftables.masqRules = mkBefore ''
    ip saddr 10.5.0.50 accept
  '';

  networking.firewall = {
    extraInputRules = ''
      iifname xfrm-jp3 ip protocol gre accept
    '';
    extraForwardRules = ''
      iifname @wan_enabled_ifs oifname gre-jp accept
    '';
  };

  systemd.network.config.routeTables.gre-jp = 32;

  systemd.network.netdevs."30-gre-jp" = {
    netdevConfig = {
      Name = "gre-jp";
      Kind = "gre";
    };
    tunnelConfig = {
      Local = "10.5.0.50";
      Remote = "10.6.18.29";
      Independent = true;
    };
  };

  systemd.network.networks."30-gre-jp" = {
    name = "gre-jp";
    address = [
      "10.5.1.2/30"
      "fdc1::2/126"
    ];
    routes = [
      {
        Source = "0.0.0.0/0";
        Table = "gre-jp";
      }
      {
        Source = "::/0";
        Table = "gre-jp";
      }
    ];
  };

}
