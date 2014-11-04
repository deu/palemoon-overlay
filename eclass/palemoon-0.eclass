# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit check-reqs gnome2-utils fdo-mime

pkg_pretend() {
	# Ensure we have enough disk space to compile
	CHECKREQS_DISK_BUILD=${REQUIRED_BUILDSPACE}
	check-reqs_pkg_setup
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}

pkg_setup() {
	# Nested configure scripts in mozilla products generate unrecognized
	# options false positives when toplevel configure passes downwards:
	export QA_CONFIGURE_OPTIONS=".*"
}

official-branding_warning() {
	elog "You are enabling official branding. You may not redistribute this build"
	elog "to any users on your network or the internet. Doing so puts yourself into"
	elog "a legal problem with Moonchild Productions"
	elog "You can disable it by emerging ${PN} _without_ the official-branding USE-flag"
}

mozconfig_init() {
	cp -L "${S}/browser/config/mozconfig" "${S}/.mozconfig" || die
}

mozconfig_enable() {
	for option in "$@"; do
		echo "ac_add_options --enable-${option}" >> "${S}/.mozconfig"
	done
}

mozconfig_disable() {
	for option in "$@"; do
		echo "ac_add_options --disable-${option}" >> "${S}/.mozconfig"
	done
}

mozconfig_with() {
	for option in "$@"; do
		echo "ac_add_options --with-${option}" >> "${S}/.mozconfig"
	done
}

mozconfig_var() {
	echo "mk_add_options $1=\"$2\"" >> "${S}/.mozconfig"
}

load_default_prefs() {
	PREFS_FILE="${S}/${obj_dir}/dist/bin/browser/defaults/preferences/firefox.js"
	cat "${FILESDIR}"/default-prefs.js-0 >> $PREFS_FILE || die
}

set_pref() {
	echo "pref(\"$1\", \"$2\");" >> $PREFS_FILE
}
