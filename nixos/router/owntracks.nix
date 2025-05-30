{
  config,
  pkgs,
  self,
  ...
}:
{

  sops.secrets = {
    "owntracks/cert" = { };
    "owntracks/key" = { };
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

}
