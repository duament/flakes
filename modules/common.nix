{ lib, pkgs, self, ... }:
with lib;
let
  sshPub = import ../lib/ssh-pubkeys.nix;
  wg0 = import ../lib/wg0.nix;
in {
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
  };

  environment.systemPackages = with pkgs; [
    compsize
    lsof
    tcpdump
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.editor = mkDefault false;
  boot.loader.timeout = mkDefault 2;
  boot.tmpOnTmpfs = mkDefault true;

  networking = {
    firewall.enable = false;
    firewall.allowedTCPPorts = [ 22 ];
    nftables.enable = true;
  };

  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "C.UTF-8";

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

  home-manager = {
    extraSpecialArgs = { inherit self; };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

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
    }) [ "nl" "az" "or1" "or2" "or3" "owrt" "rpi3" "t430" "k2" "k1" "work" ]);
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];

  system.stateVersion = "22.11";
}
