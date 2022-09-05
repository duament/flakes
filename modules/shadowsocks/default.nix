{ lib, config, pkgs, inputs, ... }:
let
  tproxyCfg = config.networking.nftables.tproxy;
in {
  imports = [
    inputs.nixos-cn.nixosModules.nixos-cn
    ./redir.nix
    ./tunnel.nix
  ];

  config = lib.mkIf tproxyCfg.enable {
    services.shadowsocks.redir.default = {
      server = tproxyCfg.server;
      port = tproxyCfg.port;
    };

    services.shadowsocks.tunnel.googleDNS = {
      server = tproxyCfg.server;
      port = 1070;
      tunnelAddress = "8.8.8.8:53";
    };

    services.shadowsocks.tunnel.cfDNS = {
      server = tproxyCfg.server;
      port = 1071;
      tunnelAddress = "1.1.1.1:53";
    };
  };
}
