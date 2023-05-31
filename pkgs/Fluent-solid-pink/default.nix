{ source, stdenvNoCC, lib, crudini }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  installPhase = ''
    mkdir -p $out/share/Kvantum/Fluent-solid-pink
    cp -a $src/Kvantum/Fluent/Fluent.kvconfig $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig
    cp -a $src/Kvantum/Fluent/Fluent.svg $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
  '';
  postFixup = ''
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig '%General' click_behavior 1
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig GeneralColors highlight.text.color '#444444'
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig ItemView text.press.color '#444444'
    ${crudini}/bin/crudini --set $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig ItemView text.toggle.color '#444444'
    sed -i 's/0078D4/E893CF/gI' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.kvconfig
    sed -i 's/0078D4/E893CF/gI' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
    sed -i 's/\(id="window-normal.*opacity="\)[^"]*"/\11"/g' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
    sed -i 's/\(id="menu-normal".*opacity="\)[^"]*"/\11"/g' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
    sed -i 's/\(id="itemview-pressed.*\)fill="[^"]*"/\1opacity="0.15"/g' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
    sed -i 's/\(id="itemview-toggled.*\) *fill="[^"]*"/\1/g' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
    sed -i 's/\(id="itemview-toggled.*opacity="\)[^"]*"/\10.1"/g' $out/share/Kvantum/Fluent-solid-pink/Fluent-solid-pink.svg
  '';
  meta = {
    description = "Fluent design theme for kde plasma";
    homepage = "https://github.com/vinceliuice/Fluent-kde";
    license = lib.licenses.gpl3;
  };
}
