#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
./scripts/check-version.sh

godot --headless --editor --path game --quit
godot --headless --path game --quit-after 2
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
