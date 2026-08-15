#!/bin/bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINS_FILE="$SCRIPT_DIR/pins.env"
DRY_RUN=0
CHECK_ONLY=0
VERIFY_ONLY=0
ASSUME_DEFAULTS=0
OPENCLAW_VERSION=""
OPENCLAW_COMMIT=""
OPENCLAW_INSTALL_CLI_SH_SHA256=""
CLAUDE_CODE_VERSION=""
CLAUDE_CODE_TARBALL_SHA256=""
TEMP_FILES=()
VERIFIED_INSTALLER_PATH=""
VERIFIED_CLAUDE_PACKAGE_PATH=""
MANAGED_CLAUDE_PATH=""
SAFE_START_MARKER="$HOME/.openclaw/.safe-start-managed"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  BOLD=$'\033[1m'
  BLUE=$'\033[36m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  RESET=$'\033[0m'
else
  BOLD="" BLUE="" GREEN="" YELLOW="" RED="" RESET=""
fi

cleanup() {
  local path
  for path in "${TEMP_FILES[@]:-}"; do
    [[ -n "$path" ]] && rm -f "$path" 2>/dev/null || true
  done
}
trap cleanup EXIT

say() { printf '%s\n' "$*"; }
info() { printf '%s•%s %s\n' "$BLUE" "$RESET" "$*"; }
ok() { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
die() { printf '%s✗%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
OpenClaw Safe Start — macOS

Usage: ./install-mac.sh [option]

  --dry-run    Show the exact plan without changing anything
  --check      Diagnose an existing setup without changing anything
  --verify     Verify pinned OpenClaw and Claude Code files without running them
  --defaults   Accept recommended choices (subscription login still opens)
  --help       Show this help
EOF
}

load_pins() {
  [[ -r "$PINS_FILE" ]] || die "Missing pins file: $PINS_FILE"
  local key value
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    [[ "$key" =~ ^[A-Z0-9_]+$ ]] || die "Invalid key in pins.env: $key"
    [[ "$value" =~ ^[A-Za-z0-9._:/+-]+$ ]] || die "Invalid value in pins.env for $key"
    case "$key" in
      OPENCLAW_VERSION) OPENCLAW_VERSION="$value" ;;
      OPENCLAW_COMMIT) OPENCLAW_COMMIT="$value" ;;
      OPENCLAW_INSTALL_CLI_SH_SHA256) OPENCLAW_INSTALL_CLI_SH_SHA256="$value" ;;
      CLAUDE_CODE_VERSION) CLAUDE_CODE_VERSION="$value" ;;
      CLAUDE_CODE_TARBALL_SHA256) CLAUDE_CODE_TARBALL_SHA256="$value" ;;
    esac
  done < "$PINS_FILE"
  [[ -n "$OPENCLAW_VERSION" && -n "$OPENCLAW_COMMIT" && -n "$OPENCLAW_INSTALL_CLI_SH_SHA256" && \
     -n "$CLAUDE_CODE_VERSION" && -n "$CLAUDE_CODE_TARBALL_SHA256" ]] || \
    die "pins.env is incomplete"
}

prompt_yes_no() {
  local prompt="$1" default="${2:-yes}" reply suffix
  if [[ "$ASSUME_DEFAULTS" == "1" ]]; then
    [[ "$default" == "yes" ]]
    return
  fi
  if [[ "$default" == "yes" ]]; then suffix="[Y/n]"; else suffix="[y/N]"; fi
  read -r -p "$prompt $suffix " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

pause() {
  [[ "$ASSUME_DEFAULTS" == "1" ]] && return
  read -r -p "Press Return when ready... " _
}

print_command() {
  local arg rendered=""
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    rendered+="${rendered:+ }$arg"
  done
  printf '  %s$%s %s\n' "$BLUE" "$RESET" "$rendered"
}

run() {
  print_command "$@"
  if [[ "$DRY_RUN" == "0" ]]; then "$@"; fi
}

resolve_openclaw() {
  local node_bin
  PATH="$HOME/.openclaw/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
  for node_bin in "$HOME"/.openclaw/tools/node-v*/bin; do
    [[ -d "$node_bin" ]] && PATH="$node_bin:$PATH"
  done
  command -v openclaw 2>/dev/null || true
}

resolve_npm() {
  resolve_openclaw >/dev/null
  command -v npm 2>/dev/null || true
}

resolve_managed_claude() {
  local candidate="$HOME/.openclaw/tools/claude-code/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe"
  [[ -x "$candidate" ]] && printf '%s\n' "$candidate"
}

claude_version() {
  local command_path="$1" output
  output="$("$command_path" --version 2>/dev/null || true)"
  printf '%s\n' "$output" | sed -nE 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n 1
}

resolve_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then
    command -v tailscale
  elif [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
    printf '%s\n' /Applications/Tailscale.app/Contents/MacOS/Tailscale
  fi
}

download_verified_installer() {
  local url="$1" expected="$2" output actual
  output="$(mktemp -t openclaw-safe-start.XXXXXX)"
  TEMP_FILES+=("$output")
  info "Downloading the reviewed OpenClaw installer snapshot"
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --output "$output" "$url"
  actual="$(shasum -a 256 "$output" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "Installer checksum mismatch. Nothing was run."
  ok "Installer checksum passed (SHA-256)"
  VERIFIED_INSTALLER_PATH="$output"
}

download_verified_claude_package() {
  local output actual url
  output="$(mktemp -t openclaw-claude-code.XXXXXX)"
  TEMP_FILES+=("$output")
  url="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$CLAUDE_CODE_VERSION.tgz"
  info "Downloading the reviewed Claude Code package"
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --output "$output" "$url"
  actual="$(shasum -a 256 "$output" | awk '{print $1}')"
  [[ "$actual" == "$CLAUDE_CODE_TARBALL_SHA256" ]] || \
    die "Claude Code package checksum mismatch. Nothing was run."
  ok "Claude Code package checksum passed (SHA-256)"
  VERIFIED_CLAUDE_PACKAGE_PATH="$output"
}

install_managed_claude_code() {
  local claude current npm prefix
  prefix="$HOME/.openclaw/tools/claude-code"
  claude="$(resolve_managed_claude)"
  current=""
  [[ -n "$claude" ]] && current="$(claude_version "$claude")"
  if [[ "$current" != "$CLAUDE_CODE_VERSION" ]]; then
    npm="$(resolve_npm)"
    [[ -n "$npm" ]] || die "The OpenClaw Node installation did not provide npm. Rerun installation, then try again."
    download_verified_claude_package
    info "Installing private Claude Code $CLAUDE_CODE_VERSION for OpenClaw"
    run "$npm" install --global --prefix "$prefix" "$VERIFIED_CLAUDE_PACKAGE_PATH"
    claude="$(resolve_managed_claude)"
    [[ -n "$claude" ]] || die "Claude Code installed, but its native executable was not found."
    current="$(claude_version "$claude")"
    [[ "$current" == "$CLAUDE_CODE_VERSION" ]] || \
      die "Claude Code version verification failed (expected $CLAUDE_CODE_VERSION)."
  fi
  mkdir -p "$HOME/.openclaw/bin"
  chmod 700 "$HOME/.openclaw" "$HOME/.openclaw/bin" 2>/dev/null || true
  ln -sfn "$claude" "$HOME/.openclaw/bin/claude"
  MANAGED_CLAUDE_PATH="$claude"
  ok "Claude Code $CLAUDE_CODE_VERSION is ready"
}

security_preflight() {
  local name path found=0 unmanaged=0
  local blocked_env=(
    OPENAI_API_KEY ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN
    CLAUDE_CODE_API_KEY GEMINI_API_KEY GOOGLE_API_KEY XAI_API_KEY
    GROQ_API_KEY MISTRAL_API_KEY DISCORD_BOT_TOKEN TELEGRAM_BOT_TOKEN
    SLACK_BOT_TOKEN SLACK_APP_TOKEN OPENCLAW_GATEWAY_TOKEN
    OPENCLAW_GATEWAY_PASSWORD AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    AZURE_CLIENT_SECRET GITHUB_TOKEN GH_TOKEN NPM_TOKEN NODE_AUTH_TOKEN
    DATABASE_URL
  )

  say "${BOLD}Safe-start prerequisite${RESET}"
  cat <<'EOF'
Use a fresh dedicated macOS user account for this bot. It should have:
  - a strong macOS login password and FileVault enabled;
  - no personal files, browser sync, password manager, email, or cloud drive;
  - no copied API keys, shell profiles, SSH keys, or credentials; and
  - a fresh browser profile used only for ChatGPT or Claude subscription login.

The installer never needs your provider password in Terminal. Enter it only on
the provider's HTTPS browser page. Do not paste secrets into AI chats.
EOF

  for name in "${blocked_env[@]}"; do
    if printenv "$name" >/dev/null 2>&1; then
      warn "Secret-bearing environment variable detected: $name (value was not read or printed)"
      found=1
    fi
  done
  [[ "$found" == "0" ]] || die "Open a clean Terminal in the fresh user account with those variables unset, then rerun."

  if [[ ! -f "$SAFE_START_MARKER" ]]; then
    for path in \
      "$HOME/.openclaw" "$HOME/.claude" "$HOME/.codex/auth.json" \
      "$HOME/.aws/credentials" "$HOME/.config/gh/hosts.yml" "$HOME/.ssh"; do
      if [[ -e "$path" ]]; then
        warn "Existing credential-capable state detected: $path (contents were not read)"
        unmanaged=1
      fi
    done
  fi
  if [[ "$unmanaged" == "1" ]]; then
    prompt_yes_no "Continue with existing state? This is not the recommended safe start." no || \
      die "Stopped. Use a fresh dedicated macOS user account or review and remove the old state first."
  fi

  prompt_yes_no "I confirm this is a fresh dedicated account with no imported personal credentials." no || \
    die "Stopped. Complete the safe-start checklist in docs/SAFE_START.md, then rerun."
}

mark_safe_start() {
  mkdir -p "$HOME/.openclaw"
  chmod 700 "$HOME/.openclaw" 2>/dev/null || true
  printf 'managed_by=openclaw-safe-start\nsafe_start_version=0.1.0-alpha\nopenclaw_version=%s\n' \
    "$OPENCLAW_VERSION" > "$SAFE_START_MARKER"
  chmod 600 "$SAFE_START_MARKER" 2>/dev/null || true
}

harden_openclaw() {
  local claw
  claw="$(resolve_openclaw)"
  say ""
  say "${BOLD}Applying the beginner safety baseline${RESET}"
  run "$claw" config set gateway.mode '"local"' --strict-json
  run "$claw" config set gateway.bind '"loopback"' --strict-json
  run "$claw" config set gateway.auth.mode '"token"' --strict-json
  run "$claw" config set gateway.auth.allowTailscale false --strict-json
  run "$claw" config set gateway.auth.rateLimit.maxAttempts 10 --strict-json
  run "$claw" config set gateway.auth.rateLimit.windowMs 60000 --strict-json
  run "$claw" config set gateway.auth.rateLimit.lockoutMs 300000 --strict-json
  run "$claw" config set gateway.controlUi.allowInsecureAuth false --strict-json
  run "$claw" config set gateway.controlUi.dangerouslyDisableDeviceAuth false --strict-json
  run "$claw" config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback false --strict-json
  run "$claw" config set gateway.allowRealIpFallback false --strict-json
  run "$claw" config set session.dmScope '"per-channel-peer"' --strict-json
  run "$claw" config set tools.profile '"messaging"' --strict-json
  run "$claw" config set tools.deny '["group:automation","group:runtime","group:fs","sessions_spawn","sessions_send"]' --strict-json
  run "$claw" config set tools.fs.workspaceOnly true --strict-json
  run "$claw" config set tools.exec.mode '"deny"' --strict-json
  run "$claw" config set tools.exec.applyPatch.enabled false --strict-json
  run "$claw" config set tools.elevated.enabled false --strict-json
  if [[ "$DRY_RUN" == "0" ]]; then
    info "Generating the Gateway token inside OpenClaw without displaying it"
    "$claw" doctor --generate-gateway-token >/dev/null
    "$claw" security audit --fix >/dev/null
    chmod 700 "$HOME/.openclaw" 2>/dev/null || true
    [[ -f "$HOME/.openclaw/openclaw.json" ]] && chmod 600 "$HOME/.openclaw/openclaw.json" 2>/dev/null || true
  fi
  mark_safe_start
  run "$claw" gateway install
  run "$claw" gateway restart
  ok "Loopback, token auth, rate limiting, private files, isolated DMs, and messaging-only tools are set"
}

print_plan() {
  cat <<EOF

${BOLD}OpenClaw Safe Start — safe dry run${RESET}

Pinned OpenClaw: $OPENCLAW_VERSION
Pinned upstream commit: $OPENCLAW_COMMIT

The guided run will:
  1. Confirm a fresh dedicated computer account with no imported credentials.
  2. Refuse to run while common API-key or bot-token variables are present.
  3. Verify the official installer from an immutable commit, then install
     exactly OpenClaw $OPENCLAW_VERSION.
  4. Choose ChatGPT subscription (default) or Claude Code subscription, sign
     in only through the provider's browser page, and test a real reply.
  5. Apply loopback-only networking, token auth, rate limiting, private file
     permissions, separate DM sessions, and a messaging-only tool profile.
  6. Open WebChat so the first conversation can start immediately.
  7. Offer a dedicated Telegram or Discord bot, or a separate WhatsApp account.
  8. Offer private Tailscale Serve, plugged-in wake settings, and optional SSH.
  9. Run health, channel, pin, and deep security checks.

No AI API key is needed or requested on the primary path. Provider passwords
belong only in provider HTTPS pages; bot tokens use OpenClaw's masked prompts.
EOF
}

check_setup() {
  local claw tail status=0 version
  say "${BOLD}OpenClaw Safe Start — diagnostics${RESET}"
  claw="$(resolve_openclaw)"
  if [[ -z "$claw" ]]; then
    warn "OpenClaw is not on PATH"
    status=1
  else
    version="$($claw --version 2>/dev/null || true)"
    ok "OpenClaw found: ${version:-version unavailable}"
    "$claw" doctor --non-interactive || status=1
    "$claw" gateway status --json || status=1
    "$claw" channels status --probe || status=1
    "$claw" security audit --deep || status=1
  fi
  tail="$(resolve_tailscale)"
  if [[ -z "$tail" ]]; then
    warn "Tailscale is not installed"
  elif "$tail" status >/dev/null 2>&1; then
    ok "Tailscale is connected"
  else
    warn "Tailscale is installed but not connected"
  fi
  return "$status"
}

install_openclaw() {
  local claw current installer url
  claw="$(resolve_openclaw)"
  if [[ -n "$claw" ]]; then
    current="$($claw --version 2>/dev/null || true)"
    if [[ "$current" == *"$OPENCLAW_VERSION"* ]]; then
      ok "OpenClaw $OPENCLAW_VERSION is already installed"
      return
    fi
    warn "You already run ${current:-an unknown OpenClaw version}. This kit was reviewed against $OPENCLAW_VERSION."
    if ! prompt_yes_no "Replace it with the reviewed pinned version?" no; then
      ok "Keeping the existing OpenClaw version. Nothing was changed."
      exit 0
    fi
  fi
  url="https://raw.githubusercontent.com/openclaw/openclaw/$OPENCLAW_COMMIT/scripts/install-cli.sh"
  download_verified_installer "$url" "$OPENCLAW_INSTALL_CLI_SH_SHA256"
  installer="$VERIFIED_INSTALLER_PATH"
  run /bin/bash "$installer" --version "$OPENCLAW_VERSION" --no-onboard
  claw="$(resolve_openclaw)"
  [[ -n "$claw" ]] || die "OpenClaw installed but is not on PATH. Open a new Terminal and run this script again."
  current="$($claw --version 2>/dev/null || true)"
  [[ "$current" == *"$OPENCLAW_VERSION"* ]] || \
    die "OpenClaw installed, but version verification failed (expected $OPENCLAW_VERSION)."
  ok "Pinned OpenClaw is ready"
}

run_onboarding() {
  local claw claude choice config="$HOME/.openclaw/openclaw.json"
  claw="$(resolve_openclaw)"
  if [[ -f "$config" ]]; then
    prompt_yes_no "An OpenClaw setup already exists. Run onboarding again?" no || {
      ok "Keeping the existing model and agent setup"
      run "$claw" gateway install
      return
    }
  fi
  cat <<'EOF'

Choose the AI subscription you already pay for:

  1) ChatGPT Plus/Pro/Business — recommended and simplest
  2) Claude Code with a Claude Pro or Max subscription

This primary setup never asks for an AI API key or enables pay-per-token API
billing. Sign in only on the provider's HTTPS browser page. The provider may
remember the login in this dedicated browser profile; do not enable browser
sync or import a password vault.
EOF
  if [[ "$ASSUME_DEFAULTS" == "1" ]]; then choice="1"; else read -r -p "Choose [1-2, default 1]: " choice; fi
  choice="${choice:-1}"
  case "$choice" in
    1)
      say "Sign in with the ChatGPT account that owns the subscription. Do not choose an API-key route."
      run "$claw" onboard --auth-choice openai --install-daemon --skip-search --skip-channels --skip-skills
      ;;
    2)
      install_managed_claude_code
      claude="$MANAGED_CLAUDE_PATH"
      say "Choose the Claude.ai Pro/Max subscription account, not Anthropic Console billing."
      run "$claude" auth login --claudeai
      "$claude" auth status --text >/dev/null 2>&1 || die "Claude Code subscription sign-in did not complete."
      run "$claw" onboard --auth-choice anthropic-cli --install-daemon --skip-search --skip-channels --skip-skills
      run "$claw" config set agents.defaults.cliBackends.claude-cli.command "$claude"
      ;;
    *) die "Choose 1 for ChatGPT or 2 for Claude Code." ;;
  esac
  run "$claw" gateway install
  run "$claw" gateway restart
}

install_tailscale() {
  local tail
  tail="$(resolve_tailscale)"
  if [[ -z "$tail" ]]; then
    if command -v brew >/dev/null 2>&1; then
      info "Installing the official Tailscale macOS app"
      run brew install --cask tailscale
    else
      warn "Homebrew is unavailable. Opening Tailscale's official Mac download page."
      run open "https://tailscale.com/download/mac"
      say "Install Tailscale, open it, and sign in with your preferred account."
      pause
    fi
    run open -a Tailscale
    tail="$(resolve_tailscale)"
  fi
  if [[ -z "$tail" ]]; then
    warn "Tailscale's command tool is not available yet. Finish app setup, then rerun this kit."
    return 1
  fi
  if ! "$tail" status >/dev/null 2>&1; then
    say "A browser may open. Sign in and approve this Mac in your tailnet."
    run "$tail" up
  fi
  "$tail" status >/dev/null 2>&1 || {
    warn "Tailscale is not connected, so private remote WebChat was not enabled."
    return 1
  }
  ok "Tailscale is connected"
  return 0
}

configure_private_remote_access() {
  local claw
  claw="$(resolve_openclaw)"
  say ""
  say "${BOLD}Private remote access${RESET}"
  say "Tailscale Serve makes WebChat reachable only from devices in your tailnet."
  say "It does not expose OpenClaw to the public internet."
  if prompt_yes_no "Set up private Tailscale access?" yes; then
    if install_tailscale; then
      run "$claw" config set gateway.bind loopback
      run "$claw" config set gateway.auth.mode token
      run "$claw" config set gateway.auth.allowTailscale true --strict-json
      run "$claw" config set gateway.controlUi.allowInsecureAuth false --strict-json
      run "$claw" config set gateway.tailscale.mode serve
      run "$claw" gateway restart
      ok "Tailscale Serve is configured; public Funnel remains disabled"
    fi
  fi
}

configure_always_on() {
  say ""
  say "${BOLD}Keep the bot alive${RESET}"
  say "OpenClaw already has a LaunchAgent that restarts it after a crash."
  say "The next settings keep this Mac awake while plugged into power."
  if prompt_yes_no "Keep the Mac awake on its power adapter?" yes; then
    run sudo pmset -c sleep 0
    run sudo systemsetup -setwakeonnetworkaccess on
    ok "AC-only always-on settings applied; battery sleep was left unchanged"
  fi
  if prompt_yes_no "Is this a dedicated desktop Mac that should restart after a power cut?" no; then
    run sudo systemsetup -setrestartpowerfailure on
  fi
  warn "After a full restart, macOS still needs a user login before this per-user OpenClaw service starts."
}

configure_ssh() {
  say ""
  say "${BOLD}Optional terminal access (SSH)${RESET}"
  say "Tailscale Serve is enough for WebChat. SSH is only for remote administration."
  warn "macOS Remote Login can also listen on trusted local networks, not only Tailscale."
  if prompt_yes_no "Enable macOS Remote Login (SSH)?" no; then
    run sudo systemsetup -setremotelogin on
    say "In System Settings → General → Sharing → Remote Login, choose 'Only these users'."
    say "Connect from another Tailscale device with: ssh $USER@<this-mac-name>"
  fi
}

open_first_chat() {
  local claw
  claw="$(resolve_openclaw)"
  say ""
  say "${BOLD}Your first chat${RESET}"
  say "Opening OpenClaw's built-in WebChat. It needs no extra account or token."
  run "$claw" dashboard
}

add_chat_channel() {
  local claw choice code
  claw="$(resolve_openclaw)"
  cat <<'EOF'

Add a separate phone-friendly bot account now:
  1) Telegram — recommended; create a new dedicated BotFather bot
  2) Discord — create a new dedicated bot in the Developer Portal
  3) WhatsApp — separate number/account only; never link a personal account
  4) Not now — keep using WebChat
EOF
  if [[ "$ASSUME_DEFAULTS" == "1" ]]; then choice="4"; else read -r -p "Choose [1-4, default 1]: " choice; fi
  choice="${choice:-1}"
  case "$choice" in
    1)
      cat <<'EOF'

Telegram setup:
  1. Open https://t.me/BotFather and confirm the handle is exactly @BotFather.
  2. Send /newbot, choose a name and username, then copy the bot token.
  3. Return here. OpenClaw's masked wizard will ask for the token.
EOF
      run open "https://t.me/BotFather"
      pause
      run "$claw" channels add --channel telegram
      run "$claw" gateway restart
      say "Send /start to your new bot in Telegram, then return here."
      pause
      run "$claw" pairing list telegram
      if [[ "$ASSUME_DEFAULTS" == "0" ]]; then
        read -r -p "Pairing code shown above (leave blank to approve later): " code
        if [[ -n "$code" ]]; then
          [[ "$code" =~ ^[A-Za-z0-9_-]+$ ]] || die "Pairing code contains unexpected characters."
          run "$claw" pairing approve telegram "$code"
        fi
      fi
      ;;
    2)
      cat <<'EOF'

Discord setup:
  1. Open https://discord.com/developers/applications and create an application.
  2. Open Bot, create/reset the token, and copy it.
  3. Enable only the intents OpenClaw's wizard requests.
  4. Return here and use the masked setup wizard.
EOF
      run open "https://discord.com/developers/applications"
      pause
      run "$claw" channels add --channel discord
      run "$claw" gateway restart
      ;;
    3)
      warn "Do not link your everyday WhatsApp account. Use a separate account with no personal chat history."
      prompt_yes_no "I have a separate WhatsApp account for this bot." no || die "WhatsApp setup stopped; WebChat is still available."
      say "OpenClaw will install its official WhatsApp plugin and guide QR login."
      run "$claw" channels add --channel whatsapp
      run "$claw" channels login --channel whatsapp
      run "$claw" gateway restart
      ;;
    4) ok "WebChat remains the active chat interface" ;;
    *) die "Choose a number from 1 to 4." ;;
  esac
}

final_checks() {
  local claw failed=0
  claw="$(resolve_openclaw)"
  say ""
  say "${BOLD}Final checks${RESET}"
  run "$claw" doctor --non-interactive || failed=1
  run "$claw" gateway status --json || failed=1
  run "$claw" channels status --probe || failed=1
  run "$claw" security audit --deep || failed=1
  if [[ "$failed" == "1" ]]; then
    warn "First-chat setup finished, but at least one final check needs attention. Run --check after using the troubleshooting guide."
  else
    ok "Setup is complete"
  fi
  say ""
  say "Chat now: openclaw dashboard"
  say "Diagnose later: $SCRIPT_DIR/install-mac.sh --check"
  say "Troubleshooting: $SCRIPT_DIR/docs/TROUBLESHOOTING.md"
}

main() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --check) CHECK_ONLY=1 ;;
      --verify) VERIFY_ONLY=1 ;;
      --defaults) ASSUME_DEFAULTS=1 ;;
      --help|-h) usage; exit 0 ;;
      *) usage; die "Unknown option: $arg" ;;
    esac
  done
  load_pins
  [[ "$(uname -s)" == "Darwin" ]] || die "This script is for macOS. Use install-windows.ps1 on Windows."
  if [[ "$DRY_RUN" == "1" ]]; then print_plan; exit 0; fi
  if [[ "$VERIFY_ONLY" == "1" ]]; then
    download_verified_installer \
      "https://raw.githubusercontent.com/openclaw/openclaw/$OPENCLAW_COMMIT/scripts/install-cli.sh" \
      "$OPENCLAW_INSTALL_CLI_SH_SHA256"
    download_verified_claude_package
    ok "Pinned Mac and Claude Code bootstrap files verified and were not run"
    exit 0
  fi
  if [[ "$CHECK_ONLY" == "1" ]]; then check_setup; exit $?; fi
  [[ -t 0 ]] || die "Run this installer in an interactive Terminal window."

  say "${BOLD}OpenClaw Safe Start${RESET}"
  say "A short, reviewed path from a new Mac to a working AI chat."
  say "Pinned OpenClaw: $OPENCLAW_VERSION"
  say ""
  prompt_yes_no "Show the dry-run plan before starting?" yes && print_plan
  pause

  security_preflight
  install_openclaw
  run_onboarding
  harden_openclaw
  open_first_chat
  add_chat_channel
  configure_private_remote_access
  configure_always_on
  configure_ssh
  final_checks
}

main "$@"
