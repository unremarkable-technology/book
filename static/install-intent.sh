#!/usr/bin/env sh
set -e

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64) ASSET="intent-linux-x64.tar.gz" ;;
      *) echo "Unsupported Linux arch: $ARCH"; exit 1 ;;
    esac
    ;;
  Darwin)
    case "$ARCH" in
      x86_64) ASSET="intent-darwin-x64.tar.gz" ;;
      arm64)  ASSET="intent-darwin-arm64.tar.gz" ;;
      *) echo "Unsupported macOS arch: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

URL="https://github.com/unremarkable-technology/tooling/releases/latest/download/$ASSET"

curl -fsSL "$URL" | tar -xz
chmod +x intent
mv intent "$HOME/.local/bin/intent"

echo "Installed intent to ~/.local/bin"
echo "Ensure ~/.local/bin is on your PATH"