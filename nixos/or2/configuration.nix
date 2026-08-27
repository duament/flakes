{ lib, pkgs, ... }:
let
  ccKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1a8SSEd+lEdS7VY6XN1YtB9q81c3/hXKACDClphoSE openpgp:0x33333333";
  httpTlsListen = [
    {
      addr = "0.0.0.0";
      port = 80;
    }
    {
      addr = "[::]";
      port = 80;
    }
    {
      addr = "127.0.0.1";
      port = 4431;
      ssl = true;
    }
    {
      addr = "[::1]";
      port = 4431;
      ssl = true;
    }
  ];
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or2";
  networking.firewall = {
    allowedTCPPorts = [
      255
      444
      2053
    ];
    allowedUDPPorts = [ 443 ];
    allowedUDPPortRanges = [
      {
        from = 444;
        to = 450;
      }
      {
        from = 40000;
        to = 50000;
      }
    ];
    extraForwardRules = lib.mkAfter ''
      iifname "tun0" oifname "ens3" accept comment "ooxxcc OpenVPN egress"
    '';
  };
  networking.nftables.masquerade = lib.mkAfter [ ''oifname "ens3" ip saddr 10.8.9.0/24 counter'' ];
  networking.nftables.tables.ooxxcc-hysteria = {
    family = "ip";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat;
        policy accept;
        iifname "ens3" udp dport 444-450 counter redirect to :443 comment "ooxxcc hysteria2 low range"
        iifname "ens3" udp dport 40000-50000 counter redirect to :443 comment "ooxxcc hysteria2 high range"
      }
    '';
  };
  networking.nftables.tables.ooxxcc-hysteria6 = {
    family = "ip6";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat;
        policy accept;
        iifname "ens3" udp dport 444-450 counter redirect to :443 comment "ooxxcc hysteria2 low range ipv6"
        iifname "ens3" udp dport 40000-50000 counter redirect to :443 comment "ooxxcc hysteria2 high range ipv6"
      }
    '';
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  presets.nginx.enable = true;
  presets.nginx.quic = false;
  presets.nginx.virtualHosts."rvfg.ooxxcc.com" = { };

  services.nginx = {
    streamConfig = ''
      map $ssl_preread_server_name $backend_443 {
        ~akamaihd\.net$ 127.0.0.1:8443;
        ~anytls\.ooxxcc\.com$ 127.0.0.1:8444;
        default 127.0.0.1:4431;
      }

      server {
        listen 0.0.0.0:443;
        listen [::]:443;
        ssl_preread on;
        proxy_connect_timeout 10s;
        proxy_timeout 1h;
        proxy_pass $backend_443;
      }
    '';
    virtualHosts."or2.rvf6.com".listen = lib.mkForce httpTlsListen;
    virtualHosts."rvfg.ooxxcc.com" = {
      listen = lib.mkForce httpTlsListen;
      locations."/generate_204".return = "204";
      locations."/vlessgrpc".extraConfig = ''
        if ($content_type !~ "application/grpc") { return 404; }
        if ($request_method != "POST") { return 404; }
        grpc_read_timeout 1h;
        grpc_send_timeout 1h;
        client_body_timeout 1h;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_socket_keepalive on;
        client_body_buffer_size 1m;
        client_max_body_size 0;
        grpc_pass grpc://127.0.0.1:10002;
      '';
      locations."/".return = "404";
    };
  };

  systemd.services."systemd-nspawn@arch" = {
    overrideStrategy = "asDropin";
    wantedBy = [ "machines.target" ];
    serviceConfig = {
      ExecStart = lib.mkForce [
        ""
        "${pkgs.systemd}/bin/systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --settings=override --machine=%i --hostname=nspawn-rvfg --capability=CAP_NET_ADMIN,CAP_NET_RAW"
      ];
      ExecStop = lib.mkForce [
        ""
        "${pkgs.systemd}/bin/machinectl poweroff %i"
      ];
      TimeoutStopSec = "120s";
      MemoryMax = "512M";
      MemorySwapMax = 0;
    };
  };

  home-manager.users.rvfg = import ./home.nix;

  users.users.rvfg.openssh.authorizedKeys.keys = [ ccKey ];
  environment.etc."ssh/pam_rssh_keys.d/rvfg".text = ''
    ${ccKey}
  '';

}
