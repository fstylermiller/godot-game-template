#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
./scripts/check-version.sh

find game -type f -name '*.gd' -not -path 'game/addons/gut/*' -print0 |
    xargs -0 gdformat --check
find game -type f -name '*.gd' -not -path 'game/addons/gut/*' -print0 |
    xargs -0 gdlint
