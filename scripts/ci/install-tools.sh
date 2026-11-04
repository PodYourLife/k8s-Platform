#!/usr/bin/env bash
# install-tools.sh — installs the pinned CI toolchain into $RUNNER_TEMP/.ci-bin.
# Every archive is verified against a pinned SHA-256 before extraction.
# Helm is the only exception: get.helm.sh publishes the checksum next to the
# archive, so it is verified against that file (same origin, TLS-protected).
set -euo pipefail

readonly TOOLS_DIR="${TOOLS_DIR:-${RUNNER_TEMP:-$PWD}/.ci-bin}"
readonly HELM_VERSION="v3.17.3"
readonly KUBECONFORM_VERSION="v0.7.0"
readonly KUBECONFORM_SHA256="c31518ddd122663b3f3aa874cfe8178cb0988de944f29c74a0b9260920d115d3"
readonly KYVERNO_VERSION="v1.14.1"
readonly KYVERNO_SHA256="b4052be8e8022b028925bfcec41daa8c111e16dd54f0cfe36e71cc3ee51f93d9"
readonly GITLEAKS_VERSION="8.24.2"
readonly GITLEAKS_SHA256="fa0500f6b7e41d28791ebc680f5dd9899cd42b58629218a5f041efa899151a8e"

mkdir -p "$TOOLS_DIR"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

# install_archive <url> <expected_sha256> <binary_name>
install_archive() {
  local archive_url="$1" expected_sha256="$2" binary_name="$3"
  local archive_path="$download_dir/$binary_name.tar.gz"
  curl -sSfL -o "$archive_path" "$archive_url"
  echo "$expected_sha256  $archive_path" | sha256sum --check --strict -
  tar -xzf "$archive_path" -C "$download_dir" "$binary_name"
  install -m 0755 "$download_dir/$binary_name" "$TOOLS_DIR/$binary_name"
}

install_archive \
  "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
  "$KUBECONFORM_SHA256" kubeconform
install_archive \
  "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz" \
  "$KYVERNO_SHA256" kyverno
install_archive \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
  "$GITLEAKS_SHA256" gitleaks

# Helm: archive layout is linux-amd64/helm, checksum fetched from the same origin.
helm_archive="helm-${HELM_VERSION}-linux-amd64.tar.gz"
curl -sSfL -o "$download_dir/$helm_archive" "https://get.helm.sh/$helm_archive"
helm_sha256="$(curl -sSfL "https://get.helm.sh/$helm_archive.sha256sum" | awk '{print $1}')"
echo "$helm_sha256  $download_dir/$helm_archive" | sha256sum --check --strict -
tar -xzf "$download_dir/$helm_archive" -C "$download_dir" linux-amd64/helm
install -m 0755 "$download_dir/linux-amd64/helm" "$TOOLS_DIR/helm"

echo "$TOOLS_DIR" >> "${GITHUB_PATH:-/dev/null}"
echo "Toolchain installed in $TOOLS_DIR"
