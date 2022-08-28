{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.tmpOnTmpfs = true;

  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "en_US.UTF-8";

  users.defaultUserShell = pkgs.fish;
  users.users.rvfg = {
    isNormalUser = true;
    extraGroups = [ "systemd-journal" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdmqOuypyBe2tF0fQ3R5vp9YkUg1e0lREno2ezJJE86"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIL6r8qfrXMqjnUBhxuBSMt0cfjHo+Vhvqtod8vvwoQk4AAAABHNzaDo= canokey"
    ];
  };

  security.sudo.extraRules = [ { users = [ "rvfg" ]; commands = [ "ALL" ]; } ];
  #security.sudo.extraConfig = ''
  #  Defaults passwd_timeout=0
  #'';

  services.openssh = {
    enable = true;
    kbdInteractiveAuthentication = false;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
}
