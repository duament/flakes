{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.shadowsocks.redir;

  ssConfigCommon = import ./config.nix config;

  generateSopsSecret = item: name: values:
    nameValuePair "shadowsocks/${values.server}/${item}" {
      sopsFile = ./secrets.yaml;
    };

  generateSopsTemplate = name: values:
    nameValuePair "shadowsocks-redir-${name}" {
      content = builtins.toJSON (
        ssConfigCommon values.port values.server
        // { tcp_tproxy = true; }
      );
    };

  generateSystemdService = name: values:
  let
    temp = "shadowsocks-redir-${name}";
  in nameValuePair temp {
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = import ../../lib/systemd-harden.nix // {
      AmbientCapabilities = "CAP_NET_ADMIN";
      CapabilityBoundingSet = "CAP_NET_ADMIN";
      LoadCredential = "${temp}:${config.sops.templates.${temp}.path}";
      ExecStart = "${pkgs.shadowsocks-libev}/bin/ss-redir -c %d/${temp}";
      PrivateNetwork = false;
      PrivateUsers = false;
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
        type = types.port;
        default = 1090;
      };
    };
  };
in {
  options = {
    services.shadowsocks.redir = mkOption {
      type = with types; attrsOf (submodule ssOpts);
      default = {};
    };
  };

  config = mkIf (cfg != {}) {
    sops.secrets = mapAttrs' (generateSopsSecret "server") cfg
      // mapAttrs' (generateSopsSecret "server_port") cfg
      // mapAttrs' (generateSopsSecret "password") cfg
      // mapAttrs' (generateSopsSecret "method") cfg;

    sops.templates = mapAttrs' generateSopsTemplate cfg;

    systemd.services = mapAttrs' generateSystemdService cfg;
  };
}
