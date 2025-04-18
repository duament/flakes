# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  Fluent-solid-pink = {
    pname = "Fluent-solid-pink";
    version = "9d6b7d4733707c38f72e8a614528f1df591419f3";
    src = fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Fluent-kde";
      rev = "9d6b7d4733707c38f72e8a614528f1df591419f3";
      fetchSubmodules = false;
      sha256 = "sha256-eRAM4f2scGLSDNljI3qjyn5XF7zjrsp8ArIGswNyimY=";
    };
    date = "2024-08-27";
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
  aleo = {
    pname = "aleo";
    version = "ce875e48d9983031648e87f38b7a269f4fbf5eb5";
    src = fetchFromGitHub {
      owner = "AlessioLaiso";
      repo = "aleo";
      rev = "ce875e48d9983031648e87f38b7a269f4fbf5eb5";
      fetchSubmodules = false;
      sha256 = "sha256-HSxP5/sLHQTujBVt1u93625EXEc42lxpt8W1//6ngWM=";
    };
    date = "2023-06-03";
  };
  avbroot = {
    pname = "avbroot";
    version = "v3.15.0";
    src = fetchFromGitHub {
      owner = "chenxiaolong";
      repo = "avbroot";
      rev = "v3.15.0";
      fetchSubmodules = false;
      sha256 = "sha256-OICx08MiiiocqVB61fMiUSmG7QOpsrLfPkLuDktTXt0=";
    };
    cargoLock."Cargo.lock" = {
      lockFile = ./avbroot-v3.15.0/Cargo.lock;
      outputHashes = {
        "zip-0.6.6" = "sha256-oZQOW7xlSsb7Tw8lby4LjmySpWty9glcZfzpPuQSSz0=";
      };
    };
  };
  fcitx5-pinyin-zhwiki = {
    pname = "fcitx5-pinyin-zhwiki";
    version = "20250310";
    src = fetchurl {
      url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.5/zhwiki-20250310.dict";
      sha256 = "sha256-73yhLHfCLVlDxF74tS06bwiXYYVL5zzH8mnRgfJEahw=";
    };
  };
  flood-for-transmission = {
    pname = "flood-for-transmission";
    version = "2024-11-16T12-26-17";
    src = fetchTarball {
      url = "https://github.com/johman10/flood-for-transmission/releases/download/2024-11-16T12-26-17/flood-for-transmission.tar.gz";
      sha256 = "sha256-K/eqvPfZ1hdaeYikHaE34agfpjsOLUOm/x4Hxhr9hFU=";
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
    version = "c9d83844ee2cf2f07e36e03660a2886da5f4208a";
    src = fetchFromGitHub {
      owner = "ronggang";
      repo = "transmission-web-control";
      rev = "c9d83844ee2cf2f07e36e03660a2886da5f4208a";
      fetchSubmodules = false;
      sha256 = "sha256-NQ1wZwe8VRIcvuLtUhjjldD00f1WgZsGAIkTDkIxgLw=";
    };
    date = "2025-02-21";
  };
  uuplugin-aarch64 = {
    pname = "uuplugin-aarch64";
    version = "8.9.14";
    src = fetchurl {
      url = "https://uu.gdl.netease.com/uuplugin/openwrt-aarch64/v8.9.14/uu.tar.gz";
      sha256 = "sha256-9glgipOpJUtW5HcdY/izVwgQWTJJMSAhAcxB1Yn+hVk=";
    };
  };
  uuplugin-x86_64 = {
    pname = "uuplugin-x86_64";
    version = "8.9.14";
    src = fetchurl {
      url = "https://uu.gdl.netease.com/uuplugin/openwrt-x86_64/v8.9.14/uu.tar.gz";
      sha256 = "sha256-zdu1togxPAPRMMwdAPQJI2omaSoVv5WDEBnxPtGTYKA=";
    };
  };
  uutunnel = {
    pname = "uutunnel";
    version = "46b76bb4ee2e523e5b835b5d70d87efa2d099295";
    src = fetchFromGitHub {
      owner = "duament";
      repo = "uutunnel";
      rev = "46b76bb4ee2e523e5b835b5d70d87efa2d099295";
      fetchSubmodules = false;
      sha256 = "sha256-I6x0outD7wSOdaou3Ner5MclMyKRZPdss/CY0KpZDuE=";
    };
    cargoLock."Cargo.lock" = {
      lockFile = ./uutunnel-46b76bb4ee2e523e5b835b5d70d87efa2d099295/Cargo.lock;
      outputHashes = {
        
      };
    };
    date = "2024-02-29";
  };
}
