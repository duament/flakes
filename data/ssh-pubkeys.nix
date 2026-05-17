let
  keys = {
    ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdmqOuypyBe2tF0fQ3R5vp9YkUg1e0lREno2ezJJE86";
    canokey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIL6r8qfrXMqjnUBhxuBSMt0cfjHo+Vhvqtod8vvwoQk4AAAABHNzaDo=";
    a4b = "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBN/ZYR5bXgmEYjhHWjtCZvocjMg0C921Gl61aib+IxlGIvtgGqJQUJsDu6xVsHQq7G7h0kBvUKJlaVNWitT2HCIAAAAEc3NoOg==";
    ybk = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHBxARed/4cfZg7KhBIyS4t8bip4bfo6U6mjOnyA1Ve9AAAABHNzaDo=";
    ip16 = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBImURynKuV6AUB6n5e4r2GBRrtolOjonx4XE60mx8EK005BNNv9e7qJgoN4D1dAYyesPKUZA1e8pTkmHFS/H8DE=";
    pixel7 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJk6qHNPPjJdDUiC7XC2YF6eUg0zu/0uqRlQjN2yIxK pixel7";

    owrt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISozBuc4XJVzmEu2yuX+O3rdA9jhIJY5qiUN/sTD+do";
    rpi3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQPPwlnFpA0jWzZHSxjrPhWw0LiBY6qpU3DJR6rOf5r";
    rpi3-init = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOyTjEV9Jc5TO2xyyah6Q5kWlxnzGOZ3GUjBtqK1QSg";
    t430 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS7ir1//vEyR9ucVOGKBTifZKJpciguUp+tGoeZGJhK";
    t430-init = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqQYZ/NjMCVajUS38ru4F9QlmActthDhX3Fq8W+xnG3";
    router = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHloY+vxqZua2vUg9KKXadUBekbgZLJWpd5vFrAtNAj9";
    router-init = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYIWsO/9gbyadMCa6IB+hEyjwfq0+bPtkYD0cZkUli8";
    k2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNeaZNbAlkXyX3m87s8NKFsbXcN1jiMp7muieSYrY7n";
    k1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5D5lost1y4VJoTI2RUnbUuDr++vIyNADW2vUf77j2W";
    work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4UESV5NcZBCRjuwFVbZzX8J6YQjRTMUvlcsJ4eO/uL";
    desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPBB1PsnH+y8UMlS9q/atk68sALsGyq8Rnq87/H9HfrQ";
    xiaoxin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINb9UNoaFdvPTxo9jcoKUhRDh2Wow2KEEIGuUVzUNgbJ";

    nl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/rhyxwCs+7Q+zzDfXUOrgQLtlNiunlWMKeyJD6+Jfo";
    or1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhnuNC6/h7v0amQUrWQHk/TL1jyrUSFu6iJCUDWTo9W";
    or2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQLQnscdJ8dgVxROJmaT63TVkRyUnyhGAs+yUTajBh3";
    or3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOiFV9RY+V9Yc+qtF+Mt7xZIBcYewmgn6dGkORXW5VrE";
    ak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOH+CAQO3TLPppb3GXE8/2+33kn0ejC1Osx1MMsJvQdd";
    sg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGrYMbv6EzBWxkluuydLdIaIpLYBjNWtfX0z9shyQRkR";
    twak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwrx9wGDB/AoJyG3s6tX583Da3OO2KmbZJVCbLKdO2i";
    jp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkimtHteI020dAw9nMYlUzAAubx7AdsQER7HZGpzDC9";

    github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

    github-action-deploy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2DsZM21JRgzLA0Fv88Qv3HQ78nqf+DnpQZBHNPW+75";
  };
in
keys
// rec {

  securityKeyNames = [
    "ybk"
    "canokey"
    "a4b"
    "ip16"
  ];
  securityKeys = map (name: keys.${name}) securityKeyNames;

  authorizedKeyNames = securityKeyNames ++ [
    "ed25519"
    "pixel7"
  ];
  authorizedKeys = map (name: keys.${name}) authorizedKeyNames;

  hosts = [
    "rpi3"
    "t430"
    "router"
    "work"

    "nl"
    "or1"
    "or2"
    "or3"
    "ak"
    "sg"
    "twak"
    "jp"
  ];

  rootHosts = [
    "owrt"
    "k2"
    "k1"
  ];
}
