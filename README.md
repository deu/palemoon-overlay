# Unofficial Pale Moon Gentoo Overlay

To add it to your layman overlays:

```
# cat > /etc/layman/overlays/palemoon.xml << EOF
<?xml version="1.0" ?>
<repositories version="1.0">
    <repo quality="experimental" status="unofficial">
        <name>palemoon</name>
        <description>Unofficial Gentoo overlay for the Pale Moon (http://www.palemoon.org/) web browser.</description>
        <homepage>https://gitlab.com/deu/palemoon-overlay</homepage>
        <owner type="person">
            <email>de@uio.re</email>
            <name>deu</name>
        </owner>
        <source type="git">https://gitlab.com/deu/palemoon-overlay.git</source>
    </repo>
</repositories>
EOF
```
