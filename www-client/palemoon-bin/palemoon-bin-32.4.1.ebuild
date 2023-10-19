EAPI=6

inherit palemoon-bin-0 pax-utils desktop

KEYWORDS="-* amd64"
DESCRIPTION="Pale Moon Web Browser"
HOMEPAGE="https://www.palemoon.org/"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="gtk2 gtk3 startup-notification"
REQUIRED_USE="^^ ( gtk2 gtk3 )"

BIN_PN="${PN/-bin/}"
RESTRICT="strip mirror"
SRC_URI="
	gtk2? ( http://rm-us.palemoon.org/release/${BIN_PN}-${PV}.linux-x86_64-gtk2.tar.xz )
	gtk3? ( http://rm-us.palemoon.org/release/${BIN_PN}-${PV}.linux-x86_64-gtk3.tar.xz )
"

DEPEND="
	dev-util/patchelf
"

RDEPEND="
	dev-libs/atk
	>=sys-apps/dbus-0.60
	>=dev-libs/dbus-glib-0.60
	media-libs/alsa-lib
	media-libs/fontconfig
	>=media-libs/freetype-2.1.0
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	gtk2? ( >=x11-libs/gtk+-2.24:2 )
	gtk3? ( >=x11-libs/gtk+-3.22:3 )
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/pango
	virtual/freedesktop-icon-theme
	media-video/ffmpeg[x264]
"

QA_PREBUILT="
	opt/${BIN_PN}/*.so
	opt/${BIN_PN}/${BIN_PN}
	opt/${BIN_PN}/${PN}
	opt/${BIN_PN}/plugin-container
	opt/${BIN_PN}/mozilla-xremote-client
"

S="${WORKDIR}/${BIN_PN}"

src_unpack() {
	unpack ${A}
}

src_install() {
	declare PALEMOON_INSTDIR=/opt/${BIN_PN}

	local size sizes icon_path icon name
	sizes="16 32 48"
	icon_path="${S}/browser/chrome/icons/default"
	icon="${PN}"
	name="Pale Moon"

	# Install icons and .desktop for menu entry:
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png" || die
	done
	# The 128x128 icon has a different name:
	insinto /usr/share/icons/hicolor/128x128/apps
	newins "${icon_path}/../../../icons/mozicon128.png" "${icon}.png" || die
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs:
	newicon "${S}"/browser/chrome/icons/default/default48.png ${PN}.png
	domenu "${FILESDIR}"/icon/${PN}.desktop
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}usr/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317:
	if use startup-notification; then
		echo "StartupNotify=true" >> "${ED}"usr/share/applications/${PN}.desktop
	fi

	# Install palemoon in /opt:
	dodir ${PALEMOON_INSTDIR%/*}
	mv "${S}" "${ED}"${PALEMOON_INSTDIR} || die

	# Create /usr/bin/palemoon-bin:
	dodir /usr/bin/
	cat <<-EOF >"${ED}"usr/bin/${PN}
	#!/bin/sh
	GTK_PATH=/usr/lib/gtk-2.0/
	exec /opt/${BIN_PN}/${BIN_PN} "\$@"
	EOF
	fperms 0755 /usr/bin/${PN}

	# Mainly to prevent system's NSS/NSPR from taking precedence over
	# the built-in ones:
	for elf in $(scanelf -RBF "%F" "${ED}"${PALEMOON_INSTDIR}/*); do
		echo "Patching ELF ${elf}"
		patchelf --set-rpath "${PALEMOON_INSTDIR}" "${elf}"
	done

	# revdep-rebuild entry:
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=${PALEMOON_INSTDIR}" >> "${T}/10${PN}"
	doins "${T}"/10${PN} || die

	# Plugins dir:
	dosym "/usr/$(get_libdir)/nsbrowser/plugins" "${PALEMOON_INSTDIR}/browser/plugins"

	# Required in order to use plugins and even run palemoon on hardened:
	pax-mark mr "${ED}"${PALEMOON_INSTDIR}/{palemoon,palemoon-bin,plugin-container}
}
