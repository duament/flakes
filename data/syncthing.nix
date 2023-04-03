rec {
  dev = {
    desktop = "SO6SZBC-7SCWFFY-K3MJDYU-ZBFPVC7-XEGQQA4-DXYF73B-NNYZ6Z2-TLSY5AZ";
    xiaoxin = "6APS5KO-H5NO53G-RAPYQWZ-BWVKINP-222XPB7-OGZN7FS-M5DPR27-YQB4IQU";
    xiaoxin-arch = "VJHRT62-5S6EHHC-QLBUXIN-HLBUOKH-2UISZOV-FHSRZR3-WMX2IZN-WH5VTQD";
    iphone = "KIAT2SK-EYWGKKF-FYOMKME-VZCQ5ZS-U3DDFCU-MERAT6L-A2LMW4G-SPFPWQJ";
    t430 = "5K2B7C2-DSMED3B-PHMUFKB-ORLOWUC-C2ZYK5S-DDMWXE6-ML6RC2T-Z6ALCAT";
    nl = "IHKBJRX-3LF4I3I-56D3VWT-33PELUZ-7AG4E44-7Z477TH-WBD63DQ-HTOJSAM";
    or1 = "CWGVZVP-2PXRUWK-3Z4OFMZ-2DOTS62-ZQVE45B-BFJJFTS-NA3CIG6-2BQZWAF";
    or3 = "KDSHDWD-W3CFYDY-RG3LQGP-BLY6MKJ-3ONN3NK-CCAFXDG-6X7F4SQ-EJOB3AU";
    az = "3M5RKEG-CA737AY-43AYUKG-6M63PHI-JB3DEB5-2WPJAZG-PB766LJ-4MLSTQS";
  };

  devices = builtins.mapAttrs
    (name: id: {
      id = id;
      name = name;
    })
    dev;

  folders = {
    keepass = {
      id = "xudus-kdccy";
      label = "KeePass";
      path = "~/KeePass";
      devices = [ "desktop" "xiaoxin" "xiaoxin-arch" "iphone" "t430" "nl" "az" ];
      versioning = {
        type = "staggered";
        params.cleanInterval = "3600";
        params.maxAge = "15552000";
      };
    };
    notes = {
      id = "m4f2r-yzqvs";
      label = "notes";
      path = "~/notes";
      devices = [ "desktop" "xiaoxin" "xiaoxin-arch" "t430" ];
    };
    session = {
      id = "upou4-bdgln";
      label = "session";
      path = "~/session";
      devices = [ "desktop" "xiaoxin" "xiaoxin-arch" "t430" ];
    };
    music = {
      id = "hngav-zprin";
      label = "Music";
      path = "~/Music";
      devices = [ "desktop" "xiaoxin" "or3" ];
    };
  };
}
