{ config, ... }:
{
  services.traefik = {
    staticConfigOptions = {
      experimental.http3 = true;
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
            permanent = false;
          };
        };
        https = {
          address = ":443";
          http.tls.certResolver = "le";
          http3 = { };
        };
      };
      certificatesResolvers.le.acme = {
        email = "le@rvf6.com";
        storage = config.services.traefik.dataDir + "/acme.json";
        keyType = "EC256";
        tlsChallenge = { };
      };
    };
    dynamicConfigOptions = {
      tls.options.default.sniStrict = true;
    };
  };
}
