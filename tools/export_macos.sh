#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
"$project_root/tools/build_xbox_usb_bridge.sh"
"$godot_bin" --headless --path "$project_root" --export-release macOS "$project_root/build/ManiubraPrototype.app"
cp "$project_root/tools/maniubra_xbox_usb_bridge" "$project_root/build/ManiubraPrototype.app/Contents/MacOS/maniubra_xbox_usb_bridge"
echo "Exported $project_root/build/ManiubraPrototype.app with Xbox USB bridge"
