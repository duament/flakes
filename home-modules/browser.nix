{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    presets.browser.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.presets.browser.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        forceWayland = true;
        extraPolicies = {
          ExtensionSettings = {
            "bypasspaywalls@bypasspaywalls" = {
              installation_mode = "force_installed";
              install_url = "https://github.com/iamadamdev/bypass-paywalls-chrome/releases/latest/download/bypass-paywalls-firefox.xpi";
            };
            "uBlock0@raymondhill.net" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            };
            "CanvasBlocker@kkapsner.de" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/canvasblocker/latest.xpi";
            };
            "{e4a8a97b-f2ed-450b-b12d-ee082ba24781}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/greasemonkey/latest.xpi";
            };
            "keepassxc-browser@keepassxc.org" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
            };
            "redirectlink@fluks" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/redirect-link/latest.xpi";
            };
            "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/search_by_image/latest.xpi";
            };
            "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
            };
            "headereditor-amo@addon.firefoxcn.net" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/header-editor/latest.xpi";
            };
          };
          "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = let
            LegitimateURLShortener = "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt";
          in {
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
              "ublock-abuse"
              "ublock-unbreak"
              "easylist"
              "adguard-spyware"
              "adguard-spyware-url"
              "easyprivacy"
              "urlhaus-1"
              "adguard-annoyance"
              "fanboy-annoyance"
              "ublock-annoyances"
              "plowe-0"
              "CHN-0"
              "JPN-1"
              LegitimateURLShortener
            ];
            userFilters = ''
              bilibili.com##.unlogin-popover-avatar:xpath(..)
              bilibili.com##.login-panel-popover:xpath(..)
            '';
          };
        };
      };
      profiles.default = {
        bookmarks = [
          {
            name = "Miniflux";
            url = "https://rss.rvf6.com";
          }
          {
            name = "GitHub";
            url = "https://github.com";
          }
        ];
        settings = {
          "app.shield.optoutstudies.enabled" = true;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;
          "browser.search.suggest.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.urlbar.suggest.searches" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "devtools.netmonitor.persistlog" = true;
          "dom.security.https_only_mode" = true;
          "extensions.pocket.enabled" = false;
          "gfx.webrender.all" = true;
          "identity.fxaccounts.enabled" = false;
          "layers.acceleration.force-enabled" = true;
          "media.autoplay.default" = 5;
          "media.eme.enabled" = false;
          "network.http.referer.XOriginPolicy" = 1;
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.pbmode.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "signon.rememberSignons" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "xul.panel-animations.enabled" = true;
        };
      };
    };

    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--ozone-platform-hint=auto"
      ];
    };
  };
}
