#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
for directory in "$root"/out/abi*/; do
    tag=$(basename "$directory")
    if ! gh release view "$tag" > /dev/null 2>&1; then
        gh release create "$tag" --title "Packages for JoLT ABI ${tag#abi}" --latest=false \
            --notes "Install with jpm on JoLT. This release is updated in place whenever packages change."
    fi
    gh release upload "$tag" "$directory"/*.pkg.tar.gz --clobber
    if compgen -G "$directory/*.src.tar" > /dev/null; then gh release upload "$tag" "$directory"/*.src.tar --clobber; fi
    gh release upload "$tag" "$directory/index" --clobber
    gh release view "$tag" --json assets --jq '.assets[].name' | while read -r asset; do
        [[ -e $directory/$asset ]] || gh release delete-asset "$tag" "$asset" --yes
    done
done
