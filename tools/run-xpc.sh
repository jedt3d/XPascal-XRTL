#!/usr/bin/env bash
set -euo pipefail

xpc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/xpc"

if [[ ! -x "${xpc}" ]]; then
  echo "build/xpc was not found or is not executable. Run tools/build-xpc.sh first." >&2
  exit 1
fi

if [[ -z "${FPC_BIN:-}" ]]; then
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local_fpc="$(find "${repo_root}/.toolchains" -type f \( -name fpc -o -name 'ppc*' \) -perm -111 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "${local_fpc}" ]]; then
    export FPC_BIN="${local_fpc}"
  fi
fi

exec "${xpc}" "$@"
