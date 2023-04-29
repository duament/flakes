{ config, lib, pkgs, ... }:
let
  fishVariablesFile = pkgs.writeText "fish_variables" ''
    # VERSION: 3.0
    SETUVAR fish_features:qmark\x2dnoglob
  '';
in
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      d = "docker";
      dl = "curl -LJO";
      j = "journalctl";
      jb = "journalctl -b 0";
      jp = "journalctl -b 0 -p 4";
      nftadd = "sudo nft add inet nixos-fw input-allow tcp dport";
      nftls = "sudo nft -a list ruleset | less";
      s = "systemctl";
      se = "sudoedit";
      sls = "systemctl list-units --type=service";
      slt = "systemctl list-timers";
      suls = "systemctl --user list-units --type=service";
      sus = "sudo systemctl";
      v = "nvim";
    };
    shellAliases = {
      l = "exa -lag --time-style=long-iso";
      ll = "exa -lg --time-style=long-iso";
      lg = "exa -lag --git --time-style=long-iso";
      sl = "sudo exa -lag --time-style=long-iso";
    };
    interactiveShellInit = ''
      set fish_greeting

      if test $TERM != linux
        set fish_color_command green
        set fish_color_comment brblack
        set fish_color_end yellow
        set fish_color_escape magenta
        set fish_color_keyword cyan
        set fish_color_operator bryellow
        set fish_color_param black
        set fish_color_quote brblue
      end

      set -U fish_features qmark-noglob

      abbr --add --global nixrp --set-cursor nix run nixpkgs#% --
      abbr --add --global nixsp --set-cursor nix shell nixpkgs#% -c
    '';
  };

  home.activation.fishFeatureQmark = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f ${config.xdg.configHome}/fish/fish_variables ]; then
      install -Dm644 ${fishVariablesFile} ${config.xdg.configHome}/fish/fish_variables
    fi
  '';
}
