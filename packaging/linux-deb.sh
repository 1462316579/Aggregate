#!/usr/bin/env bash
set -euo pipefail

APP_NAME='hongxi'
DISPLAY_NAME='宏曦聚合'
VERSION='1.0.0'
ARCH='amd64'
ROOT="$PWD/build/linux/x64/release/bundle"
PKG="$PWD/build/linux/hongxi-deb"

rm -rf "$PKG"
mkdir -p "$PKG/DEBIAN" "$PKG/opt/$APP_NAME" "$PKG/usr/share/applications"
cp -a "$ROOT/." "$PKG/opt/$APP_NAME/"

cat > "$PKG/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: video
Priority: optional
Architecture: $ARCH
Maintainer: HongXi
Description: $DISPLAY_NAME
EOF

cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/sh
chmod +x /opt/hongxi/app2026 2>/dev/null || true
EOF
chmod 0755 "$PKG/DEBIAN/postinst"

cat > "$PKG/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Comment=多媒体聚合应用
Exec=/opt/$APP_NAME/app2026
Icon=application-x-executable
Terminal=false
Type=Application
Categories=AudioVideo;
EOF

mkdir -p build/release
fakeroot dpkg-deb --build "$PKG" "build/release/hongxi-linux-x64.deb"
