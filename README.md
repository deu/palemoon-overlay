This is an awkward fork of:

https://github.com/deuiore/palemoon-overlay

Pls. use with caution! No warranties of any kind! You have been warned! ;-)

However, I was able to use these ebuilds to install various versions of Pale-Moon.git overlay at:

https://github.com/MoonchildProductions/Pale-Moon.git

from even the very latest of the tags/commits at that git repo above!

This very repo, heavily modified (not much in either though) from deu's repo, (this one) is not an overlay per se. Some ideas I hope might be used in the original repo though...

But this one is not an overlay per se. Rather, I deploy it in my /usr/local/portage/ instead.

Go and read the Local_Overlay on Gentoo wiki, if you don't know how to deploy it:

https://wiki.gentoo.org/wiki/Overlay/Local_overlay

The above is the prerequisite knowledge.

Old versions of palemoon and palemoon-bin are there but are unmodified, and I didn't try compiling any of them. No time. Forget about them in this repo.

If you want to try your luck using this (just remember that I'm not familiar yet with Palemoon development, and if I don't update this at least every couple of days, it probably won't work without modifications, any of this; currently it works for me, and in works in my Air-Gapped, from my local Cgit-on-Apache served git sources that I cloned from the above Pale-Moon.git)...

If you want to try this, first clone this repo:

git clone https://github.com/miroR/palemoon-overlay

Then from that local cloned git repo of yours copy the contents of:

/where-you-cloned-it/palemoon-overlay/eclass/

to:

/usr/local/portage/eclass/

Then copy the contents of:

/where-you-cloned-it/palemoon-overlay/www-client/palemoon/

to:

/usr/local/portage/www-client/palemoon/

And now issue:

# emerge -tuDN palemoon

and the compilation should start.

If I don't modify this README.md today, I successfully (re)tried the above procedure and it works (or I couldn't modify it because something prevented me from doing it). The non-parenthesized event it more likely.

The below is the original content of this README.md, unmodified in any way.

# Unofficial Pale Moon Gentoo Overlay

To add it to your layman overlays: `# layman -a palemoon`

<sub>**Note:** If you are coming from the [old repository](https://gitlab.com/deu/palemoon-overlay) be sure to delete `/etc/layman/overlays/palemoon.xml` before adding the new one.</sub>
