{ source, stdenvNoCC, lib }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/share/hass/custom_components
    cp -r $src/custom_components/xiaomi_miot $out/share/hass/custom_components/
  '';
  meta = {
    description = "Automatic integrate all Xiaomi devices to HomeAssistant via miot-spec, support Wi-Fi, BLE, ZigBee devices.";
    homepage = "https://github.com/al-one/hass-xiaomi-miot";
    license = lib.licenses.apsl20;
  };
}
