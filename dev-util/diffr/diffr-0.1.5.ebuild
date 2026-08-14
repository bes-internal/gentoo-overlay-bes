# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo

DESCRIPTION="Diff tool with colorized word-level highlighting inside changed lines"
HOMEPAGE="https://github.com/mookid/diffr"

SRC_URI="https://github.com/mookid/diffr/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64"

# Добавляем termion и её зависимости
CRATES="
   atty-0.2.11
    bstr-1.12.1
    libc-0.2.58
    memchr-2.7.6
    numtoa-0.1.0
    redox_syscall-0.1.54
    redox_termios-0.1.1
    regex-automata-0.4.13
    termcolor-1.1.0
    termion-1.5.3
    winapi-0.3.7
    winapi-i686-pc-windows-gnu-0.4.0
    winapi-x86_64-pc-windows-gnu-0.4.0
    winapi-util-0.1.3
    windows-sys-0.61.2
    windows-link-0.2.1
"

SRC_URI+=" $(cargo_crate_uris ${CRATES})"

src_unpack() {
    cargo_src_unpack
}

src_compile() {
    cargo_src_compile
}

src_install() {
    cargo_src_install
}
