#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "${repo_root}/tools/check-toolchain.sh"

if [[ -f "${repo_root}/.toolchains/current.env" ]]; then
  # shellcheck disable=SC1091
  source "${repo_root}/.toolchains/current.env"
fi

if [[ -n "${FPC_BIN:-}" && -x "${FPC_BIN}" ]]; then
  fpc_bin="${FPC_BIN}"
elif command -v fpc >/dev/null 2>&1; then
  fpc_bin="$(command -v fpc)"
else
  platform="${XP_PLATFORM:-$(bash "${repo_root}/tools/platform-id.sh")}"
  fpc_bin="$(find "${repo_root}/.toolchains/fpc-3.3.1/${platform}" -type f \( -name fpc -o -name 'ppc*' \) -perm -111 2>/dev/null | sort | head -n 1)"
fi

mkdir -p "${repo_root}/build"
"${fpc_bin}" -Mobjfpc -Sh -Fu"${repo_root}" -FE"${repo_root}/build" -o"${repo_root}/build/xpc" "${repo_root}/src/xpc/xpc.pas"
"${fpc_bin}" -Mobjfpc -Sh -FE"${repo_root}/build" -o"${repo_root}/build/hello_xpc" "${repo_root}/tests/smoke/hello_xpc.pas"

echo "built: build/xpc"
echo "built: build/hello_xpc"
