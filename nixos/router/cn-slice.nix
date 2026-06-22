{
  ...
}:
{
  config = {

    networking.nftables.tables.cn = {
      family = "inet";
      content = ''
        set slice {
          type cgroupsv2
        }

        chain do-mark {
          fib daddr type local accept
          socket cgroupv2 level 1 @slice mark 0 mark set 1
        }

        chain out {
          type route hook output priority -800;
          goto do-mark
        }
      '';
    };

    systemd.slices.cn = {
      wantedBy = [ "multi-user.target" ];
      sliceConfig.NFTSet = "cgroup:inet:cn:slice";
    };

  };
}
