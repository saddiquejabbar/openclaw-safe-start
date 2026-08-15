# OpenClaw Safe Start

A security-first, terminal-guided installer that helps a beginner go from a
fresh Mac or Windows account to a working OpenClaw chat using an existing
ChatGPT or Claude subscription.

The shortest path is deliberately narrow:

1. confirm a clean, dedicated computer account;
2. install a pinned and checksum-verified OpenClaw release;
3. sign in through ChatGPT subscription OAuth or Claude Code subscription
   login—never an AI API key;
4. apply a locked-down beginner profile; and
5. open the built-in WebChat for the first conversation.

Optional Telegram, Discord, WhatsApp, Tailscale, wake settings, and SSH come
after the first AI route works.

> [!IMPORTANT]
> “Fresh account” does **not** mean a passwordless computer. Use a strong local
> login password or Windows Hello, full-disk encryption, and a new dedicated OS
> user profile with no imported personal credentials. Read the
> [Safe-start checklist](docs/SAFE_START.md) before running the installer.

## What this is—and is not

OpenClaw already has the strongest application installer and onboarding flow.
Safe Start wraps that official flow with fewer choices, reproducible bootstrap
checks, subscription-only authentication, conservative network settings, and
beginner-focused recovery guidance. It does not fork or redistribute OpenClaw.

This project is independent community software. It is not affiliated with or
endorsed by OpenClaw, OpenAI, Anthropic, Tailscale, Telegram, Discord, Meta, or
Microsoft.

## Fast start

### Mac

Open Terminal in this folder and preview the complete plan:

```bash
chmod +x install-mac.sh
./install-mac.sh --dry-run
```

Then run the guided setup:

```bash
./install-mac.sh
```

### Windows

Right-click the folder, choose **Open in Terminal**, and preview the plan:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -DryRun
```

Then run the guided setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

Administrator access is not required for the basic ChatGPT/WebChat path.
Claude Code may need approval to install Git for Windows. OpenSSH and Tailscale
unattended mode need administrator access only when selected.

## Prerequisites

- A supported Mac or Windows computer with current security updates.
- A newly created, dedicated OS user profile with no personal files, browser
  sync, password vault, email, cloud drive, SSH keys, or copied credentials.
- Full-disk encryption: FileVault on Mac or Device Encryption/BitLocker on
  Windows.
- A fresh browser profile with sync disabled.
- One existing subscription:
  - ChatGPT Plus, Pro, or an eligible workspace plan; or
  - Claude Pro or Max with Claude Code access.
- Internet access to the official GitHub, npm, provider, and optional Tailscale
  or chat-service endpoints.

The installer refuses to start when common API-key or bot-token environment
variables are present. It checks variable names only; it never reads or prints
their values.

## Safe defaults

- Gateway binds to loopback only.
- Stable token authentication is generated inside OpenClaw and never displayed
  by this wrapper.
- Failed-auth rate limiting is explicit.
- Insecure Control UI and dangerous fallback switches are disabled.
- Direct messages receive separate sessions per channel and sender.
- The beginner tool profile is messaging-only; runtime, filesystem, automation,
  session-spawning, patching, and elevated execution are denied.
- State permissions are tightened by OpenClaw's own security fixer.
- Tailscale **Serve** is optional; public Funnel is never offered.
- SSH is off by default.
- Telegram and Discord require dedicated bot identities. WhatsApp is offered
  only for a separate account with no personal history.
- A deep OpenClaw security audit runs at the end.

These controls reduce risk; they do not make an AI agent infallible. Never send
passwords, recovery codes, financial information, private keys, or confidential
documents to the bot. See the [threat model](docs/THREAT_MODEL.md).

## AI subscription paths

| Choice | Sign-in | API key needed? | Default |
|---|---|---:|---:|
| ChatGPT subscription | OpenAI browser OAuth | No | Yes |
| Claude Code subscription | `claude auth login --claudeai` | No | No |

The Claude path installs a private, pinned Claude Code package under the
OpenClaw user directory. Provider passwords are entered only on provider HTTPS
pages, never in Terminal or PowerShell.

See [AI and chat setup](docs/AI_AND_CHAT_SETUP.md) for the exact flow and
optional chat-account instructions.

## Setup-time goal

The product goal is to reduce **active beginner setup time by 90%** compared
with a defined manual baseline, while preserving comprehension and safety. That
is a target, not yet a verified claim. Public marketing must not say “90%
faster” until the cross-platform study in
[SETUP_TIME_BENCHMARK.md](docs/SETUP_TIME_BENCHMARK.md) passes.

## Verification and support

Mac:

```bash
./install-mac.sh --check
./install-mac.sh --verify
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Check
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Verify
```

Verify mode downloads the pinned OpenClaw bootstrap and Claude Code wrapper
package, checks SHA-256, and runs neither file. Diagnostic mode checks the local
installation. Start with [Troubleshooting](docs/TROUBLESHOOTING.md) and redact
all tokens, account names, paths, and chat content before sharing output.

## Determinism and supply chain

`pins.env` contains the reviewed OpenClaw version, immutable upstream commit,
pinned Claude Code version, exact bootstrap/package digests, review date, and
scope. `tools/verify-pins.sh` independently reproduces every consumed pin.

A checksum mismatch stops before downloaded code executes. Hosted OAuth,
operating-system packages, Tailscale, npm platform packages, subscription model
availability, and transitive dependencies remain live services; this is a
repeatable bootstrap, not a bit-for-bit machine image.

## Project status

This is a pre-release security-focused implementation. Static checks, Mac
syntax/dry-run, pinned-download verification, and GitHub Actions are included.
Both subscription paths still require clean-machine acceptance testing on the
release matrix before the first stable release.

- [Design and release gates](docs/DESIGN.md)
- [Safe-start checklist](docs/SAFE_START.md)
- [Threat model](docs/THREAT_MODEL.md)
- [Privacy and data flow](docs/PRIVACY.md)
- [Security policy](SECURITY.md)
- [Undo guide](docs/UNDO.md)
- [Independent review prompt](docs/CRITIQUE_PROMPT.md)

## Contributing and license

Security reports belong in a private GitHub Security Advisory, not a public
issue. Other contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md).

Released under the [MIT License](LICENSE). Third-party software retains its own
licenses and terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
