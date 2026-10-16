#!/usr/bin/env bash
set -euo pipefail

directory=$1
index="$directory/index"
: > "$index.new"
for package in "$directory"/*.pkg.tar.gz; do
    [[ -f $package ]] || continue
    [[ -s $index.new ]] && printf '\n' >> "$index.new"
    tar -xzOf "$package" .PKGINFO >> "$index.new"
    printf 'filename = %s\n' "${package##*/}" >> "$index.new"
    printf 'csize = %s\n' "$(wc -c < "$package" | tr -d ' ')" >> "$index.new"
    printf 'sha256 = %s\n' "$(shasum -a 256 "$package" | cut -d' ' -f1)" >> "$index.new"
done
mv "$index.new" "$index"
printf 'index: %s packages\n' "$(grep -c '^pkgname = ' "$index")"
