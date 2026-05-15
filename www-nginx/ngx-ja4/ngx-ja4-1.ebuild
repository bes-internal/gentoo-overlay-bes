# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nginx-module

COMMIT="8e048f8b15864a678ebdfbe089b67d96b03b4e3c"

DESCRIPTION="NGINX module"
HOMEPAGE=""
SRC_URI="
 https://github.com/bes-internal/ja4-nginx-module/archive/${COMMIT}.zip -> ja4-nginx-module-${COMMIT}.zip
"

S="${WORKDIR}/ja4-nginx-module-${COMMIT}"


LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm64"

BDEPEND=""
DEPEND=""
RDEPEND="${DEPEND}"

