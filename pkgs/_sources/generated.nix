# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  Nginx-Fancyindex-Theme = {
    pname = "Nginx-Fancyindex-Theme";
    version = "32d124a0885a7a4409c2dc557c9b1d4bcf836dd5";
    src = fetchFromGitHub ({
      owner = "Naereen";
      repo = "Nginx-Fancyindex-Theme";
      rev = "32d124a0885a7a4409c2dc557c9b1d4bcf836dd5";
      fetchSubmodules = false;
      sha256 = "sha256-BFXmTwKcgX94+0wH5x77c9sEP6h9JR73WGY5gp5cyGQ=";
    });
    date = "2022-09-16";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20230128";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20230128.dict";
      sha256 = "sha256-SFSNwsyE9W9pCIKlu+8pGVVNdNn6MITA4x7meicbUyQ=";
    };
  };
  flood-for-transmission = {
    pname = "flood-for-transmission";
    version = "2023-02-03T16-14-28";
    src = fetchTarball {
      url = "https://github.com/johman10/flood-for-transmission/releases/download/2023-02-03T16-14-28/flood-for-transmission.tar.gz";
      sha256 = "0w8h7f2jyqgd8m3mpjprh8kiinz14wnywgbny9pabl07vvs335zm";
    };
  };
  transmission-client = {
    pname = "transmission-client";
    version = "a89c39bf8a5c8786becbd65d54e9f45f296a3b5a";
    src = fetchFromGitHub ({
      owner = "zj9495";
      repo = "transmission-client";
      rev = "a89c39bf8a5c8786becbd65d54e9f45f296a3b5a";
      fetchSubmodules = false;
      sha256 = "sha256-paqfvc4NaT5fX7/P/HxA92C46WLqTaAegX9GiqaJK0s=";
    });
    date = "2023-02-15";
  };
  transmission-web-control = {
    pname = "transmission-web-control";
    version = "0bbe64d28667a72130aded6e6d6826efa68566ad";
    src = fetchFromGitHub ({
      owner = "ronggang";
      repo = "transmission-web-control";
      rev = "0bbe64d28667a72130aded6e6d6826efa68566ad";
      fetchSubmodules = false;
      sha256 = "sha256-JMgrbnf6fe3rRO8oWQabchYrUPobwqGJPnbutUtOewU=";
    });
    date = "2022-02-23";
  };
  uuplugin = {
    pname = "uuplugin";
    version = "3.9.2";
    src = fetchurl {
      url = "https://uu.gdl.netease.com/uuplugin/openwrt-x86_64/v3.9.2/uu.tar.gz";
      sha256 = "sha256-XXzy+JKw8IcreUUFyJhuhFHe3m1HQHcRThxRHgRnCLU=";
    };
  };
}
