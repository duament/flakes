{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  enable = builtins.elem config.networking.hostName self.data.sops.secrets."secrets/avbroot.yaml";

  avbroot-bin = "${pkgs.avbroot}/bin/avbroot";

  avbroot-patch = pkgs.writeShellApplication {
    name = "avbroot-patch";
    text = ''
      set -ex
      DIR=$(mktemp -d)

      ${avbroot-bin} ota extract --input "$1" --directory "$DIR" --boot-only

      ${pkgs.android-tools}/bin/unpack_bootimg --boot_img "$DIR"/boot.img --out "$DIR"/boot --format=mkbootimg > "$DIR"/mkbootimg_args
      VERSION=$(${pkgs.lz4.out}/bin/lz4 -d "$DIR"/boot/kernel - | strings | grep -o -m1 'Linux version [^-]*-[^-]*' || true)  # Linux version 5.10.157-android13
      ANDROID_RELEASE=''${VERSION##*-}  # android13
      VERSION=''${VERSION%-*}  # Linux version 5.10.157
      VERSION=''${VERSION##* }  # 5.10.157
      KERNEL_VERSION=''${VERSION%.*}  # 5.10
      KMI="$ANDROID_RELEASE-$KERNEL_VERSION"

      ${pkgs.ksud}/bin/ksud boot-patch --magiskboot ${pkgs.magiskboot}/bin/magiskboot -b "$DIR"/init_boot.img --kmi "$KMI" -o "$DIR"
      PREPATCHED_PATH=("$DIR"/kernelsu_patched_*.img)

      ${avbroot-bin} ota patch --input "$1" --prepatched "''${PREPATCHED_PATH[0]}" \
        --privkey-avb ${config.sops.secrets."avbroot/avb_key".path} \
        --privkey-ota ${config.sops.secrets."avbroot/ota_key".path} \
        --cert-ota ${config.sops.secrets."avbroot/ota_crt".path} \
        --pass-avb-file /dev/null \
        --pass-ota-file /dev/null

      rm -rf "$DIR"
    '';
  };
in
{
  config = lib.mkIf enable {

    sops.secrets = builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = {
            owner = "rvfg";
            sopsFile = ../secrets/avbroot.yaml;
          };
        })
        [
          "avbroot/avb_key"
          "avbroot/ota_key"
          "avbroot/ota_crt"
        ]
    );

    environment.systemPackages = with pkgs; [
      avbroot
      avbroot-patch
    ];

  };
}
