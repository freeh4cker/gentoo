# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PYTHON_COMPAT=( python3_{6,7} )
PYTHON_REQ_USE="ncurses?"

inherit desktop distutils-r1 xdg-utils

MY_P="Electrum-${PV}"
DESCRIPTION="User friendly Bitcoin client"
HOMEPAGE="https://electrum.org/"
SRC_URI="https://download.electrum.org/${PV}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
MY_LANGS="ar_SA be_BY bg_BG cs_CZ da_DK de_DE el_GR eo_UY es_ES fa_IR fr_FR hu_HU hy_AM id_ID it_IT ja_JP ko_KR ky_KG lv_LV nb_NO nl_NL pl_PL pt_BR pt_PT ro_RO ru_RU sk_SK sl_SI sv_SE ta_IN th_TH tr_TR uk_UA vi_VN zh_CN zh_TW"

my_langs_to_l10n() {
	# Map all except pt_* and zh_* to their generic codes
	case $1 in
		pt_*|zh_*) echo ${1/_/-} ;;
		*) echo ${1%%_*} ;;
	esac
}

IUSE="audio_modem cli coldcard cosign digitalbitbox email greenaddress_it ncurses qrcode +qt5 safe_t sync revealer trustedcoin_com vkb"

for lang in ${MY_LANGS}; do
	IUSE+=" l10n_$(my_langs_to_l10n ${lang})"
done
unset lang

REQUIRED_USE="
	|| ( cli ncurses qt5 )
	audio_modem? ( qt5 )
	cosign? ( qt5 )
	digitalbitbox? ( qt5 )
	email? ( qt5 )
	greenaddress_it? ( qt5 )
	qrcode? ( qt5 )
	sync? ( qt5 )
	trustedcoin_com? ( qt5 )
	vkb? ( qt5 )
"

RDEPEND="${PYTHON_DEPS}
	dev-python/aiohttp-socks[${PYTHON_USEDEP}]
	~dev-python/aiorpcX-0.17.0[${PYTHON_USEDEP}]
	dev-python/dnspython[${PYTHON_USEDEP}]
	dev-python/ecdsa[${PYTHON_USEDEP}]
	dev-python/jsonrpclib[${PYTHON_USEDEP}]
	dev-python/pbkdf2[${PYTHON_USEDEP}]
	dev-python/pyaes[${PYTHON_USEDEP}]
	dev-python/PySocks[${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/protobuf-python[${PYTHON_USEDEP}]
	qrcode? ( media-gfx/zbar[v4l] )
	qt5? (
		dev-python/PyQt5[gui,widgets,${PYTHON_USEDEP}]
	)
	ncurses? ( dev-lang/python )
"

S="${WORKDIR}/${MY_P}"

DOCS="RELEASE-NOTES"

src_prepare() {
	eapply "${FILESDIR}/3.1.2-no-user-root.patch"
	eapply "${FILESDIR}/3.2.3-pip-optional-pkgs.patch"
	eapply "${FILESDIR}/3.3.2-desktop.patch"

	# Prevent icon from being installed in the wrong location
	sed -i '/icons_dirname/d' setup.py || die

	# Remove unrequested localization files:
	local lang
	for lang in ${MY_LANGS}; do
		use l10n_$(my_langs_to_l10n ${lang}) && continue
		rm -r "${PN}/locale/${lang}" || die
	done

	local wordlist=
	for wordlist in  \
		$(usex l10n_ja    '' japanese) \
		$(usex l10n_pt-BR '' $(usex l10n_pt-PT '' portuguese)) \
		$(usex l10n_es    '' spanish) \
		$(usex l10n_zh-CN '' chinese_simplified) \
	; do
		rm -f "${PN}/wordlist/${wordlist}.txt" || die
		sed -i "/${wordlist}\\.txt/d" ${PN}/mnemonic.py || die
	done

	# Remove unrequested GUI implementations:
	local gui setup_py_gui
	for gui in  \
		$(usex cli      '' stdio)  \
		kivy \
		$(usex qt5      '' qt   )  \
		$(usex ncurses  '' text )  \
	; do
		rm ${PN}/gui/"${gui}"* -r || die
	done

	# And install requested ones...
	for gui in  \
		$(usex !qt5     qt   '')  \
	; do
		sed -i -e "/electrum\.gui\.${gui}/d" setup.py || die
	done

	local bestgui
	if use qt5; then
		bestgui=qt
	elif use ncurses; then
		bestgui=text
	else
		bestgui=stdio
	fi
	sed -i 's/^\([[:space:]]*\)\(config_options\['\''cwd'\''\] = .*\)$/\1\2\n\1config_options.setdefault("gui", "'"${bestgui}"'")\n/' ${PN}/${PN} || die

	local plugin
	# trezor requires python trezorlib module
	# keepkey requires trezor
	for plugin in  \
		$(usex audio_modem     '' audio_modem          ) \
		$(usex coldcard        '' coldcard             ) \
		$(usex cosign          '' cosigner_pool        ) \
		$(usex digitalbitbox   '' digitalbitbox        ) \
		$(usex email           '' email_requests       ) \
		$(usex greenaddress_it '' greenaddress_instant ) \
		hw_wallet \
		ledger \
		keepkey \
		$(usex safe_t          '' safe_t               ) \
		$(usex sync            '' labels               ) \
		$(usex revealer        '' revealer             ) \
		trezor  \
		$(usex trustedcoin_com '' trustedcoin          ) \
		$(usex vkb             '' virtualkeyboard      ) \
	; do
		rm -r ${PN}/plugins/"${plugin}"* || die
		sed -i "/${plugin}/d" setup.py || die
	done

	eapply_user

	xdg_environment_reset
	distutils-r1_src_prepare
}

src_install() {
	doicon -s 128 electrum/gui/icons/${PN}.png
	distutils-r1_src_install
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}
