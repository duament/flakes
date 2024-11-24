let
  LegitimateURLShortener = "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt";
in
{
  userSettings = {
    externalLists = LegitimateURLShortener;
    importedLists = [ LegitimateURLShortener ];
  };
  selectedFilterLists = [
    "user-filters"
    "ublock-filters"
    "ublock-badware"
    "ublock-privacy"
    "ublock-quick-fixes"
    "ublock-unbreak"
    "easylist"
    "adguard-spyware"
    "adguard-spyware-url"
    "easyprivacy"
    "urlhaus-1"
    "plowe-0"
    "adguard-cookies"
    "adguard-mobile-app-banners"
    "adguard-other-annoyances"
    "adguard-popup-overlays"
    "adguard-social"
    "adguard-widgets"
    "fanboy-thirdparty_social"
    "ublock-annoyances"
    "CHN-0"
    "JPN-1"
    LegitimateURLShortener
  ];
  userFilters = ''
    bilibili.com##.unlogin-popover-avatar:xpath(..)
    bilibili.com##.login-panel-popover:xpath(..)
  '';
}
