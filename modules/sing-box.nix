{ config, lib, pkgs, self, ... }:
let
  inherit (lib) any optionalAttrs;
  inherit (lib.strings) toJSON;

  cfg = config.presets.sing-box;
  settingsFormat = pkgs.formats.json { };
  configFile = pkgs.writeText "sing-box-config" (toJSON cfg.settings);
  capNetAdmin = any (o: o ? routing_mark) (cfg.settings.outbounds or []);
in
{

  options = {
    presets.sing-box = {
      enable = lib.mkEnableOption "sing-box universal proxy platform";

      package = lib.mkPackageOption pkgs "sing-box" { };

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
      wantedBy = [ "multi-user.target" ];
      serviceConfig = self.data.systemdHarden // {
        PrivateNetwork = false;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        StateDirectory = "sing-box";
        ExecStart = [
          ""
          "${cfg.package}/bin/sing-box -D /var/lib/sing-box -c ${configFile} run"
        ];
      } // (optionalAttrs capNetAdmin {
        PrivateUsers = false;
        CapabilityBoundingSet = [ "" "CAP_NET_ADMIN" ];
        AmbientCapabilities = [ "" "CAP_NET_ADMIN" ];
      });
    };

  };

}
