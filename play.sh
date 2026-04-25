#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# This container has a read-only home, so point Godot user/cache dirs to /tmp.
export HOME=/tmp
export XDG_CACHE_HOME=/tmp/.cache
export XDG_DATA_HOME=/tmp/.local/share

exec godot --path . "$@"
