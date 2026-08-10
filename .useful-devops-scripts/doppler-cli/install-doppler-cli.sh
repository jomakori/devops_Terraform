#!/usr/bin/env bash
# =============================================================================
# install-doppler-cli.sh — GitOps-managed Doppler CLI install
#
# Repo:  jomakori/devops_Terraform
# Docs:  https://docs.doppler.com/docs/install-cli
#
# Installs the Doppler CLI from the official binary endpoint, pinned to a
# version for reproducibility. Signature verification via gpgv when available
# (the official install script's behavior), falling back to a plain download
# with an explicit warning when gnupg is not installed.
#
# Usage:
#   ./install-doppler-cli.sh [VERSION] [INSTALL_PATH]
#     VERSION      (optional) tag, e.g. 3.71.2 — default: latest from Doppler API
#     INSTALL_PATH (optional) install dir  — default: ~/.local/bin
#
# Example:
#   ./install-doppler-cli.sh                       # latest → ~/.local/bin
#   ./install-doppler-cli.sh 3.71.2 /usr/local/bin # pinned → /usr/local/bin
# =============================================================================
set -euo pipefail

DOPPLER_DOMAIN="cli.doppler.com"
VERSION="${1:-}"
INSTALL_PATH="${2:-$HOME/.local/bin}"

# --- resolve version ---------------------------------------------------------
if [ -z "$VERSION" ]; then
  VERSION="$(curl -sL --max-time 20 "https://api.github.com/repos/DopplerHQ/cli/releases/latest" \
    | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//')"
fi
if [ -z "$VERSION" ]; then
  echo "ERROR: could not resolve latest Doppler CLI version" >&2
  exit 1
fi
echo "Doppler CLI version: $VERSION"

# --- detect os/arch ----------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *) echo "ERROR: unsupported OS '$OS'" >&2; exit 1 ;;
esac
case "$ARCH" in
  x86_64|amd64)   ARCH="amd64" ;;
  arm64|aarch64)  ARCH="arm64" ;;
  *) echo "ERROR: unsupported architecture '$ARCH'" >&2; exit 1 ;;
esac
echo "Target: $OS/$ARCH"

# --- download ----------------------------------------------------------------
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
BIN_TMP="$TMPDIR/doppler"
URL="https://$DOPPLER_DOMAIN/download?os=$OS&arch=$ARCH&format=tar&version=$VERSION"
echo "Downloading: $URL"
curl -fsSL --retry 3 --max-time 60 "$URL" -o "$BIN_TMP.tar.gz"

# --- verify signature (when gnupg available) ---------------------------------
GPGV="$(command -v gpgv || true)"
if [ -x "$GPGV" ]; then
  echo "Verifying binary signature (gpgv)..."
  curl -fsSL --max-time 30 "https://$DOPPLER_DOMAIN/download/signature?os=$OS&arch=$ARCH&format=tar&version=$VERSION" -o "$BIN_TMP.sig"
  curl -fsSL --max-time 30 "https://$DOPPLER_DOMAIN/keys/public" -o "$TMPDIR/publickey.gpg"
  gpgv --keyring "$TMPDIR/publickey.gpg" "$BIN_TMP.sig" "$BIN_TMP.tar.gz"
else
  echo "WARNING: gpgv not found — skipping signature verification (install gnupg to verify)"
fi

# --- install ---------------------------------------------------------------
mkdir -p "$INSTALL_PATH"
tar -xzf "$BIN_TMP.tar.gz" -C "$TMPDIR"
install -m 0755 "$TMPDIR/doppler" "$INSTALL_PATH/doppler"

# --- verify ------------------------------------------------------------------
"$INSTALL_PATH/doppler" --version
echo
echo "Installed: $INSTALL_PATH/doppler"
echo "Add to PATH:  export PATH=\"$INSTALL_PATH:\$PATH\""
echo
echo "Next: authenticate with 'doppler login' or set DOPPLER_TOKEN, then:"
echo "  doppler secrets set KEY=value --project devops --config svc"
