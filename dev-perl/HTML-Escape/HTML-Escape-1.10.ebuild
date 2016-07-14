# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# This ebuild generated by g-cpan 0.16.5

EAPI=5

MODULE_AUTHOR="TOKUHIROM"
MODULE_VERSION="${PV}"


inherit perl-module

DESCRIPTION="Extremely fast HTML escaping"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND="dev-perl/Test-Requires
	>=dev-perl/Module-Build-Pluggable-PPPort-0.04
	dev-lang/perl"
