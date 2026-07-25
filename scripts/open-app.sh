#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/Time Mate.app"

if [[ ! -d "$APP_PATH" ]]; then
  "$SCRIPT_DIR/build-app.sh"
fi

open "$APP_PATH"
