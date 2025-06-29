#!/usr/bin/env bash
set -euo pipefail

# This script installs system dependencies (depexts) listed by `dune show depexts`.
# It is intended to be called from the setup-dune composite action.

: "${RUNNER_OS:?RUNNER_OS must be set}"

DEPEXT_LIST="$(dune show depexts 2>&1)"
if [ -z "$DEPEXT_LIST" ]; then
  echo "[setup-dune] No depexts to install."
  exit 0
fi

if [ "${RUNNER_OS}" = "Linux" ]; then
  echo "[setup-dune] Installing depexts with apt-get:"
  echo "$DEPEXT_LIST"
  sudo apt-get update
  xargs -r sudo apt-get install -y <<< "$DEPEXT_LIST"
elif [ "${RUNNER_OS}" = "macOS" ]; then
  echo "[setup-dune] Installing depexts with brew:"
  echo "$DEPEXT_LIST"
  brew update
  xargs -r brew install <<< "$DEPEXT_LIST"
else
  echo "[setup-dune] Depext installation is not supported on this OS: ${RUNNER_OS}"
  exit 1
fi
