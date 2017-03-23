# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit palemoon-bin-0 eutils pax-utils fdo-mime gnome2-utils

KEYWORDS="~x86 ~amd64"
DESCRIPTION="Pale Moon Web Browser"
HOMEPAGE="https://www.palemoon.org/"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="startup-notification"

MOZ_PN="${PN/-bin/}"
RESTRICT="strip mirror"
SRC_URI="
	amd64? ( https://linux.palemoon.org/files/${PV}/${MOZ_PN}-${PV}.en-US.linux-x86_64.tar.bz2 )
	x86? ( https://linux.palemoon.org/files/${PV}/${MOZ_PN}-${PV}.en-US.linux-i686.tar.bz2 )"
RESTRICT="mirror"

RDEPEND="
	dev-libs/atk
	>=sys-apps/dbus-0.60
	>=dev-libs/dbus-glib-0.60
	media-libs/alsa-lib
	media-libs/fontconfig
	>=media-libs/freetype-2.1.0
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	>=x11-libs/gtk+-2.10:2
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/pango
	virtual/freedesktop-icon-theme
	virtual/ffmpeg[x264]
"

QA_PREBUILT="
	opt/${MOZ_PN}/*.so
	opt/${MOZ_PN}/${MOZ_PN}
	opt/${MOZ_PN}/${PN}
	opt/${MOZ_PN}/plugin-container
	opt/${MOZ_PN}/mozilla-xremote-client
"

S="${WORKDIR}/${MOZ_PN}"

src_unpack() {
	unpack ${A}
}

src_install() {
	declare MOZILLA_FIVE_HOME=/opt/${MOZ_PN}

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
	dodir ${MOZILLA_FIVE_HOME%/*}
	mv "${S}" "${ED}"${MOZILLA_FIVE_HOME} || die

	# Create /usr/bin/palemoon-bin:
	dodir /usr/bin/
	cat <<-EOF >"${ED}"usr/bin/${PN}
	#!/bin/sh
	GTK_PATH=/usr/lib/gtk-2.0/
	exec /opt/${MOZ_PN}/${MOZ_PN} "\$@"
	EOF
	fperms 0755 /usr/bin/${PN}

	# Mainly to prevent system's NSS/NSPR from taking precedence over
	# the built-in ones:
	for elf in $(scanelf -RBF "%F" "${ED}"${MOZILLA_FIVE_HOME}/*); do
		echo "Patching ELF ${elf}"
		patchelf --set-rpath "${MOZILLA_FIVE_HOME}" "${elf}"
	done

	# revdep-rebuild entry:
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=${MOZILLA_FIVE_HOME}" >> ${T}/10${PN}
	doins "${T}"/10${PN} || die

	# Plugins dir:
	dosym "/usr/$(get_libdir)/nsbrowser/plugins" "${MOZILLA_FIVE_HOME}/browser/plugins"

	# Required in order to use plugins and even run palemoon on hardened:
	pax-mark mr "${ED}"${MOZILLA_FIVE_HOME}/{palemoon,palemoon-bin,plugin-container}
}
