{
  config,
  lib,
  pkgs,
  self,
  ...
}:
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
            "@testpilot-containers" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
            };
          };
          "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = self.data.ublockOriginSettings;
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
          {
            name = "ACG sub";
            url = "https://bbs.acgrip.com/forum-37-1.html";
          }
          {
            name = "Nyaa";
            url = "https://nyaa.si/";
          }
          {
            name = "Search";
            bookmarks = [
              {
                name = "zdic";
                keyword = "zd";
                url = "https://www.zdic.net/search/?sclb=tm&q=%s";
              }
              {
                name = "知乎";
                keyword = "zhi";
                url = "https://www.google.com/search?hl=en-US&gl=US&newwindow=0&q=site%3Awww.zhihu.com+%s";
              }
              {
                name = "moegirl";
                keyword = "moe";
                url = "https://zh.moegirl.org.cn/index.php?search=%s";
              }
              {
                name = "V2EX";
                keyword = "v2";
                url = "https://www.google.com/search?hl=en-US&gl=US&newwindow=0&q=site%3Av2ex.com+%s";
              }
              {
                name = "维基百科";
                keyword = "zh";
                url = "https://zh.wikipedia.org/w/index.php?title=Special:%E6%90%9C%E7%B4%A2&search=%s";
              }
              {
                name = "Baidu";
                keyword = "bd";
                url = "https://www.baidu.com/s?wd=%s";
              }
              {
                name = "Arch manual pages";
                keyword = "man";
                url = "https://man.archlinux.org/search?q=%s";
              }
              {
                name = "NixOS Search";
                keyword = "nixp";
                url = "https://search.nixos.org/packages?channel=unstable&type=packages&query=%s";
              }
              {
                name = "ArchWiki";
                keyword = "aw";
                url = "https://wiki.archlinux.org/index.php?title=Special%3ASearch&wprov=acrw1&search=%s";
              }
              {
                name = "Wikipedia";
                keyword = "wk";
                url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
              }
            ];
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
          "browser.urlbar.resultMenu.keyboardAccessible" = false;
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
          "media.ffmpeg.vaapi.enabled" = true;
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
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
        "--enable-experimental-web-platform-features"
        "--enable-zero-copy"
        "--enable-features=CanvasOopRasterization,ChromeRefresh2023,ChromeWebuiRefresh2023,VaapiVideoDecodeLinuxGL,Vulkan"
      ];
    };
  };
}
