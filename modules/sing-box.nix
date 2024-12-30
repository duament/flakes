{
  config,
  lib,
  pkgs,
  self,
  utils,
  ...
}:
let
  inherit (lib) any optionalAttrs;

  cfg = config.presets.sing-box;
  settingsFormat = pkgs.formats.json { };
  capNetAdmin = any (o: o ? routing_mark) (cfg.settings.outbounds or [ ]);
  prepareScript = pkgs.writeShellScript "sing-box-config-setup" cfg.prepareScript;
in
{

  options = {
    presets.sing-box = {
      enable = lib.mkEnableOption "sing-box universal proxy platform";

      package = lib.mkPackageOption pkgs "sing-box" { };

      prepareScript = lib.mkOption {
        type = lib.types.lines;
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = settingsFormat.type;
          options = {
            route = {
              geoip.path = lib.mkOption {
                type = lib.types.path;
                default = "${pkgs.sing-geoip}/share/sing-box/geoip.db";
                defaultText = lib.literalExpression "\${pkgs.sing-geoip}/share/sing-box/geoip.db";
                description = ''
                  The path to the sing-geoip database.
                '';
              };
              geosite.path = lib.mkOption {
                type = lib.types.path;
                default = "${pkgs.sing-geosite}/share/sing-box/geosite.db";
                defaultText = lib.literalExpression "\${pkgs.sing-geosite}/share/sing-box/geosite.db";
                description = ''
                  The path to the sing-geosite database.
                '';
              };
            };
          };
        };
        default = { };
        description = ''
          The sing-box configuration, see https://sing-box.sagernet.org/configuration/ for documentation.

          Options containing secret data should be set to an attribute set
          containing the attribute `_secret` - a string pointing to a file
          containing the value the option should be set to.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.packages = [ cfg.package ];

    systemd.services.sing-box = {
      serviceConfig =
        self.data.systemdHarden
        // {
          PrivateNetwork = false;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          StateDirectory = "sing-box";
          StateDirectoryMode = "0700";
          RuntimeDirectory = "sing-box";
          RuntimeDirectoryMode = "0700";
          ExecStartPre = [
            (pkgs.writeShellScript "sing-box-replace-secrets" (
              utils.genJqSecretsReplacementSnippet cfg.settings "/run/sing-box/config.json"
            ))
            prepareScript
          ];
          ExecStart = [
            ""
            "${lib.getExe cfg.package} -D \${STATE_DIRECTORY} -C \${RUNTIME_DIRECTORY} run"
          ];
          ExecReload = [
            ""
            prepareScript
            "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID"
          ];
        }
        // (optionalAttrs capNetAdmin {
          PrivateUsers = false;
          CapabilityBoundingSet = [
            ""
            "CAP_NET_ADMIN"
          ];
          AmbientCapabilities = [
            ""
            "CAP_NET_ADMIN"
          ];
        });
      wantedBy = [ "multi-user.target" ];
    };

  };

}
