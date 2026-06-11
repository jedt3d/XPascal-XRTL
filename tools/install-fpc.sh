#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${XP_PLATFORM:-$(bash "${repo_root}/tools/platform-id.sh")}"
install_dir="${INSTALL_DIR:-${repo_root}/.toolchains/fpc-3.3.1/${platform}}"
archive_url="${FPC_ARCHIVE_URL:-}"
sha256="${FPC_ARCHIVE_SHA256:-}"

if [[ -z "${archive_url}" ]]; then
case "${platform}" in
    linux-x86_64)
      archive_url="https://downloads.freepascal.org/fpc/snapshot/v33/x86_64-linux/fpc-3.3.1.x86_64-linux.tar.gz"
      ;;
    macos-aarch64)
      archive_url="https://downloads.freepascal.org/fpc/snapshot/v33/aarch64-darwin/fpc-3.3.1.aarch64-darwin.tar.gz"
      ;;
    macos-x86_64)
      echo "No locked FPC 3.3.1 snapshot is currently available for macOS Intel x86_64." >&2
      echo "Set FPC_ARCHIVE_URL and FPC_ARCHIVE_SHA256 if you have a trusted artifact." >&2
      exit 1
      ;;
    *)
      echo "No default FPC 3.3.1 snapshot is locked for ${platform}." >&2
      echo "Set FPC_ARCHIVE_URL and optionally FPC_ARCHIVE_SHA256." >&2
      exit 1
      ;;
  esac
fi

mkdir -p "${install_dir}"
archive_path="${install_dir}/$(basename "${archive_url}")"

if [[ -f "${archive_path}" ]]; then
  echo "Using existing archive ${archive_path}"
elif command -v curl >/dev/null 2>&1; then
  echo "Downloading FPC 3.3.1 from ${archive_url}"
  curl -L "${archive_url}" -o "${archive_path}"
elif command -v wget >/dev/null 2>&1; then
  echo "Downloading FPC 3.3.1 from ${archive_url}"
  wget -O "${archive_path}" "${archive_url}"
else
  echo "curl or wget is required." >&2
  exit 1
fi

if [[ -n "${sha256}" && "${sha256}" != "PENDING" ]]; then
  actual="$(sha256sum "${archive_path}" | awk '{print tolower($1)}')"
  expected="$(printf '%s' "${sha256}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "SHA256 mismatch. Expected ${expected}, got ${actual}." >&2
    exit 1
  fi
else
  echo "warning: no SHA256 provided yet. This is allowed only during bootstrap." >&2
fi

echo "Extracting ${archive_path}"
tar -xzf "${archive_path}" -C "${install_dir}"
find "${install_dir}" -type f \( -name fpc -o -name 'ppc*' \) -exec chmod +x {} \; 2>/dev/null || true

  case "${platform}" in
  macos-aarch64)
    compiler_candidates=("ppca64" "fpc")
    ;;
  linux-x86_64)
    compiler_candidates=("fpc" "ppcx64")
    ;;
  *)
    compiler_candidates=("fpc" "ppc*")
    ;;
esac

fpc_bin=""
for candidate in "${compiler_candidates[@]}"; do
  fpc_bin="$(find "${install_dir}" -type f -name "${candidate}" -perm -111 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "${fpc_bin}" ]]; then
    break
  fi
done

if [[ -z "${fpc_bin}" ]]; then
  echo "Archive extracted, but no fpc or ppc* compiler was found under ${install_dir}." >&2
  exit 1
fi

fpc_dir="$(dirname "${fpc_bin}")"
if [[ "$(basename "${fpc_bin}")" != "fpc" ]]; then
  cat > "${fpc_dir}/fpc" <<EOF
#!/usr/bin/env bash
exec "\$(dirname "\$0")/$(basename "${fpc_bin}")" "\$@"
EOF
  chmod +x "${fpc_dir}/fpc"
  echo "created wrapper: ${fpc_dir}/fpc"
fi
echo "fpc: ${fpc_bin}"

if ! "${fpc_bin}" -iV >/dev/null 2>&1; then
  echo "The selected compiler cannot execute on this machine: ${fpc_bin}" >&2
  echo "platform: ${platform}" >&2
  if command -v file >/dev/null 2>&1; then
    file "${fpc_bin}" >&2 || true
  fi
  exit 1
fi

{
  printf 'XP_PLATFORM=%q\n' "${platform}"
  printf 'FPC_BIN=%q\n' "${fpc_bin}"
  printf 'FPC_DIR=%q\n' "${fpc_dir}"
  printf 'FPC_VERSION=%q\n' "$("${fpc_bin}" -iV | tr -d '[:space:]')"
  system_ppu="$(find "${install_dir}" -type f -path '*/units/*/rtl/system.ppu' 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "${system_ppu}" ]]; then
    unit_dir="$(dirname "$(dirname "${system_ppu}")")"
    printf 'FPC_UNIT_DIR=%q\n' "${unit_dir}"
  fi
} > "${repo_root}/.toolchains/current.env"
echo "wrote: ${repo_root}/.toolchains/current.env"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${fpc_dir}" >> "${GITHUB_PATH}"
fi

export PATH="${fpc_dir}:${PATH}"
export FPC_BIN="${fpc_bin}"
"${fpc_bin}" -iV
