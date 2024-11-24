{
  config,
  pkgs,
  self,
  ...
}:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.ssh.enable = true;
  programs.ssh.matchBlocks = rec {
    devbash = {
      user = "ruifeng.ma";
      hostname = "10.9.112.14";
    };
    dev = devbash // {
      forwardAgent = true;
      extraOptions = {
        RequestTTY = "force";
        RemoteCommand = ". ~/n.sh";
      };
    };
    devroot = devbash // {
      extraOptions = {
        RequestTTY = "force";
        RemoteCommand = "~/root";
      };
    };
    sit = {
      user = "root";
      hostname = "10.9.114.25";
    };
    jump = {
      user = "root";
      hostname = "10.9.231.27";
    };
    prod = {
      user = "root";
      hostname = "172.21.3.17";
      proxyJump = "jump";
    };
  };

  presets.git.enable = true;
  presets.python.enable = true;

  home.packages = with pkgs; [
    checksec
    gcc
    gdb
    kubectl
    kubevirt
    unar
  ];

  programs.gpg.enable = true;
  programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";
}
