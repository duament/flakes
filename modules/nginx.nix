{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.presets.nginx;
in
{
  options = {
    presets.nginx.enable = lib.mkEnableOption "Nginx template";

    presets.nginx.useACMEHost = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };

    presets.nginx.virtualHosts = lib.mkOption {
      type = with lib.types; attrsOf attrs;
      default = { };
    };

    presets.nginx.selfSignedVirtualHosts = lib.mkOption {
      type = with lib.types; attrsOf attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443
      ];
    };

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "le@rvf6.com";

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts =
        builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            enableACME = cfg.useACMEHost == null;
            inherit (cfg) useACMEHost;
            quic = true;
            http3 = true;
          }
          // value
          // {
            extraConfig = ''
              ${if value ? "extraConfig" then value.extraConfig else ""}
              add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
              add_header Alt-Svc 'h3=":$server_port"; ma=86400';
            '';
          }
        ) cfg.virtualHosts
        // (builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            quic = true;
            http3 = true;
            sslCertificate = config.sops.secrets."pki/rvf6.com.crt".path;
            sslCertificateKey = config.sops.secrets."pki/rvf6.com.key".path;
            sslTrustedCertificate = config.sops.secrets."pki/all-ca".path;
          }
          // value
          // {
            extraConfig = ''
              ${if value ? "extraConfig" then value.extraConfig else ""}
              ssl_verify_client on;
              add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
              add_header Alt-Svc 'h3=":$server_port"; ma=86400';
            '';
          }
        ) cfg.selfSignedVirtualHosts);
    };

    presets.nginx.virtualHosts."${config.networking.hostName}.rvf6.com" = {
      default = true;
      reuseport = true;
    };
  };
}
