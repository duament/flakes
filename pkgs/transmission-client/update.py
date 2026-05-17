#! /usr/bin/env python3

import json
import logging
import os
import subprocess
from pathlib import Path


HASH_JSON_NAME = "hash.json"


def load_json(path: Path | str):
    with open(path) as f:
        return json.load(f)


def run(args: list[str]):
    p = subprocess.run(args, capture_output=True, check=True)
    return p.stdout.strip().decode("utf-8")


def get_source(sources_dir: Path | str, pkg: str):
    assert '"' not in pkg, "invalid pkg name"
    sources_nix = os.path.join(sources_dir, "generated.nix")
    output = run([
        "nix",
        "build",
        "--impure",
        "--json",
        "--no-link",
        "--expr",
        f'let pkgs = import <nixpkgs> {{ }}; in (pkgs.callPackage {sources_nix} {{ }})."{pkg}".src',
    ])
    return json.loads(output)[0]["outputs"]["out"]


def prefetch_yarn(yarn_lock: Path | str):
    hash = run(["nix", "run", "nixpkgs#prefetch-yarn-deps", "--", yarn_lock])
    return run(["nix", "hash", "convert", "--hash-algo", "sha256", hash])


def update(pkg: str):
    pkg_dir = os.path.normpath(os.path.dirname(__file__))
    sources_dir = os.path.normpath(os.path.join(pkg_dir, "../_sources"))

    # skip if unchanged
    hash_file = os.path.join(pkg_dir, HASH_JSON_NAME)
    hash = load_json(hash_file)
    sources = load_json(os.path.join(sources_dir, "generated.json"))
    src_hash = sources[pkg]["src"]["sha256"]
    if hash["src"] == src_hash:
        exit()

    # prefetch
    pkg_src = get_source(sources_dir, pkg)
    yarn_lock = os.path.join(pkg_src, "yarn.lock")
    yarn_hash = prefetch_yarn(yarn_lock)

    # update hash
    hash["src"] = src_hash
    hash["yarnOfflineCache"] = yarn_hash

    # atomic write
    hash_tmp_file = os.path.join(pkg_dir, HASH_JSON_NAME + ".tmp")
    try:
        os.remove(hash_tmp_file)
    except FileNotFoundError:
        logging.debug(f"File {hash_tmp_file} not found, skipping")
    with open(hash_tmp_file, "w") as f:
        json.dump(hash, f, ensure_ascii=False, indent=2)
    os.replace(hash_tmp_file, hash_file)


if __name__ == "__main__":
    update("transmission-client")
