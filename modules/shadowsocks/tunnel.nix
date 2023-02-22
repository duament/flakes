{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.shadowsocks.tunnel;

  ssConfigCommon = import ./config.nix config;

  generateSopsSecret = item: name: values:
    nameValuePair "shadowsocks/${values.server}/${item}" {
      sopsFile = ../../secrets/shadowsocks.yaml;
    };

  generateSopsTemplate = name: values:
    nameValuePair "shadowsocks-tunnel-${name}" {
      content = builtins.toJSON (
        ssConfigCommon values.port values.server
        // { tunnel_address = values.tunnelAddress; }
      );
    };

  generateSystemdService = name: values:
    let
      temp = "shadowsocks-tunnel-${name}";
    in
    nameValuePair temp {
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = import ../../lib/systemd-harden.nix // {
        LoadCredential = "${temp}:${config.sops.templates.${temp}.path}";
        ExecStart = "${pkgs.shadowsocks-libev}/bin/ss-tunnel -c %d/${temp}";
        PrivateNetwork = false;
      };
    };

  ssOpts = { ... }: {
    options = {
      server = mkOption {
        description = "Server name in sops";
        type = types.str;
        default = "";
      };

      port = mkOption {
        description = "Local port";
        type = types.port;
        default = 1090;
      };

      tunnelAddress = mkOption {
        type = types.str;
        default = "";
      };
    };
  };
in
{
  options = {
    services.shadowsocks.tunnel = mkOption {
      type = with types; attrsOf (submodule ssOpts);
      default = { };
    };
  };

  config = mkIf (cfg != { }) {
    sops.secrets = mapAttrs' (generateSopsSecret "server") cfg
      // mapAttrs' (generateSopsSecret "server_port") cfg
      // mapAttrs' (generateSopsSecret "password") cfg
      // mapAttrs' (generateSopsSecret "method") cfg;

    sops.templates = mapAttrs' generateSopsTemplate cfg;

    systemd.services = mapAttrs' generateSystemdService cfg;
  };
}
