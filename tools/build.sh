#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
source "${JOLT_SDK_DIR:?set JOLT_SDK_DIR to an unpacked JoLT SDK}/env.sh"
if [[ $# -eq 0 ]]; then
    set -- $(cd "$root/packages" && printf '%s\n' */ | tr -d /)
fi
for name in "$@"; do
    bash "$root/tools/makepkg.sh" "$name"
done
bash "$root/tools/index.sh" "$root/out/abi$JOLT_ABI"
