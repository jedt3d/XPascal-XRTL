#!/usr/bin/env bash
set -euo pipefail

required_version="${1:-3.3.1}"

find_fpc() {
  if [[ -n "${FPC_BIN:-}" && -x "${FPC_BIN}" ]]; then
    printf '%s\n' "${FPC_BIN}"
    return 0
  fi

  if command -v fpc >/dev/null 2>&1; then
    command -v fpc
    return 0
  fi

  local local_fpc
  local_fpc="$(find .toolchains -type f \( -name fpc -o -name 'ppc*' \) -perm -111 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "${local_fpc}" ]]; then
    printf '%s\n' "${local_fpc}"
    return 0
  fi

  return 1
}

if ! fpc_bin="$(find_fpc)"; then
  echo "fpc was not found. Run tools/install-fpc.sh or set FPC_BIN." >&2
  exit 1
fi

version="$("${fpc_bin}" -iV | tr -d '[:space:]')"
echo "fpc: ${fpc_bin}"
echo "version: ${version}"

if [[ "${version}" != "${required_version}" ]]; then
  echo "Expected FreePascal ${required_version}, got ${version}." >&2
  exit 1
fi

echo "ok: FreePascal toolchain matches ${required_version}"
