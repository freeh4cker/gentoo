# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGO_VENDOR=( "github.com/mitchellh/iochan 87b45ffd0e9581375c491fef3d32130bb15c5bd7" )
inherit golang-build golang-vcs-snapshot

EGO_PN="github.com/mitchellh/gox"
ARCHIVE_URI="https://${EGO_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${EGO_VENDOR_URI}"
KEYWORDS="~amd64"

DESCRIPTION="A dead simple, no frills Go cross compile tool"
HOMEPAGE="https://github.com/mitchellh/gox"
SRC_URI="${ARCHIVE_URI}"
LICENSE="MPL-2.0"
SLOT="0/${PVR}"
IUSE=""

RESTRICT="test"

src_install() {
	dobin ${PN}
	dodoc src/${EGO_PN}/README.md
}
