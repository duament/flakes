{ config, lib, pkgs, self, ... }:
let
  cfg = config.presets.gammu-smsd;
  cfgSrv = cfg.settings.smsd.Service;
  cfgDrv = cfg.settings.smsd.Driver;

  mkValueStringGammu = with lib; v:
    if isInt v then toString v
    else if isString v then v
    else if true == v then "yes"
    else if false == v then "no"
    else throw "unsupported type ${builtins.typeOf v}: ${(lib.generators.toPretty {}) v}";

  settingsFormat = pkgs.formats.ini {
    mkKeyValue = k: v:
      if v == null then "" else
      "${lib.strings.escape [ "=" ] k} = ${mkValueStringGammu v}";
  };

  configFile = settingsFormat.generate "gammu-smsd.conf" cfg.settings;
  configFileRun = "/run/gammu-smsd/gammu-smsd.conf";

  initDBDir = "share/doc/gammu/examples/sql";

  gammuPackage = (pkgs.gammu.override {
    dbiSupport = cfgSrv == "sql" && cfgDrv == "sqlite";
    postgresSupport = cfgSrv == "sql" && cfgDrv == "native_pgsql";
  });
in
{
  options.presets.gammu-smsd = with lib; {
    enable = mkEnableOption (mdDoc "gammu-smsd daemon");

    groups = mkOption {
      type = types.listOf types.str;
      default = [ "dialout" ];
      description = mdDoc "Supplementary groups of the Service";
    };

    pinFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "Path to the PIN file";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          gammu = {
            Device = mkOption {
              type = types.path;
              description = lib.mdDoc "Device node or address of the phone";
              example = "/dev/ttyUSB2";
            };

            Connection = mkOption {
              type = types.str;
              default = "at";
              description = lib.mdDoc "Protocol which will be used to talk to the phone";
            };

            SynchronizeTime = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc "Whether to set time from computer to the phone during starting connection";
            };

            LogFormat = mkOption {
              type = types.enum [ "nothing" "text" "textall" "textalldate" "errors" "errorsdate" "binary" ];
              default = "errors";
              description = lib.mdDoc "Determines what will be logged to the LogFile";
            };
          };

          smsd = {
            PIN = mkOption {
              type = types.nullOr types.str;
              default = if cfg.pinFile != null then "@PIN@" else null;
              description = lib.mdDoc "PIN for SIM card";
            };

            LogFile = mkOption {
              type = types.str;
              default = "syslog";
              description = lib.mdDoc "Path to file where information about communication will be stored";
            };

            Service = mkOption {
              type = types.enum [ "null" "files" "sql" ];
              default = "null";
              description = lib.mdDoc "Service to use to store sms data.";
            };

            InboxPath = mkOption {
              type = types.nullOr types.path;
              default = if cfgSrv == "files" then "/var/lib/gammu-smsd/inbox/" else null;
              description = lib.mdDoc "Where the received SMSes are stored";
            };

            OutboxPath = mkOption {
              type = types.nullOr types.path;
              default = if cfgSrv == "files" then "/var/lib/gammu-smsd/outbox/" else null;
              description = lib.mdDoc "Where SMSes to be sent should be placed";
            };

            SentSMSPath = mkOption {
              type = types.nullOr types.path;
              default = if cfgSrv == "files" then "/var/lib/gammu-smsd/sent/" else null;
              description = lib.mdDoc "Where the transmitted SMSes are placed";
            };

            ErrorSMSPath = mkOption {
              type = types.nullOr types.path;
              default = if cfgSrv == "files" then "/var/lib/gammu-smsd/error/" else null;
              description = lib.mdDoc "Where SMSes with error in transmission is placed";
            };

            Driver = mkOption {
              type = types.nullOr (types.enum [ "native_mysql" "native_pgsql" "odbc" "dbi" ]);
              default = null;
              description = lib.mdDoc "DB driver to use";
            };

            DBDir = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc "Database name to store sms data";
            };

            Database = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc "Database name to store sms data";
            };

            Host = mkOption {
              type = types.nullOr types.str;
              default = if cfgSrv == "sql" && cfgDrv == "native_pgsql" then "localhost" else null;
              description = lib.mdDoc "Database server address";
            };

            User = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc "User name used for connection to the database";
            };

            Password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc "User password used for connection to the database";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ gammuPackage ]
      ++ lib.optionals (cfgSrv == "sql" && cfgDrv == "sqlite") [ pkgs.sqlite ];

    systemd.services.gammu-smsd = {
      description = "gammu-smsd daemon";

      wantedBy = [ "multi-user.target" ];

      wants = lib.optionals (cfgSrv == "sql" && cfgDrv == "native_pgsql") [ "postgresql.service" ];

      preStart = lib.optionalString (cfgSrv == "files")
        (with cfg.settings.smsd; ''
          mkdir -m 755 -p ${InboxPath} ${OutboxPath} ${SentSMSPath} ${ErrorSMSPath}
        '')
      + lib.optionalString (cfgSrv == "sql" && cfgDrv == "sqlite") ''
        cat "${gammuPackage}/${initDBDir}/sqlite.sql" \
        | ${pkgs.sqlite.bin}/bin/sqlite3 ${cfg.settings.smsd.DBDir}
      ''
      + (with cfg.settings.smsd; let
        execPsql = extraArgs: lib.concatStringsSep " " [
          (lib.optionalString (Password != null) "PGPASSWORD=${Password}")
          "${config.services.postgresql.package}/bin/psql"
          (lib.optionalString (Host != null) "-h ${Host}")
          (lib.optionalString (User != null) "-U ${User}")
          "$extraArgs"
          "${cfg.settings.smsd.Database}"
        ];
      in
      lib.optionalString (cfgSrv == "sql" && cfgDrv == "native_pgsql") ''
        echo '\i '"${gammuPackage}/${initDBDir}/pgsql.sql" | ${execPsql ""}
      '')
      + lib.optionalString (cfg.pinFile != null) ''
        cp ${configFile} ${configFileRun}
        chmod 600 ${configFileRun}
        ${pkgs.replace-secret}/bin/replace-secret "@PIN@" $CREDENTIALS_DIRECTORY/pin ${configFileRun}
      '';

      serviceConfig = self.data.systemdHarden // {
        PrivateNetwork = false;
        PrivateDevices = false;
        DeviceAllow = [ "${cfg.settings.gammu.Device} rwm" ];
        SupplementaryGroups = cfg.groups;
        StateDirectory = "%N";
        RuntimeDirectory = "%N";
        ExecStart = "${gammuPackage}/bin/gammu-smsd -c ${if cfg.pinFile != null then configFileRun else configFile}";
        LoadCredential = lib.mkIf (cfg.pinFile != null) [ "pin:${cfg.pinFile}" ];
      };

    };
  };
}
