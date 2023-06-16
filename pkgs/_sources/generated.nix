# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  Fluent-solid-pink = {
    pname = "Fluent-solid-pink";
    version = "83d5cc2013751aa9eeb944dafa3a3460652690ce";
    src = fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Fluent-kde";
      rev = "83d5cc2013751aa9eeb944dafa3a3460652690ce";
      fetchSubmodules = false;
      sha256 = "sha256-jm8ztgoWV8sewCYbFxReiVPjuHY97NslKM1AIoooSiY=";
    };
    date = "2023-05-27";
  };
  Nginx-Fancyindex-Theme = {
    pname = "Nginx-Fancyindex-Theme";
    version = "32d124a0885a7a4409c2dc557c9b1d4bcf836dd5";
    src = fetchFromGitHub {
      owner = "Naereen";
      repo = "Nginx-Fancyindex-Theme";
      rev = "32d124a0885a7a4409c2dc557c9b1d4bcf836dd5";
      fetchSubmodules = false;
      sha256 = "sha256-BFXmTwKcgX94+0wH5x77c9sEP6h9JR73WGY5gp5cyGQ=";
    };
    date = "2022-09-16";
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20230605";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20230605.dict";
      sha256 = "sha256-G44bgOWpnQEbP78idcOobEUm2m+7cYM+UCqyJu+D+9E=";
    };
  };
  flood-for-transmission = {
    pname = "flood-for-transmission";
    version = "2023-04-18T18-03-53";
    src = fetchTarball {
      url = "https://github.com/johman10/flood-for-transmission/releases/download/2023-04-18T18-03-53/flood-for-transmission.tar.gz";
      sha256 = "1r0djf0yvaqdy8xjnh8qb92xapfmnsqbqis3i5xl243w64whfnva";
    };
  };
  transmission-client = {
    pname = "transmission-client";
    version = "a89c39bf8a5c8786becbd65d54e9f45f296a3b5a";
    src = fetchFromGitHub {
      owner = "zj9495";
      repo = "transmission-client";
      rev = "a89c39bf8a5c8786becbd65d54e9f45f296a3b5a";
      fetchSubmodules = false;
      sha256 = "sha256-paqfvc4NaT5fX7/P/HxA92C46WLqTaAegX9GiqaJK0s=";
    };
    date = "2023-02-15";
  };
  transmission-web-control = {
    pname = "transmission-web-control";
    version = "5aeb20c141f6c1ca30c0aaae6b861471a48210d8";
    src = fetchFromGitHub {
      owner = "ronggang";
      repo = "transmission-web-control";
      rev = "5aeb20c141f6c1ca30c0aaae6b861471a48210d8";
      fetchSubmodules = false;
      sha256 = "sha256-LbhAxInDEcf5Y9KPBbBVlqNC4qbVV9/KMK1PxcdFezY=";
    };
    date = "2023-05-21";
  };
  uuplugin = {
    pname = "uuplugin";
    version = "3.13.4";
    src = fetchurl {
      url = "https://uu.gdl.netease.com/uuplugin/openwrt-x86_64/v3.13.4/uu.tar.gz";
      sha256 = "sha256-e1fLKdy2Ep3BzXTid8MEGMgTWougDsbdqfuNsXSvbnk=";
    };
  };
}
