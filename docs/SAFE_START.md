# Safe-start checklist

Complete this checklist before running the installer. The design assumes the
bot lives in a clean, dedicated computer account—not the profile used for your
daily work, personal messages, banking, photos, or password manager.

## 1. Create a dedicated OS user

Create a new local user named something recognizable, such as `openclaw-bot`.
Use a strong unique login password or Windows Hello. “No passwords or
credentials” means **do not import personal credentials**; a passwordless OS
account is unsafe.

Prefer a standard/non-administrator daily account. Keep access to an
administrator account only for the few optional system changes that require
approval.

Enable full-disk encryption before storing conversations:

- Mac: FileVault.
- Windows: Device Encryption or BitLocker.

Install current operating-system security updates and enable the built-in
firewall and automatic updates.

## 2. Keep the account empty

Do not enable or import:

- iCloud Drive, OneDrive, Dropbox, Google Drive, or another personal sync tool;
- browser sync, saved passwords, extensions, or an existing browser profile;
- a password-manager vault;
- personal email, calendars, contacts, photos, or messages;
- SSH/private keys, cloud credentials, developer dotfiles, or shell profiles;
- an existing `.openclaw`, `.claude`, `.codex`, `.env`, or credential folder;
  or
- backups restored from another user or computer.

The installer does not search your files or read credential contents. It stops
when it detects common secret-bearing environment variable **names**, and it
warns when an unmanaged OpenClaw configuration exists.

## 3. Prepare one AI subscription

Use one account you already pay for:

- ChatGPT Plus/Pro or an eligible workspace plan; or
- Claude Pro/Max with Claude Code access.

Create a new browser profile with sync disabled. Use it only to open the
provider's official HTTPS login page when the installer asks. The provider may
store a browser session in this dedicated profile; that is expected. Never type
the provider password, recovery code, session cookie, or API key into Terminal,
PowerShell, OpenClaw chat, an issue, or a support message.

If the subscription contains valuable personal chat history, consider whether
the provider offers a separate workspace/account arrangement that fits its
terms. Do not create duplicate or shared accounts in violation of provider
rules.

## 4. Prepare optional chat and remote accounts

Add these only after WebChat works:

- Telegram: create a new bot through the verified `@BotFather`; never reuse a
  bot token from another project.
- Discord: create a new application and bot with only the requested intents and
  permissions.
- WhatsApp: use a separate account/number with no personal conversation history.
- Tailscale: use a tailnet whose members and devices you trust. Remove old or
  unknown devices before enabling Serve.

Bot tokens are credentials. Enter them only into OpenClaw's masked official
channel wizard. If a token is ever shown in a terminal recording, issue,
screenshot, AI chat, or log, revoke it immediately and create a new one.

## 5. Know the default restrictions

Safe Start intentionally creates a chat bot, not a general-purpose autonomous
computer operator. It blocks filesystem, runtime, automation, patching,
session-spawning, and elevated tools. It keeps the Gateway on loopback, uses
token authentication and rate limiting, isolates direct-message sessions, and
does not offer public internet exposure.

Advanced tools can be enabled later only after the owner understands the data,
command-execution, prompt-injection, and approval risks. That expansion is
outside the beginner flow.

## Stop and ask for help if

- a prompt asks for an OpenAI or Anthropic API key;
- a provider password is requested in Terminal or PowerShell;
- the checksum check fails;
- the installer detects a secret environment variable;
- the browser domain is not the provider's expected official HTTPS domain;
- a chat wizard requests broader permissions than documented;
- Tailscale proposes public Funnel rather than private Serve; or
- a security audit reports a critical finding.

Share only redacted error wording. Never share local state or credential files.
