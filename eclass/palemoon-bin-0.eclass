# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit gnome2-utils fdo-mime

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	# Update mimedb for the new .desktop file:
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
