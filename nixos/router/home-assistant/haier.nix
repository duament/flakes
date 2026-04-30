{
  source,
  lib,
  buildHomeAssistantComponent,
}:

buildHomeAssistantComponent {
  inherit (source) version src;
  owner = "banto6";
  domain = "haier";

  meta = {
    description = "Haier HomeAssistant integration";
    homepage = "https://github.com/banto6/haier";
    license = lib.licenses.asl20;
  };
}
