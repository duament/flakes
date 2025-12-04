{
  config,
  pkgs,
  self,
  ...
}:
let
  otRecorderUrl = "http://localhost:8083";
in
{

  sops.secrets = {
    "owntracks/cert" = { };
    "owntracks/key" = { };
    "dawarich/oidc_secret_env" = { };
    "dawarich/secret_key_base" = { };
  };

  systemd.services.ot-recorder = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = self.data.systemdHarden // {
      StateDirectory = "%N";
      ExecStartPre = "${pkgs.owntracks-recorder}/bin/ot-recorder --initialize";
      ExecStart = "${pkgs.owntracks-recorder}/bin/ot-recorder owntracks/#";
      PrivateNetwork = false;
      LoadCredential = [
        "cert:${config.sops.secrets."owntracks/cert".path}"
        "key:${config.sops.secrets."owntracks/key".path}"
      ];
    };
  };

  environment.etc."default/ot-recorder".text = ''
    OTR_STORAGEDIR="/var/lib/ot-recorder"
    OTR_HOST="router.rvf6.com"
    OTR_PORT=8883
    OTR_CAFILE="${config.sops.secrets."pki/all-ca".path}"
    OTR_CERTFILE="/run/credentials/ot-recorder.service/cert"
    OTR_KEYFILE="/run/credentials/ot-recorder.service/key"
  '';

  services.dawarich = {
    enable = true;
    localDomain = "dawarich.rvf6.com";
    extraConfig = {
      OIDC_CLIENT_ID = "dawarich";
      OIDC_ISSUER = "https://id.rvf6.com/realms/rvfg";
      OIDC_REDIRECT_URI = "https://dawarich.rvf6.com/users/auth/openid_connect/callback";
      OIDC_AUTO_REGISTER = "true";
      ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
    };
    extraEnvFiles = [ config.sops.secrets."dawarich/oidc_secret_env".path ];
    secretKeyBaseFile = config.sops.secrets."dawarich/secret_key_base".path;
  };

  presets.nginx.virtualHosts."${config.services.dawarich.localDomain}" = { };

  presets.nginx.selfSignedVirtualHosts = {
    "ot.rvf6.com".locations = {
      "/api/".proxyPass = "${otRecorderUrl}/api/";
      "/ws/" = {
        proxyPass = "${otRecorderUrl}/ws/";
        proxyWebsockets = true;
      };
      "/" = {
        root = "${pkgs.owntracks-frontend}/share/owntracks-frontend";
        index = "index.html";
      };
    };
    "ot-recorder.rvf6.com".locations."/".proxyPass = otRecorderUrl;
  };

}
