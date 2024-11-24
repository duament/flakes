{
  config,
  lib,
  sysConfig,
  ...
}:
let
  cfg = config.presets.nix-gc;
in
{
  options = {
    presets.nix-gc.enable = lib.mkEnableOption "nix-gc" // {
      default = sysConfig != null;
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.user = {
      services.nix-gc.Service = {
        Type = "oneshot";
        ExecStart = "${sysConfig.nix.package.out}/bin/nix-collect-garbage ${sysConfig.nix.gc.options}";
      };
      timers.nix-gc.Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = 10;
      };
    };

  };
}
