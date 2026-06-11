#!/usr/bin/env bash
set -euo pipefail

required_version="${1:-3.3.1}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${XP_PLATFORM:-$(bash "${repo_root}/tools/platform-id.sh")}"

if [[ -f "${repo_root}/.toolchains/current.env" ]]; then
  # shellcheck disable=SC1091
  source "${repo_root}/.toolchains/current.env"
  platform="${XP_PLATFORM:-${platform}}"
fi

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
  case "${platform}" in
    macos-aarch64)
      local_fpc="$(find "${repo_root}/.toolchains/fpc-3.3.1/${platform}" -type f \( -name fpc -o -name ppca64 \) -perm -111 2>/dev/null | sort | head -n 1 || true)"
      ;;
    linux-x86_64)
      local_fpc="$(find "${repo_root}/.toolchains/fpc-3.3.1/${platform}" -type f \( -name fpc -o -name ppcx64 \) -perm -111 2>/dev/null | sort | head -n 1 || true)"
      ;;
    *)
      local_fpc="$(find "${repo_root}/.toolchains/fpc-3.3.1/${platform}" -type f \( -name fpc -o -name 'ppc*' \) -perm -111 2>/dev/null | sort | head -n 1 || true)"
      ;;
  esac
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
echo "platform: ${platform}"
echo "fpc: ${fpc_bin}"
echo "version: ${version}"

if [[ "${version}" != "${required_version}" ]]; then
  echo "Expected FreePascal ${required_version}, got ${version}." >&2
  exit 1
fi

echo "ok: FreePascal toolchain matches ${required_version}"
