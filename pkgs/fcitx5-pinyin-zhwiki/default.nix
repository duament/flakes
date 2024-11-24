{
  source,
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/share/fcitx5/pinyin/dictionaries/zhwiki.dict
  '';
  meta = {
    description = "zhwiki dictionary for fcitx5-pinyin and rime";
    homepage = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki";
    license = lib.licenses.unlicense;
  };
}
