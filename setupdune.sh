#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Samuel Hym, Tarides <samuel@tarides.com>

set -euo pipefail

abort() {
  printf 'Fatal error: %s\n' "$1" 1>&2
  exit 2
}

install-dune() {
  curl -fsSL https://get.dune.build/install | sh
}

lock() {
  (set -x; cd "$SETUPDUNEDIR" && dune pkg lock)
}

update-depexts() {
  case "$OS" in
    Linux)
      (set -x; sudo apt-get update)
      ;;
    macOS)
      (set -x; brew update)
      ;;
  esac
}

install-depexts() {
  DEPEXTS="$(cd "$SETUPDUNEDIR" >/dev/null && dune show depexts 2>&1)" || \
    abort "got \"$DEPEXTS\" when listing depexts"
  case "$OS,$DEPEXTS" in
    *,) # No depexts to install
      ;;
    Linux,*)
      update-depexts
      (set -x; sudo apt-get install -y $DEPEXTS)
      ;;
    macOS,*)
      update-depexts
      (set -x; brew install $DEPEXTS)
      ;;
  esac
}

build() {
  (set -x; cd "$SETUPDUNEDIR" && dune build)
}

runtest() {
  (set -x; cd "$SETUPDUNEDIR" && dune runtest)
}

w() {
  # Wrap a step to control whether it should run
  case "$SETUPDUNEAUTOMAGIC,$2" in
    *,install-dune|true,*)
      echo "::group::$1"
      "$2"
      echo "::endgroup::"
      ;;
  esac
}

main() {
  w "Install dune" install-dune
  w "Lock the project dependencies" lock
  w "Install the external dependencies" install-depexts
  w "Build the project" build
  w "Run the test" runtest
}

main
