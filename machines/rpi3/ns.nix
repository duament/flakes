{ ... }:
let
  machine = "OpenWrt";
  vlan = "gaming";
  vethHost = "veth-owrt";
  vethContainer = "veth-wan";
in {
  systemd.network.networks."80-ethernet".vlan = [ vlan ];
  systemd.network.netdevs."50-${vlan}" = {
    netdevConfig = { Name = vlan; Kind = "vlan"; };
    vlanConfig = { Id = 2; };
  };
  systemd.network.networks."50-${vethHost}" = {
    name = vethHost;
    address = [ "10.6.7.1/24" ];
  };

  systemd.services."systemd-nspawn-${machine}" = {
    wants = [ "modprobe@tun.service" "sys-devices-virtual-net-${vlan}.device" ];
    partOf = [ "machines.target" ];
    before = [ "machines.target" ];
    after =  [ "network.target" "modprobe@tun.service" "sys-devices-virtual-net-${vlan}.device" ];
    wantedBy = [ "machines.target" ];
    serviceConfig = {
      ExecStart = "systemd-nspawn --quiet --keep-unit --boot --link-journal=no --network-interface=${vlan} --network-veth-extra=${vethHost}:${vethContainer} --private-users=pick --settings=no --machine=${machine}";
      KillMode = "mixed";
      Type = "notify";
      RestartForceExitStatus = 133;
      SuccessExitStatus = 133;
      Slice = "machine.slice";
      Delegate = "yes";
      TasksMax = 16384;
      WatchdogSec = "3min";
      DevicePolicy = "closed";
      DeviceAllow = [ "/dev/net/tun rwm" "char-pts rw" ];
    };
  };
}
