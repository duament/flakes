{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.presets.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
    ];

    systemd.user.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "Kvantum";
    };

    xdg.configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Light
      style=kvantum

      [Fonts]
      fixed=@Variant(\0\0\0@\0\0\0\x12\0M\0o\0n\0o\0s\0p\0\x61\0\x63\0\x65@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
      general=@Variant(\0\0\0@\0\0\0\x14\0S\0\x61\0n\0s\0 \0S\0\x65\0r\0i\0\x66@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

      [Interface]
      activate_item_on_single_click=2
    '';

    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Light
      style=kvantum

      [Fonts]
      fixed="Monospace,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
      general="Sans Serif,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

      [Interface]
      activate_item_on_single_click=2
    '';

    xdg.configFile."Kvantum/Fluent-solid-pink".source =
      "${pkgs.Fluent-solid-pink}/share/Kvantum/Fluent-solid-pink";
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Fluent-solid-pink
    '';

  };
}
