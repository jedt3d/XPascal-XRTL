#!/usr/bin/env bash
set -euo pipefail

install_dir="${INSTALL_DIR:-.toolchains/fpc-3.3.1}"
archive_url="${FPC_ARCHIVE_URL:-}"
sha256="${FPC_ARCHIVE_SHA256:-}"

os="$(uname -s)"
arch="$(uname -m)"

if [[ -z "${archive_url}" ]]; then
  case "${os}-${arch}" in
    Linux-x86_64)
      archive_url="https://downloads.freepascal.org/fpc/snapshot/v33/x86_64-linux/fpc-3.3.1.x86_64-linux.tar.gz"
      ;;
    Darwin-arm64)
      archive_url="https://downloads.freepascal.org/fpc/snapshot/v33/aarch64-darwin/fpc-3.3.1.aarch64-darwin.tar.gz"
      ;;
    Darwin-aarch64)
      archive_url="https://downloads.freepascal.org/fpc/snapshot/v33/aarch64-darwin/fpc-3.3.1.aarch64-darwin.tar.gz"
      ;;
    *)
      echo "No default FPC 3.3.1 snapshot is locked for ${os}-${arch}." >&2
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

fpc_bin="$(find "${install_dir}" -type f \( -name fpc -o -name 'ppc*' \) -perm -111 | sort | head -n 1 || true)"
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

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${fpc_dir}" >> "${GITHUB_PATH}"
fi

export PATH="${fpc_dir}:${PATH}"
export FPC_BIN="${fpc_bin}"
"${fpc_bin}" -iV
