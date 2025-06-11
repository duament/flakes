{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.presets.refind;

  refindBuilder = pkgs.replaceVarsWith {
    src = ./refind-builder.py;

    isExecutable = true;

    replacements = {

      python3 = pkgs.python311.withPackages (
        p: with p; [
          pefile
        ]
      );

      nix = config.nix.package.out;

      timeout = if config.boot.loader.timeout != null then config.boot.loader.timeout else "";

      objcopy = "${pkgs.binutils}/bin/objcopy";

      efiStubPath = "${inputs.lanzaboote.packages.${pkgs.system}.stub}/bin/lanzaboote_stub.efi";

      sbsign = "${pkgs.sbsigntool}/bin/sbsign";

      configurationLimit = if cfg.configurationLimit == null then 0 else cfg.configurationLimit;

      inherit (cfg)
        extraConfig
        installAsRemovable
        defaultSelection
        sign
        signKey
        signCert
        ;

      inherit (pkgs)
        refind
        efibootmgr
        coreutils
        utillinux
        gnugrep
        gnused
        gawk
        ;

      inherit (config.boot.loader.efi) efiSysMountPoint canTouchEfiVariables;

      inherit (config.system.nixos) distroName;

    };
  };

in
{

  options.presets.refind = {

    enable = mkOption {
      description = "Whether to enable the refind EFI boot manager";
      type = types.bool;
      default = false;
    };

    installAsRemovable = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Unless you turn this on, rEFInd will install itself in
        <literal>boot.loader.efi.efiSysMountPoint</literal> (namely
        <literal>EFI/refind/refind_$arch.efi</literal>)
        If you've set <literal>boot.loader.efi.canTouchEfiVariables</literal>
        *AND* you are currently booted in UEFI mode, then rEFInd will use
        <literal>efibootmgr</literal> to modify the boot order in the
        EFI variables of your firmware to include this location. If you are
        *not* booted in UEFI mode at the time rEFInd is being installed, the
        NVRAM will not be modified, and your system will not find rEFInd at
        boot time. However, rEFInd will still return success so you may miss
        the warning that gets printed ("<literal>efibootmgr: EFI variables
        are not supported on this system.</literal>").</para>

        <para>If you turn this feature on, rEFInd will install itself in a
        special location within <literal>efiSysMountPoint</literal> (namely
        <literal>EFI/boot/boot$arch.efi</literal>) which the firmwares
        are hardcoded to try first, regardless of NVRAM EFI variables.</para>

        <para>To summarize, turn this on if:
        <itemizedlist>
          <listitem><para>You are installing NixOS and want it to boot in UEFI mode,
          but you are currently booted in legacy mode</para></listitem>
          <listitem><para>You want to make a drive that will boot regardless of
          the NVRAM state of the computer (like a USB "removable" drive)</para></listitem>
          <listitem><para>You simply dislike the idea of depending on NVRAM
          state to make your drive bootable</para></listitem>
        </itemizedlist>
      '';
    };

    configurationLimit = mkOption {
      default = null;
      example = 120;
      type = types.nullOr types.int;
      description = lib.mdDoc ''
        Maximum number of latest generations in the boot menu.
        Useful to prevent boot partition running out of disk space.
        `null` means no limit i.e. all generations
        that were not garbage collected yet.
      '';
    };

    defaultSelection = mkOption {
      description = "The default menu selection";
      type = types.str;
      default = "NixOS";
    };

    sign = mkOption {
      description = "Whether to sign the generated EFI image";
      type = types.bool;
      default = false;
    };

    signKey = mkOption {
      description = "Path to the signing key (PEM-encoded RSA private key)";
      type = types.str;
      default = "";
    };

    signCert = mkOption {
      description = "Path to the certificate (x509 certificate)";
      type = types.str;
      default = "";
    };

    extraConfig = mkOption {
      description = "Extra configuration text appended to refind.conf";
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    boot.loader.external = {
      enable = true;
      installHook = refindBuilder;
    };
  };

}
