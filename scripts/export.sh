#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
./scripts/check-version.sh

version="$(godot --version | sed 's/\.stable.*//')"
versioned_dir="builds/${version}"
current_dir="builds/current"
executable_name="Game.exe"
mkdir -p "$versioned_dir" "$current_dir"

godot --headless --path game --export-debug "Windows Desktop" "../${versioned_dir}/${executable_name}"
cp "${versioned_dir}/${executable_name}" "${current_dir}/${executable_name}"
printf 'Exported Windows build to %s\n' "${current_dir}/${executable_name}"
