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
        acl = [
          "topic readwrite owntracks/#"
        ];
        users = {
          "ip16@rvf6.com".acl = [ "readwrite owntracks/#" ];
          "owntracks@rvf6.com".acl = [ "readwrite owntracks/#" ];
        };
        settings = {
          allow_anonymous = false;
          cafile = config.sops.secrets."pki/all-ca".path;
          certfile = config.sops.secrets."pki/rvf6.com.crt".path;
          keyfile = config.sops.secrets."pki/rvf6.com.key".path;
          require_certificate = true;
          use_identity_as_username = true;
        };
      }
      {
        address = "/run/mosquitto/mosquitto.sock";
        port = 0;
        settings = {
          allow_anonymous = true;
        };
      }
    ];
    logType = [ "all" ];
  };

  systemd.services.mosquitto.serviceConfig.SupplementaryGroups = [ "nginx" ];

  networking.firewall.allowedTCPPorts = map (
    listener: listener.port
  ) config.services.mosquitto.listeners;

}
