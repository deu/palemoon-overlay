# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit check-reqs gnome2-utils fdo-mime toolchain-funcs

EXPORT_FUNCTIONS pkg_pretend pkg_preinst pkg_postinst pkg_postrm pkg_setup

palemoon-2_pkg_pretend() {
	# Ensure that we have enough disk space to compile:
	CHECKREQS_DISK_BUILD=${REQUIRED_BUILDSPACE}
	check-reqs_pkg_setup

	# Ensure that we are on a supported compiler profile:
	einfo "Checking compiler profile..."
	if [[ $PALEMOON_ENABLE_UNSUPPORTED_COMPILERS == 1 ]]; then
		unsupported_compiler_warning
	else
		if ! [[ tc-is-gcc && "$GCC_SUPPORTED_VERSIONS" =~ (^| )"$(gcc-version)"($| ) ]]; then
			unsupported_compiler_error $(tc-get-compiler-type)
			die
		fi
	fi
}

palemoon-2_pkg_preinst() {
	gnome2_icon_savelist
}

palemoon-2_pkg_postinst() {
	# Update mimedb for the new .desktop file:
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

palemoon-2_pkg_postrm() {
	gnome2_icon_cache_update
}

palemoon-2_pkg_setup() {
	# Nested configure scripts in mozilla products generate unrecognized
	# options false positives when toplevel configure passes downwards:
	export QA_CONFIGURE_OPTIONS=".*"
}

official-branding_warning() {
	elog "You are enabling the official branding. You may not redistribute this build"
	elog "to any users on your network or the internet. Doing so puts yourself into"
	elog "a legal problem with Moonchild Productions."
	elog "You can disable the official branding by emerging ${PN} _without_"
	elog "the official-branding USE flag."
}

unsupported_compiler_warning() {
	ewarn "Building Pale Moon with a compiler other than a supported gcc version"
	ewarn "may result in an unstable build."
	ewarn "Be aware that building Pale Moon with an unsupported compiler"
	ewarn "means that the official support channels may refuse to offer any"
	ewarn "kind of help in case the build fails or the browser behaves incorrectly."
	ewarn "Supported GCC versions: ${GCC_SUPPORTED_VERSIONS// /, }"
}

unsupported_compiler_error() {
	eerror "Building Pale Moon with a compiler other than a supported gcc version"
	eerror "may result in an unstable build."
	eerror "You can use gcc-config to change your compiler profile, just remember"
	eerror "to change it back afterwards."
	eerror "You need to have the appropriate versions of gcc installed for them"
	eerror "to be shown in gcc-config."
	eerror "Alternatively, you can set the PALEMOON_ENABLE_UNSUPPORTED_COMPILERS"
	eerror "environment variable to 1 either by exporting it from the current shell"
	eerror "or by adding it to your make.conf file."
	eerror "Be aware though that building Pale Moon with an unsupported compiler"
	eerror "means that the official support channels may refuse to offer any"
	eerror "kind of help in case the build fails or the browser behaves incorrectly."
	eerror "Supported GCC versions: ${GCC_SUPPORTED_VERSIONS// /, }"
	if [[ "$1" == "gcc" ]]; then
		eerror "Selected GCC version: $(gcc-version)"
	else
		eerror "Unsupported compiler selected: $1"
	fi
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
	PREFS_FILE="${S}/${obj_dir}/dist/bin/browser/defaults/preferences/palemoon.js"
	cat "${FILESDIR}"/default-prefs.js-1 >> $PREFS_FILE || die
}

set_pref() {
	echo "pref(\"$1\", \"$2\");" >> $PREFS_FILE
}
