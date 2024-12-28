{
  config,
  lib,
  self,
  ...
}:
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
      enable = true;
      extensions = [
        "dcpihecpambacapedldabdbpakmachpb;https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml"
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
        "jlmiipndkcgobnpmcdhinopedkkejkek" # Redirect Link
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "eningockdidmgiojffjmkdblpjocbhgh" # Header Editor
        "jinjaccalgkegednnccohejagnlnfdag" # Violentmonkey
        "febaefghpimpenpigafpolgljcfkeakn" # IITC Button
      ];
      extraOpts = {
        BackgroundModeEnabled = false;
        BlockThirdPartyCookies = true;
        BrowserSignin = 0;
        DnsOverHttpsMode = "off";
        HttpsOnlyMode = "force_enabled";
        MetricsReportingEnabled = false;
        PasswordManagerEnabled = false;
        PrivacySandboxAdMeasurementEnabled = false;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;
        SafeBrowsingProtectionLevel = 0;
        SearchSuggestEnabled = false;
        SyncDisabled = true;
        "3rdparty".extensions.cjpalhdlnbpafiamejdnhcphjbkeiagm.adminSettings =
          builtins.toJSON self.data.ublockOriginSettings;
      };
    };
  };
}
