#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
name=$1
recipe_dir="$root/packages/$name"
[[ -r $recipe_dir/PKGBUILD ]] || { printf 'makepkg: no recipe for %s\n' "$name" >&2; exit 1; }
source "${JOLT_SDK_DIR:?set JOLT_SDK_DIR to an unpacked JoLT SDK}/env.sh"

cache="$root/build/sources"
work="$root/build/$name"
out="$root/out/abi$JOLT_ABI"
srcdir="$work/src"
pkgdir="$work/pkg"
jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN)}
export COPYFILE_DISABLE=1

depends=()
source "$recipe_dir/PKGBUILD"

rm -rf "$work"
mkdir -p "$srcdir" "$pkgdir" "$cache" "$out"

sha256() {
    shasum -a 256 "$1" | cut -d' ' -f1
}

for index in "${!source[@]}"; do
    entry=${source[index]}
    file=${entry%%::*}
    location=${entry#*::}
    [[ $entry == *::* ]] || file=${location##*/}
    if [[ $location == *://* ]]; then
        path="$cache/$file"
        if [[ ! -f $path ]]; then
            curl -fL --retry 3 -o "$path.partial" "$location"
            mv "$path.partial" "$path"
        fi
    else
        path="$recipe_dir/$location"
    fi
    actual=$(sha256 "$path")
    if [[ $actual != "${sha256sums[index]}" ]]; then
        printf 'makepkg: %s has sha256 %s\n' "$file" "$actual" >&2
        exit 1
    fi
    case $file in
        *.tar.gz|*.tgz|*.tar.xz|*.tar.bz2) tar -xf "$path" -C "$srcdir" ;;
        *) cp "$path" "$srcdir/$file" ;;
    esac
done

if declare -F build > /dev/null; then (cd "$srcdir" && build); fi
(cd "$srcdir" && package)

if [[ -n $(find "$pkgdir" -type l) ]]; then
    printf 'makepkg: JoLT has no symbolic links, use a wrapper script instead\n' >&2
    exit 1
fi

case $arch in
    jolt) pkgarch="jolt$JOLT_ABI" ;;
    any) pkgarch=any ;;
    *) printf 'makepkg: arch must be jolt or any\n' >&2; exit 1 ;;
esac

while IFS= read -r -d '' file; do
    if [[ $(head -c 4 "$file" | od -An -tx1 | tr -d ' \n') == 7f454c46 ]]; then
        [[ $arch == jolt ]] || { printf 'makepkg: %s is a program in an arch=any package\n' "$file" >&2; exit 1; }
        jolt_check_binary "$file"
        "$STRIP" "$file"
    fi
done < <(find "$pkgdir" -type f -print0)

size=$(find "$pkgdir" -type f -exec cat {} + | wc -c | tr -d ' ')
{
    printf 'pkgname = %s\n' "$pkgname"
    printf 'pkgver = %s-%s\n' "$pkgver" "$pkgrel"
    printf 'pkgdesc = %s\n' "$pkgdesc"
    printf 'url = %s\n' "$url"
    printf 'license = %s\n' "$license"
    printf 'arch = %s\n' "$pkgarch"
    printf 'size = %s\n' "$size"
    for dependency in ${depends[@]+"${depends[@]}"}; do printf 'depend = %s\n' "$dependency"; done
} > "$pkgdir/.PKGINFO"

filename="$pkgname-$pkgver-$pkgrel.pkg.tar.gz"
rm -f "$out/$pkgname"-[0-9]*.pkg.tar.gz
(cd "$pkgdir" && { echo .PKGINFO; find . ! -type d ! -name .PKGINFO | sed 's|^\./||' | LC_ALL=C sort; } > "$work/contents")
tar_flags=()
if tar --version 2>/dev/null | grep -q GNU; then
    tar_flags=(--mtime="@${SOURCE_DATE_EPOCH:-0}" --owner=0 --group=0 --numeric-owner)
fi
tar -cf - ${tar_flags[@]+"${tar_flags[@]}"} -C "$pkgdir" -T "$work/contents" | gzip -n -9 > "$out/$filename"
rm -f "$out/$pkgname"-[0-9]*.src.tar
if [[ $license == *GPL* ]]; then
    mkdir -p "$work/sources/$pkgname"
    cp -R "$recipe_dir/." "$work/sources/$pkgname/"
    for entry in "${source[@]}"; do
        location=${entry#*::}
        file=${entry%%::*}
        [[ $entry == *::* ]] || file=${location##*/}
        [[ $location == *://* ]] && cp "$cache/$file" "$work/sources/$pkgname/"
    done
    tar -cf "$out/$pkgname-$pkgver-$pkgrel.src.tar" ${tar_flags[@]+"${tar_flags[@]}"} -C "$work/sources" "$pkgname"
fi
printf 'makepkg: built %s\n' "$filename"
