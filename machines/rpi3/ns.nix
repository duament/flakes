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
  systemd.network.networks."50-simns" = {
    name = "simns";
    linkConfig = { MACAddress = "CC:5B:31:2F:BE:AD"; };
    DHCP = "yes";
    dhcpV4Config = {
      SendHostname = false;
      ClientIdentifier = "mac";
      UseDNS = false;
      UseNTP = false;
      UseSIP = false;
      UseDomains = false;
      RouteTable = 10;
    };
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          FirewallMark = 3;
          Table = 10;
        };
      }
    ];
  };

  networking.nftables.forwardAccept = ''
    iifname veth-owrt oifname eth0 accept;
    iifname eth0 oifname veth-owrt accept;
  '';

  systemd.services."systemd-nspawn-${machine}" = {
    wants = [ "modprobe@tun.service" "sys-devices-virtual-net-${vlan}.device" ];
    partOf = [ "machines.target" ];
    before = [ "machines.target" ];
    after =  [ "network.target" "modprobe@tun.service" "sys-devices-virtual-net-${vlan}.device" ];
    wantedBy = [ "machines.target" ];
    serviceConfig = {
      ExecStart = "systemd-nspawn --quiet --keep-unit --boot --link-journal=no --network-interface=${vlan} --network-veth-extra=${vethHost}:${vethContainer} --network-veth-extra=simns --private-users=pick --settings=no --machine=${machine} --kill-signal=SIGTERM";
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
