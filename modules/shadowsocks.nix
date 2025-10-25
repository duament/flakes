{
  config,
  lib,
  pkgs,
  self,
  utils,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    optionalAttrs
    types
    ;

  cfg = config.presets.shadowsocks;

  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "shadowsocks.json" cfg.settings;

  replacePassword = cfg.passwordFile != null;
  runtimeConfigFile = "/run/shadowsocks/config.json";
in
{
  options.presets.shadowsocks = {

    enable = mkEnableOption "";

    exeName = mkOption {
      type = types.str;
      default = "ssserver";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
      };
    };

    passwordFile = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

  };

  config = mkIf cfg.enable {

    presets.shadowsocks.settings.password = mkIf replacePassword {
      _secret = "/run/credentials/shadowsocks.service/shadowsocks";
    };

    systemd.services.shadowsocks = {
      serviceConfig = self.data.systemdHarden // {
        PrivateNetwork = false;
        LoadCredential = mkIf replacePassword "shadowsocks:${cfg.passwordFile}";
        RuntimeDirectory = mkIf replacePassword "shadowsocks";
        RuntimeDirectoryMode = "0700";
        ExecStart = "${pkgs.shadowsocks-rust}/bin/${cfg.exeName} -c ${
          if replacePassword then runtimeConfigFile else configFile
        }";
      };
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    }
    // (optionalAttrs replacePassword {
      preStart = utils.genJqSecretsReplacementSnippet cfg.settings runtimeConfigFile;
    });

  };
}
