#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_path="${1:-}"
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

mkdir -p "${repo_root}/build" "${repo_root}/build/units"
compiler_args=(-Mobjfpc -Sh)

if [[ -n "${FPC_UNIT_DIR:-}" ]]; then
  compiler_args+=(-Fu"${FPC_UNIT_DIR}"/*)
fi

if [[ "$(bash "${repo_root}/tools/platform-id.sh")" == macos-* ]]; then
  sdk_path="$(xcrun --show-sdk-path)"
  compiler_args+=(-k"-syslibroot" -k"${sdk_path}" -k"-lSystem")
fi

if [[ -n "${project_path}" ]]; then
  project_root="$(cd "${project_path}" && pwd)"
  project_name="$(basename "${project_root}")"
  project_main="${project_root}/src/main.pas"
  project_file="${project_root}/xproject.toml"
  project_build="${project_root}/build"
  project_unit_build="${project_build}/units"

  if [[ ! -f "${project_file}" ]]; then
    echo "Expected xproject.toml in ${project_root}." >&2
    exit 1
  fi
  if [[ ! -f "${project_main}" ]]; then
    echo "Expected src/main.pas in ${project_root}." >&2
    exit 1
  fi

  mkdir -p "${project_build}" "${project_unit_build}"
  rm -f "${project_build}/${project_name}"
  "${fpc_bin}" "${compiler_args[@]}" -FU"${project_unit_build}" -FE"${project_build}" -o"${project_build}/${project_name}" "${project_main}"
  echo "built: ${project_name}/build/${project_name}"
  exit 0
fi

core_tests=(core_smoke core_result_tests core_option_tests)
database_tests=(database_smoke database_sqlite_tests)
rm -f "${repo_root}/build/xpc" "${repo_root}/build/hello_xpc"
for test_name in "${core_tests[@]}"; do
  rm -f "${repo_root}/build/${test_name}"
done
for test_name in "${database_tests[@]}"; do
  rm -f "${repo_root}/build/${test_name}"
done

"${fpc_bin}" "${compiler_args[@]}" -Fu"${repo_root}" -FU"${repo_root}/build/units" -FE"${repo_root}/build" -o"${repo_root}/build/xpc" "${repo_root}/src/xpc/xpc.pas"
"${fpc_bin}" "${compiler_args[@]}" -FU"${repo_root}/build/units" -FE"${repo_root}/build" -o"${repo_root}/build/hello_xpc" "${repo_root}/tests/smoke/hello_xpc.pas"

for test_name in "${core_tests[@]}"; do
  "${fpc_bin}" "${compiler_args[@]}" -Fu"${repo_root}/src/xrtl/core" -FU"${repo_root}/build/units" -FE"${repo_root}/build" -o"${repo_root}/build/${test_name}" "${repo_root}/tests/xrtl/core/${test_name}.pas"
  "${repo_root}/build/${test_name}"
done

for test_name in "${database_tests[@]}"; do
  "${fpc_bin}" "${compiler_args[@]}" -Fu"${repo_root}/src/xrtl/core" -Fu"${repo_root}/src/xrtl/database" -FU"${repo_root}/build/units" -FE"${repo_root}/build" -o"${repo_root}/build/${test_name}" "${repo_root}/tests/xrtl/database/${test_name}.pas"
  "${repo_root}/build/${test_name}"
done

echo "built: build/xpc"
echo "built: build/hello_xpc"
for test_name in "${core_tests[@]}"; do
  echo "built: build/${test_name}"
done
for test_name in "${database_tests[@]}"; do
  echo "built: build/${test_name}"
done
