{ config, lib, pkgs, sysConfig, ... }:
let
  cfg = config.presets.cert;

  ca = sysConfig.sops.secrets."pki/ca".path;
  openssl = "${pkgs.openssl}/bin/openssl";

  openssl-conf = pkgs.runCommand "openssl-conf" { } ''
    install -Dm644 ${pkgs.openssl.out}/etc/ssl/openssl.cnf $out
    sed -i '/^\[openssl_init\]/a engines=engine_section' $out
    cat <<EOT >> $out
    [engine_section]
    pkcs11 = pkcs11_section
    [pkcs11_section]
    engine_id = pkcs11
    dynamic_path = ${pkgs.libp11}/lib/engines/pkcs11.so
    MODULE_PATH = ${pkgs.opensc}/lib/opensc-pkcs11.so
    init = 0
    EOT
  '';

  openssl-p11 = pkgs.writeShellApplication {
    name = "openssl-p11";
    text = ''
      export OPENSSL_CONF=${openssl-conf}
      exec ${openssl} "$@"
    '';
  };

  create-cert = usage: ''
    if [ ! -f "$1".key ]; then
      ${openssl} ecparam -out "$1".key -name secp384r1 -genkey
    fi
    ${openssl} req -new -key "$1".key -out "$1".csr -sha384 -subj "${if usage == "client" then "/CN=$1@rvf6.com/emailAddress=$1@rvf6.com" else "/CN=$1.rvf6.com"}" -addext 'basicConstraints = critical, CA:FALSE' -addext "subjectAltName = ${if usage == "client" then "email:$1@rvf6.com" else "DNS:$1.rvf6.com"}" -addext 'extendedKeyUsage = critical, ${usage}Auth'
    if [ ! -f ybk.crt ]; then
      ${pkgs.yubikey-manager}/bin/ykman piv certificates export 9c ybk.crt
    fi
    ${openssl-p11}/bin/openssl-p11 x509 -req -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -in "$1".csr -CA ybk.crt -days 3650 -out "$1".crt -sha384 -copy_extensions copy
  '';

  sign-server = pkgs.writeShellApplication {
    name = "sign-server";
    text = create-cert "server";
  };

  sign-client = pkgs.writeShellApplication {
    name = "sign-client";
    text = ''
      ${create-cert "client"}
      ${openssl} pkcs8 -topk8 -in "$1".key -out "$1".key.p8 -nocrypt
    '';
  };

  sign-client-p12 = pkgs.writeShellApplication {
    name = "sign-client-p12";
    text = ''
      ${create-cert "client"}
      cat "$1".crt ybk.crt ${ca} > "$1"-bundle.crt
      ${openssl} pkcs12 -export -out "$1".p12 -inkey "$1".key -in "$1"-bundle.crt -legacy
    '';
  };
in
{
  options = {
    presets.cert.enable = lib.mkEnableOption "Enable cert signing scripts";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      openssl-p11
      sign-client
      sign-client-p12
      sign-server
    ];
  };
}
