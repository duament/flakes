{ lib, pkgs, inputs, ... }:
let
  sshPub = import ../lib/ssh-pubkeys.nix;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./nftables
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.tmpOnTmpfs = lib.mkDefault true;

  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    inputAccept = ''
      ip6 saddr fe80::/64 udp dport 546 accept comment "DHCPv6 client"
      tcp dport 22 accept comment "SSH"
    '';
  };

  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "en_US.UTF-8";

  users.defaultUserShell = pkgs.fish;
  users.users.rvfg = {
    isNormalUser = true;
    extraGroups = [ "systemd-journal" ];
    openssh.authorizedKeys.keys = [ sshPub.canokey sshPub.a4b sshPub.ed25519 ];
  };

  security.sudo.extraRules = [ { users = [ "rvfg" ]; commands = [ "ALL" ]; } ];
  #security.sudo.extraConfig = ''
  #  Defaults passwd_timeout=0
  #'';

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    hostKeys = [ { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; } ];
    kbdInteractiveAuthentication = false;
    passwordAuthentication = false;
    permitRootLogin = "no";
    ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" ];
    kexAlgorithms = [ "sntrup761x25519-sha512@openssh.com" "curve25519-sha256" "curve25519-sha256@libssh.org" ];
    macs = [ "hmac-sha2-512-etm@openssh.com" "umac-128-etm@openssh.com" ];
    extraConfig = ''
      AuthenticationMethods publickey
      AllowUsers rvfg
    '';
    knownHosts = builtins.listToAttrs (map (host: {
      name = host;
      value = {
        hostNames = [ "${host}.rvf6.com" ];
        publicKey = sshPub."${host}";
      };
    }) [ "nl" "az" "or1" "or2" "or3" ]) // {
      rpi3 = {
        hostNames = [ "10.6.6.1" ];
        publicKey = sshPub.rpi3;
      };
    };
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];

  system.stateVersion = "22.11";
}
