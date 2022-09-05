{ lib, config, pkgs, inputs, ... }:
let
  server = "tw3";
in {
  imports = [
    inputs.nixos-cn.nixosModules.nixos-cn
    ./redir.nix
    ./tunnel.nix
  ];

  config = lib.mkIf config.networking.nftables.tproxy.enable {
    services.shadowsocks.redir.default = {
      server = server;
      port = config.networking.nftables.tproxy.port;
    };

    services.shadowsocks.tunnel.googleDNS = {
      server = server;
      port = 1070;
      tunnelAddress = "8.8.8.8:53";
    };

    services.shadowsocks.tunnel.cfDNS = {
      server = server;
      port = 1071;
      tunnelAddress = "1.1.1.1:53";
    };
  };
}
