#!/usr/bin/env bash
set -euo pipefail

./tools/check-toolchain.sh

if [[ -n "${FPC_BIN:-}" && -x "${FPC_BIN}" ]]; then
  fpc_bin="${FPC_BIN}"
elif command -v fpc >/dev/null 2>&1; then
  fpc_bin="$(command -v fpc)"
else
  fpc_bin="$(find .toolchains -type f \( -name fpc -o -name 'ppc*' \) -perm -111 2>/dev/null | sort | head -n 1)"
fi

mkdir -p build
"${fpc_bin}" -Mobjfpc -Sh -Fu. -FEbuild -obuild/xpc src/xpc/xpc.pas
"${fpc_bin}" -Mobjfpc -Sh -FEbuild -obuild/hello_xpc tests/smoke/hello_xpc.pas

echo "built: build/xpc"
echo "built: build/hello_xpc"
