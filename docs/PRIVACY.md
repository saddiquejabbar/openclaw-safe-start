# Privacy and data flow

Safe Start itself has no account, analytics service, telemetry collector, or
hosted backend. Its wrapper scripts run locally. That does **not** mean the
finished system is offline or private from every provider.

## Data that leaves the computer

- AI prompts, conversation context, tool results made available to the model,
  and generated replies travel to the chosen OpenAI or Anthropic service.
- Subscription login uses the provider's browser authentication service.
- Telegram, Discord, or WhatsApp messages and account metadata pass through the
  selected chat service and OpenClaw's channel integration.
- Tailscale receives the network/account/device information needed to operate
  the tailnet and Serve connection.
- Package checks contact GitHub, npm, and optional Homebrew/WinGet/vendor
  endpoints.

Each provider controls its own logging, retention, training, legal-process,
region, and account policies. Review the policy attached to the exact account
and workspace used. Safe Start cannot change those terms.

## Data kept locally

OpenClaw can store configuration, device identity, credentials or secret
references, session state, chat history, memory, workspace files, service
metadata, and logs under the dedicated user's OpenClaw state directory. The
exact layout is version-dependent.

Safe Start adds only a small `.safe-start-managed` marker containing the wrapper
name and pinned OpenClaw version. It contains no token, account identifier, chat
content, provider choice, or password.

OpenClaw's security fixer tightens state permissions, but software running as
the same OS user—or an administrator—may still access local state. Full-disk
encryption protects data at rest only while the device is properly locked/off;
it does not protect an unlocked compromised session.

## What not to send

Do not send passwords, API keys, bot tokens, recovery codes, session cookies,
private keys, identity documents, financial/medical/legal records, confidential
work materials, or another person's data to the bot. The messaging-only tool
profile limits computer actions; it does not redact text you deliberately put
into a message.

## Deletion and revocation

Deleting local files does not erase provider or chat-service records and does
not revoke remote credentials. Follow `UNDO.md`, then separately revoke provider
sessions, bot tokens, linked devices, and Tailscale membership. Use each
service's account controls to request any supported remote-data deletion.

## Support and GitHub

Repository issues are public. Never attach local OpenClaw state, auth files,
browser data, raw transcripts, tokens, screenshots with account information, or
unredacted logs. Vulnerabilities belong in a private GitHub Security Advisory.
