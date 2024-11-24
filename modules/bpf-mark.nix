{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.presets.bpf-mark;

  markValues = lib.unique (builtins.attrValues cfg);
in
{
  options = {
    presets.bpf-mark = lib.mkOption {
      type = with lib.types; attrsOf int;
      default = { };
      example = {
        "serive1" = 1;
      };
    };
  };

  config = {
    systemd.services =
      builtins.listToAttrs (
        map (markValue: {
          name = "bpf-mark-${toString markValue}";
          value = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.bpftools}/bin/bpftool prog load ${
                pkgs.bpf-mark.override { inherit markValue; }
              } /sys/fs/bpf/mark-${toString markValue} type cgroup/sock";
              ExecStop = "${pkgs.coreutils}/bin/rm -f /sys/fs/bpf/mark-${toString markValue}";
              RemainAfterExit = true;
            };
          };
        }) markValues
      )
      // builtins.mapAttrs (name: value: {
        requires = [ "bpf-mark-${toString value}.service" ];
        after = [ "bpf-mark-${toString value}.service" ];
        serviceConfig.BPFProgram = "sock_create:/sys/fs/bpf/mark-${toString value}";
      }) cfg;
  };
}
