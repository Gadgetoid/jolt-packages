# JoLT packages

Extra programs and data for [JoLT](https://github.com/Gadgetoid/jolt), installed on the device with `jpm`:

```sh
jpm update
jpm list
jpm install sacc
```

| Package | |
| --- | --- |
| `sacc` | Gopher client |
| `lrzsz` | ZMODEM file transfer: `sz` and `rz`, for use with `jolt serial-shell` |
| `antiword` | Read Microsoft Word documents as text |
| `font-cozette` | Cozette 6x13 bitmap font |

The package format is described in JoLT's [docs/packages.md](https://github.com/Gadgetoid/jolt/blob/main/docs/packages.md). Every push to `main` publishes to https://gadgetoid.github.io/jolt-packages/, which `jpm` reads.

## Adding a package

Each package is a directory under `packages/` with a `PKGBUILD`, in the style of Arch Linux:

```bash
pkgname=hello
pkgver=1.0
pkgrel=1
pkgdesc="One line description"
url="https://example.com/hello"
license=MIT
arch=jolt
source=("https://example.com/hello-$pkgver.tar.gz")
sha256sums=(...)

build() {
    cd "hello-$pkgver"
    make CC="$CC"
}

package() {
    mkdir -p "$pkgdir/usr/bin"
    cp "hello-$pkgver/hello" "$pkgdir/usr/bin/"
}
```

- `arch=jolt` for programs, `arch=any` for data such as fonts and themes.
- `source` entries can be `name::url` to rename a download, or a file in the package's directory, such as a patch.
- `build()` and `package()` run in the directory the sources were unpacked into. `$CC`, `$AR`, `$RANLIB`, `$STRIP`, `$JOLT_SDK` and `$jobs` are set.
- Programs are static. ncurses (narrow), LibreSSL and Mbed TLS are in the SDK.
- There are no symbolic links on JoLT, so use a small wrapper script instead.
- Programs are checked for instructions the Jornada's StrongARM lacks and stripped.
- Bump `pkgrel` when the recipe changes but the upstream version doesn't.

## Building

Needs the [Windows CE LLVM](https://github.com/Gadgetoid/velo-llvm-builds), a JoLT SDK from a [JoLT release](https://github.com/Gadgetoid/jolt/releases), bash, curl and Node.js (for fonts).

```sh
export JORNADA_LLVM_ROOT=/path/to/velo-llvm
export JOLT_SDK_DIR=/path/to/jolt-sdk-VERSION
tools/build.sh            # every package
tools/build.sh sacc       # just one
```

Packages and `index` are written to `out/abi2/`. To try them on a device, copy `out` to `JoLT\root\tmp\repo` on the card and run `JPM_REPO=/tmp/repo jpm update`, or serve `out` over HTTP.

GPL packages also get a `NAME-VERSION-REL.src.tar` with their sources and recipe, published alongside the package.

## Licence

The recipes and tools are MIT licensed. Each package keeps its upstream licence, given in its `PKGBUILD`.
