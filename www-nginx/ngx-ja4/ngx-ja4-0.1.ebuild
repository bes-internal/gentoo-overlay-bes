# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nginx-module

DESCRIPTION="JA4 TLS fingerprinting module for NGINX"
HOMEPAGE="https://github.com/bes-internal/ja4-nginx-module"
SRC_URI="https://github.com/bes-internal/ja4-nginx-module/archive/v0.1.tar.gz"

S="${WORKDIR}/ja4-nginx-module-0.1"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm64"

BDEPEND=""
DEPEND=""
RDEPEND="${DEPEND}"

