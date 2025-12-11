#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Samuel Hym, Tarides <samuel@tarides.com>

set -euo pipefail

abort() {
  printf '::error title=Fatal error::%s\n' "$1" 1>&2
  exit 2
}

dune_aux() {
  status=0
  (set -x; cd "$SETUPDUNEDIR" && \
    dune "$@" \
      ${SETUPDUNEWORKSPACE:+--workspace="$SETUPDUNEWORKSPACE"} \
      ${SETUPDUNEDISPLAY:+--display="$SETUPDUNEDISPLAY"}) \
    || status=$?
  if ! test "$status" = 0; then
    if test -e "$SETUPDUNEDIR/_build/log"; then
      echo "::endgroup::"
      echo '::group::`_build/log`'
      printf '::error title=Fatal error::"dune %s" exited with code %d\n' \
        "$*" "$status" 1>&2
      cat "$SETUPDUNEDIR/_build/log"
    else
      printf '::error title=Fatal error::"dune %s" exited with code %d\n' \
        "$*" "$status" 1>&2
    fi
    exit "$status"
  fi
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

enable-pkg() {
  case "$(dune --version)" in
    3.19*|3.20*)
      (set -x; cd "$SETUPDUNEDIR" && test -d dune.lock) || dune_aux pkg lock
      ;;
    *)
      CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dune"
      if test -e "$CONFIG_DIR/config"; then
        dune_aux pkg enabled \
          || abort "dune package management is disabled in your configuration"
      else
        mkdir -p "$CONFIG_DIR"
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
  DEPEXTS="$(cd "$SETUPDUNEDIR" >/dev/null && \
             dune show depexts \
               ${SETUPDUNEWORKSPACE:+--workspace="$SETUPDUNEWORKSPACE"} 2>&1)" \
    || abort "got \"$DEPEXTS\" when listing depexts"
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
      STEPS="install-dune enable-pkg lazy-update-depexts install-gpatch install-depexts build runtest"
      ;;
    "Linux,all")
      STEPS="install-dune enable-pkg lazy-update-depexts install-depexts build runtest"
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
  w "Enable dune package management" enable-pkg
  w "Install GNU patch on macOS" install-gpatch
  w "Install the external dependencies" install-depexts
  w "Build the project" build
  w "Run the test" runtest
}

main
