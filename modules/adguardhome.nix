{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    concatStringsSep
    ;
  cfg = config.presets.adguardhome;

  adguardhomeUpstream = pkgs.runCommand "adguardhome-upstream-dns" { } ''
    cp -r ${inputs.dnsmasq-china-list}/* .
    make SERVER="${concatStringsSep " " cfg.chinaDns}" adguardhome
    cat accelerated-domains.china.adguardhome.conf >> $out
    echo >> $out
    cat apple.china.adguardhome.conf >> $out
    echo >> $out
    cat <<EOF >> $out
    ${concatStringsSep "\n" cfg.upstream}
    EOF
  '';
in
{
  options.presets.adguardhome = {

    enable = mkEnableOption "";

    chinaDns = mkOption {
      type = with types; listOf str;
      default = [
        "[2400:3200::1]"
        "[2402:4e00::]"
        "223.5.5.5"
        "119.29.29.29"
      ];
    };

    upstream = mkOption {
      type = with types; listOf str;
      default = [
        "[2606:4700:4700::1111]"
        "[2001:4860:4860::8888]"
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    bootstrap_dns = mkOption {
      type = with types; listOf str;
      default = cfg.chinaDns;
    };

  };

  config = mkIf cfg.enable {

    services.resolved.enable = false;

    environment.etc."resolv.conf".text = ''
      nameserver ::1
    '';

    services.adguardhome = {
      enable = true;
      host = "[::1]";
      mutableSettings = false;
      settings = {
        dns = {
          inherit (cfg) bootstrap_dns;
          bind_hosts = [ "::" ];
          port = 53;
          ratelimit = 0;
          upstream_dns_file = adguardhomeUpstream.outPath;
        };
        dhcp.enabled = false;
      };
    };

  };
}
