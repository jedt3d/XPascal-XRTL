#!/usr/bin/env bash
set -euo pipefail

xpc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/xpc"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "build" ]]; then
  exec bash "${repo_root}/tools/build-xpc.sh"
fi

if [[ ! -x "${xpc}" ]]; then
  echo "build/xpc was not found or is not executable. Run tools/run-xpc.sh build first." >&2
  exit 1
fi

if [[ -z "${FPC_BIN:-}" ]]; then
  if [[ -f "${repo_root}/.toolchains/current.env" ]]; then
    # shellcheck disable=SC1091
    source "${repo_root}/.toolchains/current.env"
    export FPC_BIN
    export FPC_VERSION
  fi
fi

if [[ -z "${FPC_VERSION:-}" && -n "${FPC_BIN:-}" && -x "${FPC_BIN}" ]]; then
  export FPC_VERSION="$("${FPC_BIN}" -iV | tr -d '[:space:]')"
fi

exec "${xpc}" "$@"
