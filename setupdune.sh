#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Samuel Hym, Tarides <samuel@tarides.com>

set -euo pipefail

: "${ERRORPREFIX:="::error::Fatal error: "}"

abort() {
  printf '%s%s\n' "$ERRORPREFIX" "$1"
  exit 2
}

# A simple wrapper to run Dune in the correct directory with the workspace
# setting
dune_() {
  x=:
  case "$1" in
    "-x")
      shift
      x="set -x"
      ;;
  esac
  ($x; cd "$SETUPDUNEDIR" >/dev/null && \
    dune "$@" ${SETUPDUNEWORKSPACE:+--workspace="$SETUPDUNEWORKSPACE"})
}

# Run Dune recording trace (and displaying it if requested)
dune_trace() {
  status=0
  trace_file="_build/trace-$*.$SETUPDUNE_TRACEEXT"
  trace_file="${trace_file// /_}"
  dune_ -x "$@" --trace-file="$trace_file" \
      ${SETUPDUNEDISPLAY:+--display="$SETUPDUNEDISPLAY"} \
    || status=$?
  if ! test "$status" = 0; then
    echo "::endgroup::"
    echo '::group::Show the build trace'
    printf '%s"dune %s" exited with code %d\n' \
      "$ERRORPREFIX" "$*" "$status"
    if test -e "$SETUPDUNEDIR/_build/log"; then
      cat "$SETUPDUNEDIR/_build/log"
    else
      (set -x; cd "$SETUPDUNEDIR" && \
        dune trace commands --trace-file="$trace_file")
    fi
    return "$status"
  fi
}

install-dune() {
  # Whether the version should be explicit set in the installer
  case "$SETUPDUNEVERSION" in
    nightly|dev)
      explicit=
      ;;
    latest|*)
      explicit=y
      ;;
  esac
  (set -x;
    curl -fsSLv4 --http1.1 https://get.dune.build/install | \
      sh -s ${explicit:+-- --release "$SETUPDUNEVERSION"}
    command -v dune
    dune --version)
  case "$(dune --version)" in
    3.19*|3.20*|3.21*)
      SETUPDUNE_TRACEEXT=json
      ;;
    *)
      SETUPDUNE_TRACEEXT=csexp
      ;;
  esac
}

enable-pkg() {
  case "$(dune --version)" in
    3.19*|3.20*)
      mkdir -p "$SETUPDUNEDIR/_build"
      (set -x; cd "$SETUPDUNEDIR" && test -d dune.lock) || dune_trace pkg lock
      ;;
    *)
      CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dune"
      if test -e "$CONFIG_DIR/config"; then
        dune_ pkg enabled || abort \
          "dune package management is disabled in your global configuration"
      else
        mkdir -p "$CONFIG_DIR"
        printf '(lang dune 3.21)\n(pkg enabled)\n' > "$CONFIG_DIR/config"
        (set -x; cat "$CONFIG_DIR/config")
        dune_ pkg enabled || abort \
          "dune package management is disabled in your workspace configuration"
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
  DEPEXTS="$(dune_ show depexts 2>&1)" \
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

build-deps() {
  dune_trace build @pkg-install
}

build() {
  dune_trace build
}

runtest() {
  dune_trace runtest
}

expand_steps() {
  case "$OS,$SETUPDUNESTEPS" in
    "macOS,all")
      STEPS="install-dune enable-pkg lazy-update-depexts install-gpatch install-depexts build-deps build runtest"
      ;;
    "Linux,all")
      STEPS="install-dune enable-pkg lazy-update-depexts install-depexts build-deps build runtest"
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
  status=0
  # Wrap a step to control whether it should run
  case "$STEPS" in
    *"$2"*)
      echo "::group::$1"
      "$2" || status=$?
      echo "::endgroup::"
      ;;
  esac
  test "$status" = 0 || exit "$status"
}

main() {
  expand_steps
  w "Install dune" install-dune
  w "Enable dune package management" enable-pkg
  w "Install GNU patch on macOS" install-gpatch
  w "Install the external dependencies" install-depexts
  w "Build the dependencies" build-deps
  w "Build the project" build
  w "Run the test" runtest
}

main
