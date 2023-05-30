{ source, stdenvNoCC, lib, crudini }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share/Kvantum/Fluent-round-solid-pink
    cp -a $src/Kvantum/Fluent-round-solid/Fluent-round-solid.kvconfig $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.kvconfig
    cp -a $src/Kvantum/Fluent-round-solid/Fluent-round-solid.svg $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.svg
  '';
  postFixup = ''
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.kvconfig '%General' click_behavior 1
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.kvconfig ItemView text.press.color '#444444'
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.kvconfig ItemView text.toggle.color '#444444'
    sed -i 's/0078D4/E893CF/gI' $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.kvconfig
    sed -i 's/0078D4/E893CF/gI' $out/share/Kvantum/Fluent-round-solid-pink/Fluent-round-solid-pink.svg
  '';
  meta = {
    description = "Fluent design theme for kde plasma";
    homepage = "https://github.com/vinceliuice/Fluent-kde";
    license = lib.licenses.gpl3;
  };
}
