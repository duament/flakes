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

  kernelsu = ''curl -Ls -H "Authorization: Bearer $(cat ${config.sops.secrets.github-token.path})" https://api.github.com/repos/tiann/KernelSU/releases/latest'';

  parse-ksu = pkgs.writers.writePython3 "parse-ksu" { } ''
    import json
    import re
    import sys

    prefix = sys.argv[1]

    result = None
    max_patch_level = -1

    data = json.load(sys.stdin)
    for asset in data.get('assets', []):
        name = asset.get('name', ''')
        if name.startswith(prefix) and name.endswith('boot-lz4.img.gz'):
            patch_level = int(re.match(r'^[^-]*-\d+.\d+.(\d+)', name).group(1))
            if patch_level > max_patch_level:
                max_patch_level = patch_level
                result = asset.get('browser_download_url')

    if not result:
        raise ValueError(f'result is {result}')
    print(result, end=''')
  '';

  avbroot-patch = pkgs.writeShellApplication {
    name = "avbroot-patch";
    text = ''
      set -ex
      DIR=$(mktemp -d)

      ${avbroot-bin} ota extract --input "$1" --directory "$DIR" --boot-only
      ${pkgs.android-tools}/bin/unpack_bootimg --boot_img "$DIR"/boot.img --out "$DIR"/boot --format=mkbootimg > "$DIR"/mkbootimg_args
      VERSION=$(strings "$DIR"/boot/kernel | grep -o -m1 'Linux version [^-]*-[^-]*' || true)  # Linux version 5.10.157-android13
      ANDROID_RELEASE=''${VERSION##*-}  # android13
      VERSION=''${VERSION%-*}  # Linux version 5.10.157
      VERSION=''${VERSION##* }  # 5.10.157
      KERNEL_VERSION=''${VERSION%.*}  # 5.10
      URL=$(${kernelsu} | ${parse-ksu} "$ANDROID_RELEASE-$KERNEL_VERSION")
      NAME=''${URL##*/}

      ${pkgs.curl}/bin/curl -Ls -o "$DIR/$NAME" "$URL"
      ${pkgs.gzip}/bin/gunzip "$DIR/$NAME"
      NAME=''${NAME%.gz}

      ${avbroot-bin} ota patch --input "$1" --prepatched "$DIR/$NAME" \
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
