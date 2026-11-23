# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="REST server for restic backups (upstream binary release)"
HOMEPAGE="https://github.com/restic/rest-server"
SRC_URI="
	amd64? ( https://github.com/restic/rest-server/releases/download/v${PV}/rest-server_${PV}_linux_amd64.tar.gz -> ${P}-linux-amd64.tar.gz )
	arm64? ( https://github.com/restic/rest-server/releases/download/v${PV}/rest-server_${PV}_linux_arm64.tar.gz -> ${P}-linux-arm64.tar.gz )
"
S="${WORKDIR}"

LICENSE="BSD-2 Apache-2.0 BSD MIT MPL-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

RESTRICT="strip"
QA_PREBUILT="usr/bin/rest-server"

src_install() {
	local dir
	case ${ARCH} in
		amd64) dir="rest-server_${PV}_linux_amd64" ;;
		arm64) dir="rest-server_${PV}_linux_arm64" ;;
		*) die "Unsupported architecture: ${ARCH}" ;;
	esac

	dobin "${dir}"/rest-server
	dodoc "${dir}"/{README,CHANGELOG}.md

	newinitd "${FILESDIR}"/restic-rest-server.initd restic-rest-server
	newconfd "${FILESDIR}"/restic-rest-server.confd restic-rest-server
	systemd_newunit "${FILESDIR}"/restic-rest-server.service restic-rest-server.service

	keepdir /var/lib/restic-rest-server
}
