{
  config,
  lib,
  self,
  ...
}:
with lib;
{
  options = {
    presets.git.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.git.enable {

    home.file.".ssh/allowed_signers".text = concatMapStrings (x: "i@rvf6.com ${x}\n") (
      with self.data.sshPub;
      [
        ybk
        canokey
      ]
    );

    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        user = {
          email = "i@rvf6.com";
          name = "Rvfg";
        };
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
      signing = {
        signByDefault = true;
        key = "~/.ssh/id_ybk.pub";
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        light = true;
        line-numbers = true;
        side-by-side = true;
      };
    };

  };
}
