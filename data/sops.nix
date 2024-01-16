let

  admin_pgp = "F2E3DA8DE23F4EA11033EDEC535D184864C05736";
  admin_age = "age1vtztgpzm0y0qqd4jjr37hmgfc6l6ptpyks5mgc5n0qk3zsmv9s8ssfw4xc";

  machines = {
    rpi3 = "age1fl08lz0jhvmj468qs0c263dxsgdh0k95wdhz72wgc7rd6whgvu5s47uer0";
    work = "age1qqnqkt2emdm9tqg8err2h80r0g37lkqaujjzeqp0zq32thnkefestmwuru";
    desktop = "age1y6fkn5p6x5zr6rw9r8p5urz0gnhuqqwup0g69hpf4wtuhv4sty3qe7zpu4";
    xiaoxin = "age1xyxljs0yx5dttk77f9r8l7s30js6zjy30h9ldy09mwyhrlhrdptqdzwcek";
    t430 = "age1nprdnw6pdhstfll7hy8jv74evy2kajr257hc7p9jhe446l5xz52qej7y0v";
    nl = "age1h3eu4fukupn8ssquqyfgn587hv5l0ck0gmmvyv8lhncpq0myhq8sg54mxy";
    or2 = "age19p2mn396dl4qnwlyczuahwrjz0dglmcpk0yd86wcn9mn9mpxzffs6qdpa9";
    or3 = "age1t7fpg9m0n5cg5vz0fypltc6c7py548uhpyp8f37hmdnq2j73ky9s6cvhgr";
    az = "age1tpln8534w0ttdp7sd7tf3zeyr3m4w707dakt8kgm8j8c9r0vhyjqhae023";
    ak = "age1rvdmtzg5j8298qvtpmq0rwwu6alev5qf3cg36w0j6jcjpyv4lgvqn5ukum";
    nixctnr = "age192t8u22pq3yhwr7u8zrg38kdxvsxk7n7h4wykjgnsz6u2zx3effqdsmdhc";
  };

in

rec {

  secrets = {
    "secrets/clash" = [ "desktop" "xiaoxin" ];
    "secrets/passwd.yaml" = builtins.attrNames machines;
    "secrets/shadowsocks.yaml" = [ "rpi3" ];
    "secrets/ssh-keys.yaml" = [ "desktop" "xiaoxin" ];
    "secrets/restic.yaml" = [ "desktop" "xiaoxin" "t430" "nl" "or2" "or3" "az" ];
    "secrets/github-token.yaml" = [ "work" "desktop" "xiaoxin" ];
    "secrets/avbroot.yaml" = [ "desktop" "xiaoxin" ];
    "secrets/wireless.yaml" = [ "desktop" "xiaoxin" ];
    "secrets/uu.yaml" = [ "rpi3" "t430" "desktop" "xiaoxin" ];
  } // (builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs
    (name: value:
      { name = "nixos/${name}/.*"; value = [ name ]; }
    )
    machines)));

  configText = builtins.toJSON {
    creation_rules = builtins.attrValues (builtins.mapAttrs
      (name: value:
        {
          path_regex = name;
          key_groups = [
            {
              pgp = [ admin_pgp ];
              age = [ admin_age ] ++ (map (x: machines.${x}) value);
            }
          ];
        }
      )
      secrets);
  };
}

