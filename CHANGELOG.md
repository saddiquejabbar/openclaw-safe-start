# Changelog

All notable release changes will be documented here.

## 0.1.0-alpha - 2026-08-15

- Added guided Mac and Windows installation around a pinned OpenClaw release.
- Made ChatGPT subscription OAuth the default and Claude Code subscription
  login the only primary alternative; removed AI API keys from beginner setup.
- Added pinned, checksum-verified private Claude Code installation.
- Added a fresh dedicated-account prerequisite and secret-variable/state checks
  that inspect names/paths without reading values or contents.
- Added loopback, token auth, rate limit, Control UI, DM isolation, private state,
  and messaging-only tool hardening.
- Kept Tailscale Serve optional and prohibited public Funnel.
- Added dedicated Telegram/Discord guidance and separate-account WhatsApp rules.
- Added threat model, privacy guide, undo guide, private security reporting,
  independent critique prompt, release matrix, pin reproducer, CI, secret scan,
  and setup-time benchmark protocol.

This alpha is not a stable release. Clean-machine subscription-path acceptance
testing remains required.
