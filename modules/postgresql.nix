{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  pgCfg = config.services.postgresql;

  newPostgresPkg = pkgs.postgresql_18;
  newPostgres = newPostgresPkg.withPackages pgCfg.extensions;
in
{
  options = {
    presets.postgresql.enable = mkEnableOption "" // {
      default = pgCfg.enable && pgCfg.package.psqlSchema != newPostgresPkg.psqlSchema;
    };
  };

  config = mkIf config.presets.postgresql.enable {

    environment.systemPackages = [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
        export NEWBIN="${newPostgres}/bin"

        export OLDDATA="${pgCfg.dataDir}"
        export OLDBIN="${pgCfg.finalPackage}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs pgCfg.initdbArgs}

        sudo -u postgres "$NEWBIN/pg_upgrade" \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
          "$@"
      '')
    ];

  };
}
