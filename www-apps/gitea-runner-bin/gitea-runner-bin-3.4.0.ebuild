# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Gitea Actions runner binary"
HOMEPAGE="https://gitea.com/gitea/runner/"

SRC_URI="
	amd64? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-amd64.xz -> ${P}-linux-amd64.xz )
	arm? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-arm-7.xz -> ${P}-linux-arm-7.xz )
	arm64? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-arm64.xz -> ${P}-linux-arm64.xz )
	loong? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-loong64.xz -> ${P}-linux-loong64.xz )
	riscv? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-riscv64.xz -> ${P}-linux-riscv64.xz )
	s390? ( https://gitea.com/gitea/runner/releases/download/v${PV}/gitea-runner-${PV}-linux-s390x.xz -> ${P}-linux-s390x.xz )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm arm64 loong riscv s390"
IUSE=""

RDEPEND="
	app-containers/docker
"

S="${WORKDIR}"

RESTRICT="strip"

QA_PREBUILT="usr/bin/gitea-runner"

src_install() {

	case ${ARCH} in
		amd64) arch_suffix="linux-amd64" ;;
		arm)   arch_suffix="linux-arm-5" ;;
		arm64) arch_suffix="linux-arm64" ;;
		loong) arch_suffix="linux-loong64" ;;
		riscv) arch_suffix="linux-riscv64" ;;
		s390)  arch_suffix="linux-s390x" ;;
		*) die "Unsupported architecture: ${ARCH}" ;;
	esac

	exeinto /usr/bin
	newexe "gitea-runner-bin-${PV}-${arch_suffix}" gitea-runner

	newinitd "${FILESDIR}/gitea-runner.initd" gitea-runner

	newconfd "${FILESDIR}/gitea-runner.confd" gitea-runner

	keepdir /var/lib/gitea
	keepdir /var/log/gitea-runner
	keepdir /etc/gitea
}

pkg_postinst() {
	elog "To start the runner:"
	elog "  Register: sudo -u git gitea-runner register"
        elog "  Create config: gitea-runner generate-config > /etc/gitea/gitea-runner-config.yaml"
	elog "  Start: rc-service gitea-runner start"
	elog ""
	elog "Make sure the 'git' user exists and has access to Docker socket."
}
