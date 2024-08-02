#! @python3@/bin/python3 -B
import argparse
import os
import os.path
import sys
import errno
import subprocess
import glob
import tempfile
import datetime
import shutil
import ctypes
import pefile
import hashlib
from typing import NamedTuple, List, Optional
libc = ctypes.CDLL("libc.so.6")


class SystemIdentifier(NamedTuple):
    profile: Optional[str]
    generation: int
    specialisation: Optional[str]


def copy_if_not_exists(source: str, dest: str) -> None:
    if not os.path.exists(dest):
        shutil.copyfile(source, dest)


def generation_dir(profile: Optional[str], generation: int) -> str:
    if profile:
        return "/nix/var/nix/profiles/system-profiles/%s-%d-link" % (profile, generation)
    else:
        return "/nix/var/nix/profiles/system-%d-link" % (generation)


def system_dir(profile: Optional[str], generation: int, specialisation: Optional[str]) -> str:
    d = generation_dir(profile, generation)
    if specialisation:
        return os.path.join(d, "specialisation", specialisation)
    else:
        return d


MENU_ENTRY = """
menuentry "@distroName@" {{
    loader {loader}
    {submenuentries}
    graphics on
}}
"""

SUBMENUENTRY = """
    submenuentry "{profile}{specialisation}Generation {generation} {description}" {{
        loader {loader}
    }}
"""


def generation_conf_filename(profile: Optional[str], generation: int, specialisation: Optional[str]) -> str:
    pieces = [
        "nixos",
        profile or None,
        "generation",
        str(generation),
        f"specialisation-{specialisation}" if specialisation else None,
    ]
    return "-".join(p for p in pieces if p)


def profile_path(profile: Optional[str], generation: int, specialisation: Optional[str], name: str) -> str:
    return os.path.realpath("%s/%s" % (system_dir(profile, generation, specialisation), name))


def copy_from_profile(profile: Optional[str], generation: int, specialisation: Optional[str], name: str, dry_run: bool = False) -> str:
    store_file_path = profile_path(profile, generation, specialisation, name)
    suffix = os.path.basename(store_file_path)
    store_dir = os.path.basename(os.path.dirname(store_file_path))
    efi_file_path = "/efi/nixos/%s-%s.efi" % (store_dir, suffix)
    if not dry_run:
        copy_if_not_exists(store_file_path, "@efiSysMountPoint@%s" % (efi_file_path))
    return efi_file_path


def describe_generation(profile: Optional[str], generation: int, specialisation: Optional[str]) -> str:
    try:
        with open(profile_path(profile, generation, specialisation, "nixos-version")) as f:
            nixos_version = f.read()
    except IOError:
        nixos_version = "Unknown"

    kernel_dir = os.path.dirname(profile_path(profile, generation, specialisation, "kernel"))
    module_dir = glob.glob("%s/lib/modules/*" % kernel_dir)[0]
    kernel_version = os.path.basename(module_dir)

    build_time = int(os.path.getctime(system_dir(profile, generation, specialisation)))
    build_date = datetime.datetime.fromtimestamp(build_time).strftime('%F')

    description = "@distroName@ {}, Linux Kernel {}, Built on {}".format(
        nixos_version, kernel_version, build_date
    )

    return description


def mkdir_p(path: str) -> None:
    try:
        os.makedirs(path)
    except OSError as e:
        if e.errno != errno.EEXIST or not os.path.isdir(path):
            raise


def get_generations(profile: Optional[str] = None) -> List[SystemIdentifier]:
    gen_list = subprocess.check_output([
        "@nix@/bin/nix-env",
        "--list-generations",
        "-p",
        "/nix/var/nix/profiles/%s" % ("system-profiles/" + profile if profile else "system"),
        "--option", "build-users-group", ""],
        universal_newlines=True)
    gen_lines = gen_list.split('\n')
    gen_lines.pop()

    configurationLimit = int('@configurationLimit@')
    configurations = [
        SystemIdentifier(
            profile=profile,
            generation=int(line.split()[0]),
            specialisation=None
        )
        for line in gen_lines
    ]
    return configurations[-configurationLimit:]


def get_specialisations(profile: Optional[str], generation: int, _: Optional[str]) -> List[SystemIdentifier]:
    specialisations_dir = os.path.join(
        system_dir(profile, generation, None), "specialisation")
    if not os.path.exists(specialisations_dir):
        return []
    return [SystemIdentifier(profile, generation, spec) for spec in os.listdir(specialisations_dir)]


def remove_old_entries(gens: List[SystemIdentifier]) -> None:
    known_paths = []
    for gen in gens:
        known_paths.append(copy_from_profile(*gen, "kernel", True).lower())
        known_paths.append(copy_from_profile(*gen, "initrd", True).lower())
        known_paths.append(f'/efi/nixos/{generation_conf_filename(*gen)}.efi')
    for path in glob.iglob("@efiSysMountPoint@/efi/nixos/*"):
        efi_path = path.removeprefix('@efiSysMountPoint@').lower()
        if efi_path not in known_paths and not os.path.isdir(path):
            os.unlink(path)


def get_profiles() -> List[str]:
    if os.path.isdir("/nix/var/nix/profiles/system-profiles/"):
        return [
            x for x in os.listdir("/nix/var/nix/profiles/system-profiles/")
            if not x.endswith("-link")
        ]
    return []


def generate_efi(profile: Optional[str], generation: int, specialisation: Optional[str], kernel_params: str) -> str:
    osrel = profile_path(profile, generation, specialisation, 'etc/os-release')
    kernel_path = copy_from_profile(profile, generation, specialisation, 'kernel')
    kernel_full_path = f'@efiSysMountPoint@{kernel_path}'
    initrd_path = copy_from_profile(profile, generation, specialisation, 'initrd')
    initrd_full_path = f'@efiSysMountPoint@{initrd_path}'
    efi_file_path = f'/efi/nixos/{generation_conf_filename(profile, generation, specialisation)}.efi'
    efi_file_full_path = '@efiSysMountPoint@' + efi_file_path
    if os.path.exists(efi_file_full_path):
        return efi_file_path
    with tempfile.TemporaryDirectory() as tmpdir:
        try:
            append_initrd_secrets = profile_path(profile, generation, specialisation, 'append-initrd-secrets')
            subprocess.check_call([append_initrd_secrets, initrd_full_path])
        except FileNotFoundError:
            pass
        unsigned_efi_path = os.path.join(tmpdir, 'efi')
        if '@sign@' == '1':
            objcopy_output = unsigned_efi_path
        else:
            objcopy_output = efi_file_full_path
        with (tempfile.NamedTemporaryFile('w') as cmdline,
              tempfile.NamedTemporaryFile('w') as kernel,
              tempfile.NamedTemporaryFile('w') as initrd,
              tempfile.NamedTemporaryFile('wb') as kernel_hash,
              tempfile.NamedTemporaryFile('wb') as initrd_hash):
            cmdline.write(kernel_params)
            cmdline.flush()
            kernel.write(kernel_path.replace('/', '\\'))
            kernel.flush()
            initrd.write(initrd_path.replace('/', '\\'))
            initrd.flush()
            with open(kernel_full_path, 'rb') as f:
                kernel_hash.write(hashlib.file_digest(f, 'sha256').digest())
                kernel_hash.flush()
            with open(initrd_full_path, 'rb') as f:
                initrd_hash.write(hashlib.file_digest(f, 'sha256').digest())
                initrd_hash.flush()
            stub = pefile.PE('@efiStubPath@')
            osrel_offset = stub.OPTIONAL_HEADER.ImageBase + stub.sections[-1].VirtualAddress + stub.sections[-1].Misc_VirtualSize
            cmdline_offset = osrel_offset + os.path.getsize(osrel)
            kernelp_offset = cmdline_offset + len(kernel_params)
            initrdp_offset = kernelp_offset + len(kernel_path)
            kernelh_offset = initrdp_offset + len(initrd_path)
            initrdh_offset = kernelh_offset + os.path.getsize(kernel_hash.name)
            subprocess.check_call([
                '@objcopy@',
                '--add-section', f'.osrel={osrel}', '--change-section-vma', f'.osrel={osrel_offset:#x}',
                '--add-section', f'.cmdline={cmdline.name}', '--change-section-vma', f'.cmdline={cmdline_offset:#x}',
                '--add-section', f'.linux={kernel.name}', '--change-section-vma', f'.linux={kernelp_offset:#x}',
                '--add-section', f'.initrd={initrd.name}', '--change-section-vma', f'.initrd={initrdp_offset:#x}',
                '--add-section', f'.linuxh={kernel_hash.name}', '--change-section-vma', f'.linuxh={kernelh_offset:#x}',
                '--add-section', f'.initrdh={initrd_hash.name}', '--change-section-vma', f'.initrdh={initrdh_offset:#x}',
                '@efiStubPath@', objcopy_output])
        if '@sign@' == '1':
            subprocess.check_call(['@sbsign@', '--key', '@signKey@', '--cert', '@signCert@', '--output', efi_file_full_path, unsigned_efi_path])
    return efi_file_path


def generation_details(profile: Optional[str], generation: int, specialisation: Optional[str]):
    generation_dir = os.readlink(system_dir(profile, generation, specialisation))
    kernel_params = "init=%s/init " % (generation_dir)
    with open("%s/kernel-params" % (generation_dir)) as params_file:
        kernel_params = kernel_params + params_file.read()
    efi_file_path = generate_efi(profile, generation, specialisation, kernel_params)
    description = describe_generation(profile, generation, specialisation)
    return {
        "profile": f"[{profile}] " if profile else "",
        "specialisation": f"({specialisation}) " if specialisation else "",
        "generation": generation,
        "loader": efi_file_path,
        "description": description
    }


def write_refind_config(path: str, default_generation: SystemIdentifier, generations: List[SystemIdentifier]) -> None:
    with open(path, 'w') as f:
        if "@canTouchEfiVariables@" == "1":
            f.write("use_nvram true\n")
        else:
            f.write("use_nvram false\n")

        if "@timeout@" != "":
            f.write("timeout @timeout@\n")

        # prevent refind from adding boot-entries for kernels in /EFI/nixos
        # this is done so that the default_selection will not mistakenly use the wrong entry
        f.write("dont_scan_dirs ESP:/EFI/nixos\n")
        f.write("default_selection \"@defaultSelection@\"\n")

        rev_generations = sorted(generations, key=lambda x: x[1], reverse=True)
        submenuentries = []
        for generation in rev_generations:
            submenuentries.append(SUBMENUENTRY.format(
                **generation_details(*generation)
            ))
            for specialisation in get_specialisations(*generation):
                submenuentries.append(SUBMENUENTRY.format(
                    **generation_details(*specialisation)
                ))

        f.write(MENU_ENTRY.format(
            **generation_details(*default_generation),
            submenuentries="\n".join(submenuentries)
        ))

        f.write('''@extraConfig@''')


def main():
    parser = argparse.ArgumentParser(description='Update @distroName@-related refind files')
    parser.add_argument('default_config', metavar='DEFAULT-CONFIG', help='The default @distroName@ config to boot')
    args = parser.parse_args()

    if "@installAsRemovable@":
        install_target = "@efiSysMountPoint@/EFI/BOOT"
    else:
        install_target = "@efiSysMountPoint@/EFI/refind"

    mkdir_p(install_target)
    mkdir_p("@efiSysMountPoint@/efi/nixos")

    gens = get_generations()
    for profile in get_profiles():
        gens += get_generations(profile)
    remove_old_entries(gens)
    default_gen = None
    for gen in gens:
        if os.readlink(system_dir(*gen)) == args.default_config:
            default_gen = gen

    # write config before installing refind in order to enforce update
    # this results in using the location of refind.conf as install-directory
    write_refind_config(f"{install_target}/refind.conf", default_gen, gens)

    if os.getenv("NIXOS_INSTALL_BOOTLOADER") == "1":
        subprocess.check_call(
            ["@refind@/bin/refind-install", "--yes"],
            env={"PATH": ":".join([
                "@efibootmgr@/bin",
                "@coreutils@/bin",
                "@utillinux@/bin",
                "@gnugrep@/bin",
                "@gnused@/bin",
                "@gawk@/bin",
            ])}
        )
        # TODO Sign
    # TODO Update refind efi

    # Since fat32 provides little recovery facilities after a crash,
    # it can leave the system in an unbootable state, when a crash/outage
    # happens shortly after an update. To decrease the likelihood of this
    # event sync the efi filesystem after each update.
    rc = libc.syncfs(os.open("@efiSysMountPoint@", os.O_RDONLY))
    if rc != 0:
        print("could not sync @efiSysMountPoint@: {}".format(os.strerror(rc)), file=sys.stderr)


if __name__ == '__main__':
    main()
