# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

REQUIRED_BUILDSPACE='7G'
GCC_SUPPORTED_VERSIONS="4.7 4.9"

inherit palemoon-4 git-r3 eutils flag-o-matic pax-utils

KEYWORDS="~x86 ~amd64"
DESCRIPTION="Pale Moon Web Browser"
HOMEPAGE="https://www.palemoon.org/"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="+official-branding
	+optimize cpu_flags_x86_sse cpu_flags_x86_sse2 threads debug
	-system-libevent -system-zlib -system-bzip2 -system-libwebp -system-libvpx
	-system-sqlite
	shared-js jemalloc -valgrind dbus -necko-wifi +gtk2 -gtk3 -webrtc
	alsa pulseaudio ffmpeg +devtools"

EGIT_REPO_URI="https://github.com/MoonchildProductions/Pale-Moon.git"
GIT_TAG="${PV}_Release"

RESTRICT="mirror"

DEPEND="
	>=sys-devel/autoconf-2.13:2.1
	dev-lang/python:2.7
	>=dev-lang/perl-5.6
	dev-lang/yasm"

RDEPEND="
	x11-libs/libXt
	app-arch/zip
	media-libs/freetype
	media-libs/fontconfig

	system-libevent? ( dev-libs/libevent )
	system-zlib?     ( sys-libs/zlib )
	system-bzip2?    ( app-arch/bzip2 )
	system-libwebp?  ( media-libs/libwebp )
	system-libvpx?   ( >=media-libs/libvpx-1.4.0 )
	system-sqlite?   ( >=dev-db/sqlite-3.19.3[secure-delete] )

	optimize? ( sys-libs/glibc )

	valgrind? ( dev-util/valgrind )

	shared-js? ( virtual/libffi )

	dbus? (
		>=sys-apps/dbus-0.60
		>=dev-libs/dbus-glib-0.60
	)

	gtk2? ( >=x11-libs/gtk+-2.18.0:2 )
	gtk3? ( >=x11-libs/gtk+-3.4.0:3 )

	alsa? ( media-libs/alsa-lib )
	pulseaudio? ( media-sound/pulseaudio )

	ffmpeg? ( virtual/ffmpeg[x264] )

	necko-wifi? ( net-wireless/wireless-tools )"

REQUIRED_USE="
	optimize? ( !debug )
	jemalloc? ( !valgrind )
	^^ ( gtk2 gtk3 )
	alsa? ( !pulseaudio )
	pulseaudio? ( !alsa )
	necko-wifi? ( dbus )"

src_unpack() {
	git-r3_fetch ${EGIT_REPO_URI} refs/tags/${GIT_TAG}
	git-r3_checkout
}

src_prepare() {
	# Ensure that our plugins dir is enabled by default:
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}/xpcom/io/nsAppFileLocationProvider.cpp" \
		|| die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}/xpcom/io/nsAppFileLocationProvider.cpp" \
		|| die "sed failed to replace plugin path for 64bit!"

	default
}

src_configure() {
	# Basic configuration:
	mozconfig_init

	mozconfig_disable installer updater install-strip

	if use official-branding; then
		official-branding_warning
		mozconfig_enable official-branding
	fi

	if use system-libevent; then mozconfig_with system-libevent; fi
	if use system-zlib;     then mozconfig_with system-zlib; fi
	if use system-bzip2;    then mozconfig_with system-bz2; fi
	if use system-libwebp;  then mozconfig_with system-webp; fi
	if use system-libvpx;   then mozconfig_with system-libvpx; fi
	if use system-sqlite;   then mozconfig_enable system-sqlite; fi

	if use optimize; then
		O='-O2'
		if use cpu_flags_x86_sse && use cpu_flags_x86_sse2; then
			O="${O} -msse2 -mfpmath=sse"
		fi
		mozconfig_enable "optimize=\"${O}\""
		filter-flags '-O*' '-msse2' '-mfpmath=sse'
	else
		mozconfig_disable optimize
	fi

	if use threads; then
		mozconfig_with pthreads
	fi

	if use debug; then
		mozconfig_var MOZ_DEBUG_SYMBOLS 1
		mozconfig_enable "debug-symbols=\"-gdwarf-2\""
	fi

	if use shared-js; then
		mozconfig_enable shared-js
	fi

	if use jemalloc; then
		mozconfig_enable jemalloc jemalloc-lib
	fi

	if use valgrind; then
		mozconfig_enable valgrind
	else
		mozconfig_disable valgrind
	fi

	if ! use dbus; then
		mozconfig_disable dbus
	fi

	if use gtk2; then
		mozconfig_enable default-toolkit=\"cairo-gtk2\"
	fi

	if use gtk3; then
		mozconfig_enable default-toolkit=\"cairo-gtk3\"
	fi

	if ! use necko-wifi; then
		mozconfig_disable necko-wifi
	fi

	if use webrtc; then
		mozconfig_enable webrtc
	else
		mozconfig_disable webrtc
	fi

	if   use alsa; then
		mozconfig_enable alsa
	fi

	if ! use pulseaudio; then
		mozconfig_disable pulseaudio
	fi

	if ! use ffmpeg; then
		mozconfig_disable ffmpeg
	fi

	if use devtools; then
		mozconfig_enable devtools
	fi

	# Mainly to prevent system's NSS/NSPR from taking precedence over
	# the built-in ones:
	append-ldflags -Wl,-rpath="$EPREFIX/usr/$(get_libdir)/palemoon"

	export MOZBUILD_STATE_PATH="${WORKDIR}/mach_state"
	mozconfig_var PYTHON $(which python2)
	mozconfig_var AUTOCONF $(which autoconf-2.13)
	mozconfig_var MOZ_MAKE_FLAGS "\"${MAKEOPTS}\""

	# Shorten obj dir to limit some errors linked to the path size hitting
	# a kernel limit (127 chars):
	mozconfig_var MOZ_OBJDIR "@TOPSRCDIR@/o"

	# Disable mach notifications, which also cause sandbox access violations:
	export MOZ_NOSPAM=1
}

src_compile() {
	python2 mach build || die
}

src_install() {
	# obj_dir changes depending on arch, compiler, etc:
	local obj_dir="$(echo */config.log)"
	obj_dir="${obj_dir%/*}"

	# Disable MPROTECT for startup cache creation:
	pax-mark m "${obj_dir}"/dist/bin/xpcshell

	# Set the backspace behaviour to be consistent with the other platforms:
	set_pref "browser.backspace_action" 0

	# Gotta create the package, unpack it and manually install the files
	# from there not to miss anything (e.g. the statusbar extension):
	einfo "Creating the package..."
	python2 mach package || die
	local extracted_dir="${T}/package"
	mkdir -p "${extracted_dir}"
	cd "${extracted_dir}"
	einfo "Extracting the package..."
	tar xjpf "${S}/${obj_dir}/dist/${P}.linux-${CTARGET_default%%-*}.tar.bz2"
	einfo "Installing the package..."
	local dest_libdir="/usr/$(get_libdir)"
	mkdir -p "${D}/${dest_libdir}"
	cp -rL "${PN}" "${D}/${dest_libdir}"
	dosym "${dest_libdir}/${PN}/${PN}" "/usr/bin/${PN}"
	einfo "Done installing the package."

	# Until JIT-less builds are supported,
	# also disable MPROTECT on the main executable:
	pax-mark m "${D}/${dest_libdir}/${PN}/"{palemoon,palemoon-bin,plugin-container}

	# Install icons and .desktop for menu entry:
	install_branding_files
}
