# Threat model

## Security goal

Help a beginner create a private, subscription-backed OpenClaw chat without
accidentally exposing personal credentials, enabling API billing, publishing a
Gateway, or giving an untrusted chat sender control of the computer.

## Protected assets

- AI subscription sessions and provider account access.
- Gateway authentication material and device identities.
- Chat bot tokens and paired-user authorization.
- Conversation content and OpenClaw memory/state.
- The host computer, local files, network, microphone/camera, and other devices.
- The user's time, subscription limits, and reputation on connected chat
  services.

## Trust boundaries

1. This repository's reviewed local wrapper scripts.
2. Pinned OpenClaw and Claude Code bootstrap packages.
3. Live transitive packages, operating-system package managers, and updates.
4. OpenAI or Anthropic hosted authentication and inference.
5. OpenClaw's local Gateway and credential/state storage.
6. Optional Tailscale and chat-service infrastructure.
7. Every person or bot able to send a message to a connected channel.

No boundary is assumed perfect. The wrapper verifies directly consumed remote
files but cannot attest every upstream dependency or hosted service.

## Threats and controls

| Threat | Primary controls | Residual risk |
|---|---|---|
| Old secrets are inherited from the daily account | Dedicated fresh OS account; secret-variable name check; unmanaged-config warning | The installer cannot detect browser sync, Keychain, Credential Manager, backups, or every custom secret store |
| API billing is enabled accidentally | Only `openai` subscription OAuth and Claude `--claudeai` appear in primary setup | Provider plan eligibility, limits, and UI wording may change |
| Download is replaced | Immutable OpenClaw commit, exact versions, SHA-256 before execution, independent pin verifier | Maintainer review may miss malicious upstream code; transitive platform packages remain live |
| Gateway becomes public | Loopback bind; optional Tailscale Serve; no Funnel or port forwarding | A compromised host or tailnet member may still reach trusted surfaces |
| Gateway token is stolen or brute-forced | Token generated inside OpenClaw; private state permissions; auth rate limit; no display by wrapper | Malware running as the same OS user can read state or control the process |
| Prompt injection triggers host actions | Messaging-only profile; runtime/filesystem/automation/session/elevated tools denied | Model output can still mislead a human or disclose information supplied in chat |
| Chat strangers share one context or control the bot | Per-channel-peer DM scope; bot pairing; dedicated bot identities | Misconfigured channel permissions or an approved malicious sender remains dangerous |
| Browser login is phished | Fresh browser profile; official HTTPS-only instruction; passwords never accepted in terminal | DNS, browser, provider, or user judgment can still fail |
| Logs or support leak secrets | No secret CLI arguments; masked channel prompts; redaction instructions; `.gitignore` | Upstream tools or screen recordings may display sensitive data |
| Remote administration expands attack surface | SSH off by default; Tailscale-only Windows firewall option; Serve is sufficient for chat | macOS Remote Login can also listen on trusted LANs; admin choices remain consequential |
| AI gives unsafe or false advice | Clear limitations; security-first tool denial; user confirmation for system changes | The model can hallucinate, manipulate, or produce harmful content |

## Explicit non-goals

- Protecting against a malicious administrator, kernel compromise, or malware
  running as the dedicated OS user.
- Providing anonymity from AI, chat, network, or operating-system providers.
- Making provider subscriptions unlimited or guaranteeing a specific model.
- Safely automating finance, healthcare, legal decisions, credential handling,
  or critical infrastructure.
- Turning the beginner profile into an autonomous coding or computer-control
  agent.
- Replacing upstream security reviews or incident response.

## Release invariants

A release is blocked if any primary path:

- accepts an AI API key;
- prints or places a secret in a process argument controlled by this wrapper;
- binds the Gateway beyond loopback;
- offers Tailscale Funnel or public port forwarding;
- enables runtime, filesystem, automation, patching, session-spawning, or
  elevated tools;
- uses an unverified directly executed remote bootstrap;
- skips the deep security audit; or
- proceeds after detecting a known secret-bearing environment variable.

Review this threat model whenever a provider, channel, tool, network mode,
secret source, or privilege requirement changes.
