#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRODUCT_NAME="TimeMate"
APP_NAME="Time Mate"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
PLIST_SRC="$ROOT_DIR/AppBundle/Info.plist"

cd "$ROOT_DIR"

swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/$PRODUCT_NAME"

if [[ ! -f "$PLIST_SRC" ]]; then
  echo "Missing Info.plist at $PLIST_SRC" >&2
  exit 1
fi

if [[ ! -x "$BIN_PATH" ]]; then
  echo "Missing executable at $BIN_PATH" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$PLIST_SRC" "$APP_DIR/Contents/Info.plist"
install -m 755 "$BIN_PATH" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"

echo "Built $APP_DIR"
