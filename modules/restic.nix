{ config, lib, ... }:
let
  cfg = config.presets.restic;
in
{
  options = {
    presets.restic.enable = lib.mkEnableOption "restic";

    presets.restic.exclude = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };

    presets.restic.enablePg = lib.mkEnableOption "restic PostgreSQL";

    presets.restic.pgDumpCommand = lib.mkOption {
      type = lib.types.str;
      default = "sudo -u postgres pg_dumpall";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "restic/password".sopsFile = ../secrets/restic.yaml;
      "restic/s3".sopsFile = ../secrets/restic.yaml;
    };

    services.restic.backups.b2 = {
      initialize = true;
      passwordFile = config.sops.secrets."restic/password".path;
      paths = [ "/persist" ];
      exclude = [
        "/persist/var/cache"
        "/persist/var/lib/postgresql"
        "/persist/var/log"
        "/persist/var/tmp"
        "/persist/home/*/.cache"
      ] ++ cfg.exclude;
      repository = "s3:s3.us-west-004.backblazeb2.com/restic-rvfg";
      environmentFile = config.sops.secrets."restic/s3".path;
      timerConfig = {
        OnCalendar = "daily";
      };
      extraBackupArgs = [ "--compression=auto" ];
      backupPrepareCommand = lib.optionalString cfg.enablePg ''
        ${cfg.pgDumpCommand} > /persist/postgres_backup
      '';
      backupCleanupCommand = lib.optionalString cfg.enablePg ''
        rm -f /persist/postgres_backup
      '';
    };
  };
}
