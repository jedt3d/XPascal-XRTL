#!/usr/bin/env bash
set -euo pipefail

os="$(uname -s)"
arch="$(uname -m)"

case "${os}-${arch}" in
  Darwin-arm64|Darwin-aarch64)
    printf '%s\n' "macos-aarch64"
    ;;
  Darwin-x86_64)
    printf '%s\n' "macos-x86_64"
    ;;
  Linux-x86_64)
    printf '%s\n' "linux-x86_64"
    ;;
  *)
    echo "Unsupported platform: ${os}-${arch}" >&2
    exit 1
    ;;
esac
