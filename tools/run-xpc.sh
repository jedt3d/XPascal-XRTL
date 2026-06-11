#!/usr/bin/env bash
set -euo pipefail

xpc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/xpc"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "${xpc}" ]]; then
  echo "build/xpc was not found or is not executable. Run tools/build-xpc.sh first." >&2
  exit 1
fi

if [[ -z "${FPC_BIN:-}" ]]; then
  if [[ -f "${repo_root}/.toolchains/current.env" ]]; then
    # shellcheck disable=SC1091
    source "${repo_root}/.toolchains/current.env"
    export FPC_BIN
  fi
fi

exec "${xpc}" "$@"
