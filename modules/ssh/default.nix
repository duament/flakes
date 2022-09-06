{ ... }:
{
  home.file.".ssh/id_canokey.pub".source = ./id_canokey.pub;
  home.file.".ssh/id_a4b.pub".source = ./id_a4b.pub;
  home.file.".ssh/id_ed25519.pub".source = ./id_ed25519.pub;

  programs.ssh = let
    sshIdentities = [ "~/.ssh/id_canokey" "~/.ssh/id_a4b" "~/.ssh/id_ed25519.pub" ];
  in {
    enable = true;
    compression = true;
    serverAliveInterval = 10;
    extraConfig = ''
      CheckHostIP no
    '';
    matchBlocks = builtins.listToAttrs (map (host: {
      name = host;
      value = {
        user = "duama";
        hostname = "${host}.rvf6.com";
        identityFile = sshIdentities;
        forwardAgent = true;
      };
    }) [ "nl" "az" "or1" "or2" "or3" ]) // {
      "github.com" = {
        identityFile = sshIdentities;
      };
    };
  };
}
