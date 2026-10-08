#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
libusb_prefix=$(brew --prefix libusb)
clang -std=c11 -O2 -Wall -Wextra -Werror \
  -I"$libusb_prefix/include/libusb-1.0" \
  "$project_root/tools/xbox_usb_bridge.c" \
  "$libusb_prefix/lib/libusb-1.0.a" \
  -framework IOKit -framework CoreFoundation -framework Security \
  -o "$project_root/tools/maniubra_xbox_usb_bridge"
echo "Built $project_root/tools/maniubra_xbox_usb_bridge"
