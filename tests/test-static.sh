#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC="$ROOT/install-mac.sh"
WIN="$ROOT/install-windows.ps1"
PINS="$ROOT/pins.env"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

bash -n "$MAC"

dry_output="$("$MAC" --dry-run)"
[[ "$dry_output" == *"safe dry run"* ]] || fail "Mac dry-run banner missing"
[[ "$dry_output" == *"2026.7.1-2"* ]] || fail "Pinned version missing from Mac dry-run"
[[ "$dry_output" == *"Tailscale Serve"* ]] || fail "Private remote plan missing"
[[ "$dry_output" == *"ChatGPT subscription"* ]] || fail "ChatGPT subscription is not in the primary plan"
[[ "$dry_output" == *"Claude Code subscription"* ]] || fail "Claude Code subscription is not in the primary plan"
[[ "$dry_output" == *"fresh dedicated"* ]] || fail "Fresh-account prerequisite is missing from the plan"

version="$(sed -n 's/^OPENCLAW_VERSION=//p' "$PINS")"
commit="$(sed -n 's/^OPENCLAW_COMMIT=//p' "$PINS")"
mac_hash="$(sed -n 's/^OPENCLAW_INSTALL_CLI_SH_SHA256=//p' "$PINS")"
win_hash="$(sed -n 's/^OPENCLAW_INSTALL_PS1_SHA256=//p' "$PINS")"
claude_version="$(sed -n 's/^CLAUDE_CODE_VERSION=//p' "$PINS")"
claude_hash="$(sed -n 's/^CLAUDE_CODE_TARBALL_SHA256=//p' "$PINS")"

[[ "$version" =~ ^[0-9]{4}\.[0-9]+\.[0-9]+(-[0-9]+)?$ ]] || fail "Invalid OpenClaw version pin"
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || fail "Invalid OpenClaw commit pin"
[[ "$mac_hash" =~ ^[0-9a-f]{64}$ ]] || fail "Invalid Mac installer checksum"
[[ "$win_hash" =~ ^[0-9a-f]{64}$ ]] || fail "Invalid Windows installer checksum"
[[ "$claude_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid Claude Code version"
[[ "$claude_hash" =~ ^[0-9a-f]{64}$ ]] || fail "Invalid Claude Code package checksum"

rg -q 'scripts/install-cli\.sh' "$MAC" || fail "Mac does not use the local-prefix installer"
rg -q 'scripts/install\.ps1' "$WIN" || fail "Windows does not use the official PowerShell installer"
rg -q 'gateway\.tailscale\.mode.*serve' "$MAC" || fail "Mac does not configure Tailscale Serve"
rg -q 'gateway\.tailscale\.mode.*serve' "$WIN" || fail "Windows does not configure Tailscale Serve"
rg -q 'auth-choice.*openai' "$MAC" || fail "Mac lacks ChatGPT subscription OAuth onboarding"
rg -q 'auth-choice.*openai' "$WIN" || fail "Windows lacks ChatGPT subscription OAuth onboarding"
rg -q 'auth-choice.*anthropic-cli' "$MAC" || fail "Mac lacks Claude Code subscription onboarding"
rg -q 'auth-choice.*anthropic-cli' "$WIN" || fail "Windows lacks Claude Code subscription onboarding"
rg -q 'auth login.*--claudeai' "$MAC" || fail "Mac does not force Claude subscription login"
rg -q 'auth.*login.*claudeai' "$WIN" || fail "Windows does not force Claude subscription login"
rg -q 'security audit.*--deep' "$MAC" || fail "Mac lacks a deep security audit"
rg -q 'security.*audit.*deep' "$WIN" || fail "Windows lacks a deep security audit"
rg -q 'allowInsecureAuth.*false' "$MAC" || fail "Mac does not disable insecure Control UI auth"
rg -q 'allowInsecureAuth.*false' "$WIN" || fail "Windows does not disable insecure Control UI auth"
rg -q 'tools\.profile.*messaging' "$MAC" || fail "Mac lacks the beginner messaging-only tool profile"
rg -q 'tools\.profile.*messaging' "$WIN" || fail "Windows lacks the beginner messaging-only tool profile"

if rg -n 'openai-api-key|anthropic-api-key|auth[[:space:]]+login.*--console' "$MAC" "$WIN"; then
  fail "An API-key or Anthropic Console billing path is present in primary setup"
fi

if rg -n 'tailscale[[:space:]]+funnel|gateway\.tailscale\.mode[[:space:]]+funnel' "$MAC" "$WIN"; then
  fail "A public Tailscale Funnel path is present"
fi

if rg -n 'curl[^\n]*\|[[:space:]]*(ba)?sh|iwr[^\n]*\|[[:space:]]*iex' "$MAC" "$WIN"; then
  fail "A download-to-shell pipeline bypasses checksum verification"
fi

for file in .gitignore SECURITY.md docs/SAFE_START.md docs/THREAT_MODEL.md docs/SETUP_TIME_BENCHMARK.md; do
  [[ -f "$ROOT/$file" ]] || fail "Missing GitHub safety file: $file"
done

printf 'PASS: static checks and Mac dry-run\n'
