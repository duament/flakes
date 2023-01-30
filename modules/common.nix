{ inputs, lib, pkgs, self, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
  authorizedKeys = with sshPub; [ ybk canokey a4b ed25519 ];
in
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://nix-community.cachix.org"
      "https://rvfg.cachix.org"
      "https://cache.rvf6.com"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rvfg.cachix.org-1:Y4KBTduWzzLGMyy/SQPkzXuHiYeeaIFszIQI0kA59lQ="
      "cache.rvf6.com-1:puyypMB+P2nYa5Zg40uzzAh2ncg/cwSTR/OxqQ8yK7Q="
    ];
    trusted-users = [ "deploy" ];
    flake-registry = "/etc/nix/registry.json";
  };
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  environment.systemPackages = with pkgs; [
    compsize
    dig
    lsof
    tcpdump
  ];

  boot = {
    loader.systemd-boot.editor = mkDefault false;
    loader.timeout = mkDefault 2;
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    initrd.systemd.enable = mkDefault true;
    tmpOnTmpfs = mkDefault true;
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
      filterForward = true;
      logRefusedConnections = false;
      pingLimit = "20/second";
    };
    nftables = {
      enable = mkDefault true;
      flushRuleset = false;
    };
  };

  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "C.UTF-8";

  users.defaultUserShell = pkgs.fish;
  users.users.rvfg = {
    isNormalUser = true;
    extraGroups = [ "systemd-journal" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.groups.deploy = { };
  users.users.deploy = {
    isSystemUser = true;
    group = "deploy";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  security.sudo.extraRules = [
    {
      users = [ "rvfg" ];
      commands = [ "ALL" ];
    }
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nix-env";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/switch-to-configuration";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  #security.sudo.extraConfig = ''
  #  Defaults passwd_timeout=0
  #'';

  home-manager = {
    extraSpecialArgs = { inherit self; };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs.fish.enable = true;

  services.dbus.implementation = "broker";
  services.nscd.enableNsncd = true;

  services.openssh = {
    enable = mkDefault true;
    hostKeys = [{ path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }];
    ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" ];
    kexAlgorithms = [ "sntrup761x25519-sha512@openssh.com" "curve25519-sha256" "curve25519-sha256@libssh.org" ];
    macs = [ "hmac-sha2-512-etm@openssh.com" "umac-128-etm@openssh.com" ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowUsers = "rvfg deploy";
    };
    knownHosts = builtins.listToAttrs (map
      (host: {
        name = host;
        value = {
          hostNames = [ "${host}.rvf6.com" ];
          publicKey = sshPub."${host}";
        };
      }) [ "nl" "az" "or1" "or2" "or3" "owrt" "rpi3" "t430" "k2" "k1" "work" ]);
  };

  systemd.services.systemd-importd.environment.SYSTEMD_IMPORT_BTRFS_QUOTA = "0";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];

  system.stateVersion = "22.11";
}
