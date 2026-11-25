#!/bin/sh
set -eu

expected_version="4.7.2"
project_version="${expected_version%.*}"

if ! command -v godot >/dev/null 2>&1; then
    printf '%s\n' "error: Godot ${expected_version} is not installed in this environment" >&2
    exit 1
fi

actual_version="$(godot --version)"
case "$actual_version" in
    "${expected_version}.stable"*) ;;
    *)
        printf 'error: expected Godot %s, found %s\n' "$expected_version" "$actual_version" >&2
        exit 1
        ;;
esac

if [ ! -f game/project.godot ]; then
    printf '%s\n' "error: game/project.godot was not found; run this script from the repository" >&2
    exit 1
fi

features="$(sed -n 's/^config\/features[[:space:]]*=[[:space:]]*//p' game/project.godot)"
case "$features" in
    *"\"${project_version}\""*) ;;
    *)
        printf 'error: game/project.godot must declare Godot feature version %s\n' "$project_version" >&2
        exit 1
        ;;
esac

printf 'Godot version check passed: %s (%s)\n' "$expected_version" "$actual_version"
