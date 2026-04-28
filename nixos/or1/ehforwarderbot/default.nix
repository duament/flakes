{ self, pkgs, ... }:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };

  ehPython = pkgs.python3.override {
    packageOverrides = self: super: {
      bullet = self.callPackage ./bullet.nix { source = sources.bullet; };
      itchat = self.callPackage ./itchat.nix { source = sources.itchat; };
      python-telegram-bot = self.callPackage ./python-telegram-bot.nix { };
      ehforwarderbot = self.callPackage ./ehforwarderbot.nix { source = sources.ehforwarderbot; };
      efb-telegram-master = self.callPackage ./efb-telegram-master.nix {
        source = sources.efb-telegram-master;
      };
      efb-wechat-slave = self.callPackage ./efb-wechat-slave.nix { source = sources.efb-wechat-slave; };
    };
  };

  pythonEnv = ehPython.withPackages (
    p: with p; [
      bullet
      itchat
      ehforwarderbot
      efb-telegram-master
      efb-wechat-slave
    ]
  );

  settingsFormat = pkgs.formats.yaml { };
  config = {
    master_channel = "blueset.telegram";
    slave_channels = [ "blueset.wechat" ];
  };
  configFile = settingsFormat.generate "config.yaml" config;
in
{

  systemd.services.ehforwarderbot = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = self.data.systemdHarden // {
      PrivateNetwork = false;
      StateDirectory = "%N";
      Environment = [ "EFB_DATA_PATH=%S/%N" ];
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %S/%N/profiles/default"
        "${pkgs.coreutils}/bin/ln -sf ${configFile} %S/%N/profiles/default/config.yaml"
      ];
      ExecStart = "${pythonEnv}/bin/ehforwarderbot";
    };
  };

}
