{
  config,
  ...
}:
{

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 8883;
        settings = {
          allow_anonymous = false;
          cafile = config.sops.secrets."pki/all-ca".path;
          certfile = config.sops.secrets."pki/rvf6.com.crt".path;
          keyfile = config.sops.secrets."pki/rvf6.com.key".path;
          require_certificate = true;
          use_identity_as_username = true;
        };
      }
    ];
  };

  systemd.services.mosquitto.serviceConfig.SupplementaryGroups = [ "nginx" ];

  networking.firewall.allowedTCPPorts = map (
    listener: listener.port
  ) config.services.mosquitto.listeners;

}
