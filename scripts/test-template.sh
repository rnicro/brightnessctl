#!/bin/sh
set -eu

template="srcpkgs/brightnessctl/template"
[ -s "$template" ] || {
    echo "Missing package template: $template" >&2
    exit 1
}

grep -Eq '^pkgname=brightnessctl$' "$template"
grep -Eq '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$template"
grep -Eq '^revision=[0-9]+$' "$template"
grep -Fq 'build_style=gnu-makefile' "$template"
grep -Fq 'make_use_env=yes' "$template"
grep -Fq 'make_install_args="UDEVDIR=/usr/lib/udev/rules.d"' "$template"
grep -Fq 'hostmakedepends="pkg-config"' "$template"
grep -Fq 'archs="x86_64-musl"' "$template"
grep -Fq 'CFLAGS+=" -march=skylake -mtune=skylake"' "$template"
grep -Fq 'https://github.com/Hummer12007/brightnessctl/archive/${version}.tar.gz' "$template"
grep -Fq 'license="MIT"' "$template"
grep -Fq 'vlicense LICENSE' "$template"

checksum="$(sed -n 's/^checksum=//p' "$template")"
[ "$(printf '%s' "$checksum" | wc -c | tr -d ' ')" -eq 64 ] || {
    echo "Expected a 64-character source SHA-256 checksum." >&2
    exit 1
}
case "$checksum" in
    *[!0-9a-f]*|'')
        echo "Source checksum must be lowercase hexadecimal." >&2
        exit 1
        ;;
esac

version="$(sed -n 's/^version=//p' "$template")"
revision="$(sed -n 's/^revision=//p' "$template")"
[ -n "$version" ] && [ -n "$revision" ]

if grep -Eq '^(archs|hostmakedepends)=.*(x86_64$|glibc|aarch64)' "$template"; then
    echo "Unexpected target or dependency expansion in the package template." >&2
    exit 1
fi

echo "brightnessctl x86_64-musl / Skylake package checks passed"
