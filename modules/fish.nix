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
  };
}
