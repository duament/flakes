{ pkgs, self, ... }: {
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    iperf
    usbutils
    wireguard-tools
  ];

  programs.git = {
    enable = true;
    userEmail = "i@rvf6.com";
    userName = "Rvfg";
    signing = {
      signByDefault = true;
      key = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
    };
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
