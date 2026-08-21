# OpenClaw Safe Start

A security-first guided setup for OpenClaw on Mac and Windows using an existing ChatGPT or Claude subscription—no AI API key required.

> [!WARNING]
> This is alpha software. Use a new, dedicated OS account with a strong login password and full-disk encryption. Read the [safe-start checklist](docs/SAFE_START.md) before installing.

## Start

Download and extract this repository, then open Terminal in the folder.

### Mac

```bash
chmod +x install-mac.sh
./install-mac.sh --dry-run
./install-mac.sh
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

The basic ChatGPT + WebChat path does not need administrator access. Some optional features do.

## What it does

- Verifies a pinned OpenClaw release before running it.
- Uses official subscription sign-in instead of AI API keys.
- Keeps the gateway local, applies a messaging-only beginner profile, and leaves SSH off by default.
- Runs a deep OpenClaw security audit after setup.

Optional Telegram, Discord, WhatsApp, Tailscale, wake, and SSH setup comes after the first AI route works.

These safeguards reduce risk; they do not make an AI agent infallible. Never send passwords, recovery codes, private keys, financial details, or confidential documents to a bot.

## Help and details

[AI and chat setup](docs/AI_AND_CHAT_SETUP.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Threat model](docs/THREAT_MODEL.md) · [Privacy](docs/PRIVACY.md) · [Undo](docs/UNDO.md)

**Status:** v0.1.0-alpha. Clean-machine acceptance testing is still required before a stable release.

Community software; not affiliated with OpenClaw, OpenAI, Anthropic, or the optional service providers. [MIT License](LICENSE).
