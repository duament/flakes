{ config, lib, ... }:
with lib;
{
  options = {
    presets.chromium.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.chromium.enable {
    programs.chromium = {
      extensions = [
        "dcpihecpambacapedldabdbpakmachpb;https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml" # 
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
        "jlmiipndkcgobnpmcdhinopedkkejkek" # Redirect Link
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "eningockdidmgiojffjmkdblpjocbhgh" # Header Editor
      ];
      extraOpts = {
        #"BlockThirdPartyCookies" = true;
        "BrowserSignin" = 0;
        "MetricsReportingEnabled" = false;
        "PasswordManagerEnabled" = false;
        "SafeBrowsingProtectionLevel" = 0;
        "SearchSuggestEnabled" = false;
        "SyncDisabled" = true;
      };
    };
  };
}
