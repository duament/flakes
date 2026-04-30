{
  source,
  lib,
  buildHomeAssistantComponent,
  lupa,
}:

buildHomeAssistantComponent {
  inherit (source) version src;
  owner = "sususweet";
  domain = "midea_auto_cloud";

  dependencies = [
    lupa
  ];

  meta = {
    description = "Control Midea devices via Cloud from Home Assistant";
    homepage = "https://github.com/sususweet/midea_auto_cloud";
    license = lib.licenses.asl20;
  };
}
