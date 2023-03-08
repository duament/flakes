{ ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      d = "docker";
      dl = "curl -LJO";
      j = "journalctl";
      jb = "journalctl -b 0";
      jp = "journalctl -b 0 -p 4";
      nftadd = "sudo nft add inet firewall input_accept tcp dport";
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
    '';
  };
}
