# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# These must be bumped together:
# - media-libs/libzen (if a release is available)
# - media-libs/libmediainfo
# - media-video/mediainfo

WX_GTK_VER="3.2-gtk3"
inherit xdg-utils autotools qmake-utils wxwidgets

DESCRIPTION="MediaInfo supplies technical and tag information about media files"
HOMEPAGE="https://mediaarea.net/en/mediainfo/ https://github.com/MediaArea/MediaInfo"
SRC_URI="https://mediaarea.net/download/source/${PN}/${PV}/${P/-/_}.tar.xz"
S="${WORKDIR}/MediaInfo"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc ~ppc64 ~riscv ~x86"
IUSE="curl mms qt6 wxwidgets"
REQUIRED_USE="?? ( qt6 wxwidgets )"

# The libzen dep usually needs to be bumped for each release!
RDEPEND="
	~media-libs/libmediainfo-${PV}[curl=,mms=]
	>=media-libs/libzen-0.4.41
	virtual/zlib:=
	qt6? ( dev-qt/qtbase:6[gui,network,widgets,xml] )
	wxwidgets? ( x11-libs/wxGTK:${WX_GTK_VER}=[X] )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	qt6? ( dev-qt/qttools:6 )
"

pkg_setup() {
	if use wxwidgets; then
		setup-wxwidgets
	fi
}

src_prepare() {
	default

	cd "${S}"/Project/GNU/CLI || die
	sed -i -e "s:-O2::" configure.ac || die
	eautoreconf

	if use qt6 || use wxwidgets; then
		cd "${S}"/Project/GNU/GUI || die
		sed -i -e "s:-O2::" configure.ac || die
		eautoreconf
	fi

	if use qt6; then
		sed \
			-e "s:lupdate:$(qt6_get_bindir)/lupdate:" \
			-e "s:lrelease:$(qt6_get_bindir)/lrelease:" \
			-i "${S}"/Source/GUI/Qt/Qt_Translations_Updater/update_Qt_translations.sh || die
	fi
}

src_configure() {
	cd "${S}"/Project/GNU/CLI || die
	econf

	if use qt6; then
		cd "${S}"/Project/GNU/GUI || die
		with_wx=no econf --with-wxwidgets=no --with-wx-gui=no
		cd "${S}"/Project/QMake/GUI || die
		eqmake6
	fi

	if use wxwidgets; then
		cd "${S}"/Project/GNU/GUI || die
		econf --with-wxwidgets --with-wx-gui
	fi
}

src_compile() {
	cd "${S}"/Project/GNU/CLI || die
	default

	if use qt6; then
		cd "${S}"/Project/QMake/GUI || die
		default
	fi

	if use wxwidgets; then
		cd "${S}"/Project/GNU/GUI || die
		default
	fi
}

src_install() {
	cd "${S}"/Project/GNU/CLI || die
	default

	if use qt6; then
		cd "${S}"/Project/GNU/GUI || die
		emake DESTDIR="${D}" install-data
		cd "${S}"/Project/QMake/GUI || die
		emake INSTALL_ROOT="${D}" install
	fi

	if use wxwidgets; then
		cd "${S}"/Project/GNU/GUI || die
		default
	fi

	dodoc "${S}"/History_CLI.txt
	if use qt6 || use wxwidgets; then
		dodoc "${S}"/History_GUI.txt
	fi
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}
