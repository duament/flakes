rec {
  dev = {
    desktop = "U5O7TKM-EBE4QLY-AQOJVMF-27BVZPA-ZDM27MP-IBR6UUL-DBL36UD-RQEN4AO";
    desktop-arch = "SO6SZBC-7SCWFFY-K3MJDYU-ZBFPVC7-XEGQQA4-DXYF73B-NNYZ6Z2-TLSY5AZ";
    xiaoxin = "6APS5KO-H5NO53G-RAPYQWZ-BWVKINP-222XPB7-OGZN7FS-M5DPR27-YQB4IQU";
    xiaoxin-arch = "VJHRT62-5S6EHHC-QLBUXIN-HLBUOKH-2UISZOV-FHSRZR3-WMX2IZN-WH5VTQD";
    iphone = "KIAT2SK-EYWGKKF-FYOMKME-VZCQ5ZS-U3DDFCU-MERAT6L-A2LMW4G-SPFPWQJ";
    pixel7 = "L6Y4I5R-FDGXMJC-QJ4ASKA-RIZ5FLM-M35IRXL-236VYT7-N23BSWX-B46UWAP";
    t430 = "5K2B7C2-DSMED3B-PHMUFKB-ORLOWUC-C2ZYK5S-DDMWXE6-ML6RC2T-Z6ALCAT";
    nl = "IHKBJRX-3LF4I3I-56D3VWT-33PELUZ-7AG4E44-7Z477TH-WBD63DQ-HTOJSAM";
    or1 = "CWGVZVP-2PXRUWK-3Z4OFMZ-2DOTS62-ZQVE45B-BFJJFTS-NA3CIG6-2BQZWAF";
    or3 = "KDSHDWD-W3CFYDY-RG3LQGP-BLY6MKJ-3ONN3NK-CCAFXDG-6X7F4SQ-EJOB3AU";
    az = "3M5RKEG-CA737AY-43AYUKG-6M63PHI-JB3DEB5-2WPJAZG-PB766LJ-4MLSTQS";
  };

  devices = builtins.mapAttrs (name: id: {
    id = id;
    name = name;
  }) dev;

  folders = {
    keepass = {
      id = "xudus-kdccy";
      label = "KeePass";
      path = "~/KeePass";
      devices = [
        "desktop"
        "desktop-arch"
        "xiaoxin"
        "xiaoxin-arch"
        "iphone"
        "pixel7"
        "t430"
        "nl"
        "az"
      ];
      versioning = {
        type = "staggered";
        params.cleanInterval = "3600";
        params.maxAge = "15552000";
      };
    };
    notes = {
      id = "m4f2r-yzqvs";
      path = "~/notes";
      devices = [
        "desktop"
        "desktop-arch"
        "xiaoxin"
        "xiaoxin-arch"
        "t430"
      ];
    };
    session = {
      id = "upou4-bdgln";
      path = "~/session";
      devices = [
        "desktop"
        "desktop-arch"
        "xiaoxin"
        "xiaoxin-arch"
        "t430"
      ];
    };
    music = {
      id = "hngav-zprin";
      label = "Music";
      path = "~/Music";
      devices = [
        "desktop"
        "xiaoxin"
        "or3"
      ];
    };
    archives = {
      id = "mzjds-orbsp";
      path = "~/archives";
      devices = [
        "desktop"
        "xiaoxin"
        "iphone"
        "pixel7"
      ];
    };
    backups = {
      id = "rn8kp-jell8";
      path = "~/backups";
      devices = [
        "desktop"
        "xiaoxin"
      ];
    };
    ebooks = {
      id = "lkrir-xvafz";
      path = "~/ebooks";
      devices = [
        "desktop"
        "xiaoxin"
        "iphone"
      ];
    };
  };
}
