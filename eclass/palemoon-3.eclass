# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit check-reqs gnome2-utils fdo-mime toolchain-funcs

EXPORT_FUNCTIONS pkg_pretend pkg_preinst pkg_postinst pkg_postrm pkg_setup


###
# Package
###

palemoon-3_pkg_pretend() {
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

palemoon-3_pkg_preinst() {
	gnome2_icon_savelist
}

palemoon-3_pkg_postinst() {
	# Update mimedb for the new .desktop file:
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

palemoon-3_pkg_postrm() {
	gnome2_icon_cache_update
}

palemoon-3_pkg_setup() {
	# Nested configure scripts in mozilla products generate unrecognized
	# options false positives when toplevel configure passes downwards:
	export QA_CONFIGURE_OPTIONS=".*"
}


###
# Messages
###

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


###
# Configuration
###

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


###
# Localization
###

# Add LINGUAS USE flags:
for lang in ${L10N_LANGUAGES}; do
	IUSE+=" linguas_${lang/-/_}"
done

l10n_repo_name=${L10N_REPO_URI##*/}
l10n_repo_path="${PORTAGE_ACTUAL_DISTDIR}/${l10n_repo_name}"
l10n_dir=${l10n_repo_name%.*}

l10n_get() {
	pushd "${PORTAGE_ACTUAL_DISTDIR}"
	if [[ -d "${l10n_repo_path}" ]]; then
		einfo "Updating localization repository..."
		addwrite "${l10n_repo_path}"
		cd ${l10n_repo_path}
		git fetch ${L10N_REPO_URI} +refs/heads/*:refs/heads/* --prune
	else
		einfo "Cloning localization repository..."
		addwrite "${PORTAGE_ACTUAL_DISTDIR}"
		git clone --bare ${L10N_REPO_URI}
	fi
	popd

	# Clone the localization repository into the work dir:
	pushd "${WORKDIR}"
	git clone "${l10n_repo_path}"
	cd ${l10n_dir}
	git checkout --detach ${L10N_COMMIT}
	popd
}

l10n_install() {
	einfo "Installing language packs..."
	pushd "${WORKDIR}/${l10n_dir}"
	#MAX_PV=$(echo ${PV} | cut -d. -f1,2).*

	for lingua in ${LINGUAS}; do
		lang=${lingua//_/-}

		if [[ "en en-US" =~ (^| )"${lang}"($| ) ]]; then
			# en and en-US are handled internally.
			continue
		elif [[ "${L10N_LANGUAGES}" =~ (^| )"${lang}"($| ) ]]; then
			einfo "Installing language pack \"${lang}\"..."
			pushd ${lang}

			# Not needed for now since we're always pulling commits where
			# it's already been run, but having it ready just in case:
			#sed -i -e "s/em:version=\"[a-zA-Z0-9_.]\+\"/em:version=\"${PV}\"/g" install.rdf
			#sed -i -e "s/maxVersion>[a-zA-Z0-9_.\*]\+</maxVersion>${MAX_PV}</g" install.rdf

			mv browser/chrome/AB-CD browser/chrome/${lang}
			mv chrome/AB-CD/locale/AB-CD chrome/AB-CD/locale/${lang}
			mv chrome/AB-CD chrome/${lang}

			emid="$(sed -n -e '/install-manifest/,$ { /em:id/!d; s/.*[\">]\([^\"<>]*\)[\"<].*/\1/; p; q }' install.rdf)"
			insinto ${dest_libdir}/${PN}/browser/extensions/${emid}
			doins -r *

			popd
		fi
	done
	popd
}


###
# Branding
###

install_branding_files() {
	cp -rL "${S}/${obj_dir}/dist/branding" "${extracted_dir}/"
	local size sizes icon_path icon name
	sizes="16 32 48"
	icon_path="${extracted_dir}/branding"
	icon="${PN}"
	name="Pale Moon"
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# The 128x128 icon has a different name:
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/mozicon128.png" "${icon}.png"
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs:
	newicon "${icon_path}/default48.png" "${icon}.png"
	newmenu "${FILESDIR}/icon/${PN}.desktop" "${PN}.desktop"
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}/usr/share/applications/${PN}.desktop" || die
}
