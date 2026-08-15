#!/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINS="$ROOT/pins.env"
TEMP_DIR="$(mktemp -d -t openclaw-pin-check.XXXXXX)"
trap 'rm -rf "$TEMP_DIR"' EXIT

read_pin() {
  sed -n "s/^$1=//p" "$PINS"
}

verify_file() {
  local label="$1" path="$2" expected="$3" actual
  actual="$(shasum -a 256 "$path" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'PASS: %s %s\n' "$label" "$actual"
}

version="$(read_pin OPENCLAW_VERSION)"
commit="$(read_pin OPENCLAW_COMMIT)"
mac_hash="$(read_pin OPENCLAW_INSTALL_CLI_SH_SHA256)"
win_hash="$(read_pin OPENCLAW_INSTALL_PS1_SHA256)"
claude_version="$(read_pin CLAUDE_CODE_VERSION)"
claude_hash="$(read_pin CLAUDE_CODE_TARBALL_SHA256)"

[[ "$version" =~ ^[0-9]{4}\.[0-9]+\.[0-9]+(-[0-9]+)?$ ]] || { printf 'FAIL: invalid OpenClaw version pin\n' >&2; exit 1; }
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { printf 'FAIL: invalid OpenClaw commit pin\n' >&2; exit 1; }
[[ "$mac_hash" =~ ^[0-9a-f]{64}$ ]] || { printf 'FAIL: invalid Mac checksum pin\n' >&2; exit 1; }
[[ "$win_hash" =~ ^[0-9a-f]{64}$ ]] || { printf 'FAIL: invalid Windows checksum pin\n' >&2; exit 1; }
[[ "$claude_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'FAIL: invalid Claude Code version pin\n' >&2; exit 1; }
[[ "$claude_hash" =~ ^[0-9a-f]{64}$ ]] || { printf 'FAIL: invalid Claude Code checksum pin\n' >&2; exit 1; }

curl -fsSL --proto '=https' --tlsv1.2 --retry 3 \
  "https://raw.githubusercontent.com/openclaw/openclaw/$commit/scripts/install-cli.sh" \
  -o "$TEMP_DIR/install-cli.sh"
curl -fsSL --proto '=https' --tlsv1.2 --retry 3 \
  "https://raw.githubusercontent.com/openclaw/openclaw/$commit/scripts/install.ps1" \
  -o "$TEMP_DIR/install.ps1"
curl -fsSL --proto '=https' --tlsv1.2 --retry 3 \
  "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$claude_version.tgz" \
  -o "$TEMP_DIR/claude-code.tgz"

verify_file "install-cli.sh" "$TEMP_DIR/install-cli.sh" "$mac_hash"
verify_file "install.ps1" "$TEMP_DIR/install.ps1" "$win_hash"
verify_file "Claude Code $claude_version" "$TEMP_DIR/claude-code.tgz" "$claude_hash"
printf 'All consumed upstream bootstrap pins are reproducible.\n'
