#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Samuel Hym, Tarides <samuel@tarides.com>

set -euo pipefail

abort() {
  printf 'Fatal error: %s\n' "$1" 1>&2
  exit 2
}

dune_aux() {
  (set -x; cd "$SETUPDUNEDIR" && \
    dune "$@" ${SETUPDUNEDISPLAY:+--display="$SETUPDUNEDISPLAY"})
}

install-dune() {
  case "$SETUPDUNEVERSION" in
    nightly|dev)
      (set -x; curl -fsSL https://get.dune.build/install | sh)
      ;;
    latest)
      (set -x; curl -fsSL https://github.com/ocaml-dune/dune-bin-install/releases/download/v2/install.sh | sh -s -- --install-root "$HOME/.local" --no-update-shell-config)
      ;;
    *)
      (set -x; curl -fsSL https://github.com/ocaml-dune/dune-bin-install/releases/download/v2/install.sh | sh -s -- "$SETUPDUNEVERSION" --install-root "$HOME/.local" --no-update-shell-config)
      ;;
  esac
  (set -x; dune --version)
}

enable_pkg() {
  case "$(dune --version)" in
    3.19*|3.20*)
      (set -x; cd "$SETUPDUNEDIR" && test -d dune.lock) || dune_aux pkg lock
      ;;
    *)
      CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dune"
      mkdir -p "$CONFIG_DIR"
      if test -e "$CONFIG_DIR/config"; then
        printf 'Warning: %s already exists, assume it enables package management\n' "$CONFIG_DIR/config" >&2
      else
        printf '(lang dune 3.21)\n(pkg enabled)\n' > "$CONFIG_DIR/config"
        (set -x; cat "$CONFIG_DIR/config")
      fi
      ;;
  esac
}

lazy-update-depexts() {
  case "$OS,$STEPS" in
    Linux,*lazy-update-depexts*)
      (set -x; sudo apt-get update)
      STEPS="${STEPS//lazy-update-depexts/}"
      ;;
    macOS,*lazy-update-depexts*)
      (set -x; brew update)
      STEPS="${STEPS//lazy-update-depexts/}"
      ;;
  esac
}

install-gpatch() {
  case "$OS" in
    macOS)
      lazy-update-depexts
      (set -x; brew install gpatch)
      PATH="$(brew --prefix gpatch)/libexec/gnubin:$PATH"
      printf '%s/libexec/gnubin\n' "$(brew --prefix gpatch)" >> "$GITHUB_PATH"
      (set -x; patch --version)
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
      lazy-update-depexts
      # shellcheck disable=SC2086
      (set -x; sudo apt-get install -y $DEPEXTS)
      ;;
    macOS,*)
      lazy-update-depexts
      # shellcheck disable=SC2086
      (set -x; brew install $DEPEXTS)
      ;;
  esac
}

build() {
  dune_aux build
}

runtest() {
  dune_aux runtest
}

expand_steps() {
  case "$OS,$SETUPDUNESTEPS" in
    "macOS,all")
      STEPS="install-dune enable_pkg lazy-update-depexts install-gpatch install-depexts build runtest"
      ;;
    "Linux,all")
      STEPS="install-dune enable_pkg lazy-update-depexts install-depexts build runtest"
      ;;
    "macOS,"|"Linux,")
      STEPS="install-dune"
      ;;
    *)
      STEPS="$SETUPDUNESTEPS"
      ;;
  esac
}

w() {
  # Wrap a step to control whether it should run
  case "$STEPS" in
    *"$2"*)
      echo "::group::$1"
      "$2"
      echo "::endgroup::"
      ;;
  esac
}

main() {
  expand_steps
  w "Install dune" install-dune
  w "Enable dune package management" enable_pkg
  w "Install GNU patch on macOS" install-gpatch
  w "Install the external dependencies" install-depexts
  w "Build the project" build
  w "Run the test" runtest
}

main
