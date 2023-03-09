{ config, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.presets.vouch;

  vouchOptions = { ... }: {
    options = {
      settings = mkOption {
        type = types.submodule {
          freeformType = (pkgs.formats.yaml { }).type;
          options = {
            vouch = {
              listen = mkOption {
                type = types.str;
                default = "[::1]";
              };
              port = mkOption {
                type = types.port;
                default = 2001;
              };
              document_root = mkOption {
                type = types.str;
                default = "/vouch";
              };
              allowAllUsers = mkOption {
                type = types.bool;
                default = true;
              };
              cookie.secure = mkOption {
                type = types.bool;
                default = true;
              };
            };
            oauth = {
              provider = mkOption {
                type = types.str;
                default = "oidc";
              };
              auth_url = mkOption {
                type = types.str;
                default = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/auth";
              };
              token_url = mkOption {
                type = types.str;
                default = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/token";
              };
              user_info_url = mkOption {
                type = types.str;
                default = "https://id.rvf6.com/realms/rvfg/protocol/openid-connect/userinfo";
              };
              scopes = mkOption {
                type = types.listOf types.str;
                default = [ "openid" "email" "profile" ];
              };
            };
          };
        };
      };

      jwtSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };

      clientSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
      };

      authLocations = mkOption {
        type = types.listOf types.str;
        default = [ "/" ];
      };
    };
  };
in
{
  options = {
    presets.vouch = mkOption {
      type = types.attrsOf (types.submodule vouchOptions);
      default = { };
    };
  };

  config = {
    systemd.services = mapAttrs'
      (name: values:
        let
          settings = recursiveUpdate
            {
              vouch = {
                cookie.domain = "${name}.rvf6.com";
              };
              oauth = {
                client_id = name;
                callback_url = "https://${name}.rvf6.com/vouch/auth";
              };
            }
            values.settings;
          configFile = pkgs.writeText "vouch-${name}-config" (builtins.toJSON settings);
        in
        nameValuePair "vouch-${name}" {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment.VOUCH_CONFIG = "%t/%N/config.json";
          path = [ pkgs.jq ];
          preStart = ''
            cd $RUNTIME_DIRECTORY
            jq -Rs '{"vouch": {"jwt": {"secret": .}}}' $CREDENTIALS_DIRECTORY/jwt > jwt.json
            jq -Rs '{"oauth": {"client_secret": .}}' $CREDENTIALS_DIRECTORY/client > client.json
            jq -s '.[0] * .[1] * .[2]' ${configFile} jwt.json client.json > config.json
            rm -f jwt.json client.json
          '';
          serviceConfig = self.data.systemdHarden // {
            ExecStart = "${pkgs.vouch-proxy}/bin/vouch-proxy";
            LoadCredential = [
              "jwt:${values.jwtSecretFile}"
              "client:${values.clientSecretFile}"
            ];
            RuntimeDirectory = "%N";
            RuntimeDirectoryMode = "0700";
            PrivateNetwork = false;
          };
        }
      )
      cfg;

    services.nginx.virtualHosts = mapAttrs'
      (name: values:
        nameValuePair "${name}.rvf6.com" {
          extraConfig = "error_page 401 = @error401;";
          locations = {
            "/vouch" = {
              proxyPass = "http://${values.settings.vouch.listen}:${toString values.settings.vouch.port}";
              extraConfig = ''
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                auth_request_set $auth_resp_jwt $upstream_http_x_vouch_jwt;
                auth_request_set $auth_resp_err $upstream_http_x_vouch_err;
                auth_request_set $auth_resp_failcount $upstream_http_x_vouch_failcount;
              '';
            };
            "@error401".return = "302 /vouch/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err";
          } // (builtins.listToAttrs (map
            (loc: {
              name = loc;
              value.extraConfig = "auth_request /vouch/validate;";
            })
            values.authLocations));
        }
      )
      cfg;
  };
}
