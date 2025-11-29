{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
with lib;
{
  nixpkgs.overlays = [ self.overlays.default ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://rvfg.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "rvfg.cachix.org-1:Y4KBTduWzzLGMyy/SQPkzXuHiYeeaIFszIQI0kA59lQ="
      ];
      trusted-users = [ "deploy" ];
      flake-registry = "/etc/nix/registry.json";
      auto-allocate-uids = mkDefault true;
      use-cgroups = mkDefault true;
      nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  environment.systemPackages = with pkgs; [
    bandwhich
    compsize
    conntrack-tools
    dig
    lsof
    tcpdump
  ];

  boot = {
    loader = {
      systemd-boot.editor = mkDefault false;
      timeout = mkDefault 2;
      efi.efiSysMountPoint = mkDefault "/efi";
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    initrd.systemd.enable = mkDefault true;
    tmp.useTmpfs = mkDefault true;
  };

  networking = {
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = [ 22 ];
      filterForward = true;
      logRefusedConnections = false;
      pingLimit = "20/second";
    };
    nftables = {
      enable = mkDefault true;
      flushRuleset = false;
      preCheckRuleset = "sed '/^include/d' -i ruleset.conf";
    };
  };
  systemd.network.networks = lib.mkIf config.networking.useDHCP {
    "99-ethernet-default-dhcp" = {
      dhcpV6Config.UseDelegatedPrefix = false;
      networkConfig.IPv6AcceptRA = true;
    };
    "99-wireless-client-dhcp" = {
      dhcpV6Config.UseDelegatedPrefix = false;
      networkConfig.IPv6AcceptRA = true;
    };
  };

  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "C.UTF-8";

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  home-manager = {
    extraSpecialArgs = {
      inherit self;
      sysConfig = config;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs.fish.enable = true;

  services.dbus.implementation = "broker";
  services.nscd.enableNsncd = true;

  services.openssh = {
    enable = mkDefault true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowUsers = [
        "rvfg"
        "deploy"
      ];
      KexAlgorithms = [
        "mlkem768x25519-sha256"
        "sntrup761x25519-sha512"
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
    knownHosts =
      builtins.listToAttrs (
        map
          (host: {
            name = host;
            value = {
              hostNames = [ "${host}.rvf6.com" ];
              publicKey = self.data.sshPub."${host}";
            };
          })
          [
            "nl"
            "az"
            "or1"
            "or2"
            "or3"
            "ak"
            "sg"
            "owrt"
            "rpi3"
            "t430"
            "k2"
            "k1"
            "work"
            "router"
          ]
      )
      // {
        "github" = {
          hostNames = [ "github.com" ];
          publicKey = self.data.sshPub.github;
        };
      };
  };

  services.postgresql.package = mkOverride 900 pkgs.postgresql_18;

  systemd.services.systemd-importd.environment.SYSTEMD_IMPORT_BTRFS_QUOTA = "0";

  sops = {
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ];
  };

  system.stateVersion = "25.11";
}
