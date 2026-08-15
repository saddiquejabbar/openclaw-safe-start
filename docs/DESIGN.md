# Design and release gates

## Product objective

Minimize active beginner time from a clean dedicated computer account to one
verified OpenClaw WebChat reply, without copying credentials, enabling API
billing, exposing the Gateway publicly, or giving chat messages host-control
tools.

The order is intentional: safety prerequisite, verified application install,
subscription login, security baseline, first WebChat, then optional integrations.

## Architecture

Safe Start is a narrow wrapper, not an OpenClaw fork:

1. `pins.env` selects an immutable OpenClaw commit and version, exact Claude
   Code version, and bootstrap/package checksums.
2. Platform scripts download only the matching official bootstrap and optional
   Claude wrapper, verify SHA-256, then execute/install the verified file.
3. Mac uses OpenClaw's local-prefix install under `~/.openclaw`; Windows uses
   the official native PowerShell path.
4. Authentication is exactly one of:
   - OpenClaw `--auth-choice openai` for ChatGPT subscription OAuth; or
   - pinned Claude Code `--claudeai` followed by OpenClaw `anthropic-cli` adoption.
5. OpenClaw owns credential storage, provider verification, and the managed
   Gateway service. This wrapper never receives provider passwords or tokens.
6. The wrapper applies a conservative configuration using OpenClaw's validated
   config CLI, generates the Gateway token internally, runs OpenClaw's safe
   permission fixer, and records only a non-secret management marker.
7. WebChat opens before chat channels, remote access, wake, or SSH choices.
8. Tailscale Serve is the only optional remote Web exposure mode.

## Beginner safety profile

The baseline config enforces:

- local Gateway mode and loopback bind;
- token authentication, explicit failed-auth rate limiting, and no insecure or
  dangerous Control UI fallbacks;
- Tailscale identity disabled until Serve is intentionally selected;
- per-channel-peer DM sessions;
- `messaging` tool profile;
- denial of automation, runtime, filesystem, session-spawning/sending,
  patching, host execution, and elevated tools; and
- private OpenClaw state permissions through `security audit --fix`.

This profile prioritizes safe conversation. General-purpose coding, browsing,
filesystem, and computer automation are outside version 1.

## Idempotence and recovery

- Matching OpenClaw and managed Claude versions are not reinstalled.
- A different OpenClaw version requires explicit confirmation; replacement is
  never the default.
- The `.safe-start-managed` marker distinguishes a rerun from an unrelated
  pre-existing OpenClaw configuration without storing a secret.
- Existing unmanaged state triggers a stop-by-default warning.
- Gateway service, hardening config, restart, Tailscale target state, wake
  target state, and Windows firewall rule are safe to repeat.
- Failed downloads are retried and checksum failures stop before execution.
- Temporary bootstrap/package files are removed on exit.
- Provider cancellation leaves the official login/onboarding flow safe to rerun.

## Honest determinism

The directly consumed OpenClaw bootstrap scripts and Claude Code wrapper are
version-pinned and SHA-256 verified, the installed versions are checked, and
the wrapper applies the same ordered target state. `tools/verify-pins.sh`
reproduces the consumed bytes independently.

This is not a reproducible machine image. Operating systems, Homebrew/WinGet,
Git for Windows, Tailscale, npm platform-specific packages and transitive
dependencies, hosted subscription authentication, model catalogs, plan limits,
and remote services remain live. “Deterministic” must always be qualified as a
verified bootstrap and repeatable configuration target.

## Secret-handling invariant

The wrapper must never:

- accept an AI API key in the beginner flow;
- accept a provider password, browser cookie, recovery code, or session token;
- pass a provider/bot/Gateway secret as a wrapper-controlled command argument;
- print or log a secret;
- inspect the value of a secret-bearing environment variable;
- save a secret in this repository, management marker, or support artifact;
- copy another user's state, workspace, history, or credentials; or
- encourage users to paste secret-bearing diagnostics into an AI or issue.

Subscription login is delegated to official browser flows. Bot tokens are
delegated to OpenClaw's masked official channel prompts. The Gateway token is
generated inside OpenClaw without displaying it.

## Setup-time design budget

Before the first reply, the only intended user decisions are:

1. confirm the safe dedicated-account checklist;
2. consent to the reviewed installation plan;
3. choose ChatGPT (default) or Claude; and
4. complete the provider's browser login.

Channel, Tailscale, wake, and SSH choices occur later. The 90% active-time goal
is governed by `SETUP_TIME_BENCHMARK.md` and is not a release claim until tested.

## Release matrix

Run each release on disposable, fully patched machines or virtual machines.

| Platform | ChatGPT | Claude | Rerun | No-admin first chat | Tailscale | Wake | SSH | Reboot |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Current macOS Apple Silicon | required | required | required | required | required | required | required | required |
| Current macOS Intel | required | required | required | required | required | required | required | required |
| Windows 11 x64 / PowerShell 5.1 | required | required | required | required | required | required | required | required |
| Windows 11 x64 / PowerShell 7 | required | required | required | required | required | required | required | required |
| Windows 11 ARM64 | required | required | required | required | required | required | required | required |

For each relevant row verify:

1. Dry-run performs no filesystem, network, service, power, or firewall write.
2. A mismatched OpenClaw or Claude checksum stops before execution/installation.
3. A known secret environment variable stops safely without printing its value.
4. Unmanaged OpenClaw state stops by default; a managed rerun succeeds.
5. ChatGPT OAuth cannot fall through to an API-key route.
6. Claude always runs `--claudeai`, never Console billing, and uses the pinned
   absolute runtime path.
7. Browser/provider cancellation gives a clear rerun path.
8. The Gateway is loopback-only with token auth and explicit rate limiting.
9. Insecure/dangerous Control UI switches are false.
10. Runtime, filesystem, automation, patching, spawning, and elevated tools are
    unavailable to the first chat and connected channel.
11. Separate senders do not share one DM session.
12. WebChat returns a real reply before optional integrations are required.
13. Telegram uses pairing and a dedicated bot; token input is masked.
14. Tailscale uses Serve, verified identity, loopback origin, and no Funnel.
15. The Gateway survives a process kill and recovers after logout/reboot as
    documented.
16. Battery sleep remains unchanged.
17. Windows SSH permits only Tailscale address ranges; macOS warns that Remote
    Login may also be reachable on trusted LANs.
18. `security audit --deep` has no unresolved critical/high finding created by
    the wrapper.
19. Undo instructions remove only named Safe Start changes.
20. No archive, log, screenshot, CI artifact, issue template, or repository file
    contains a real secret or personal baseline detail.

Stable release is blocked until every applicable required cell passes and an
independent security review has no unresolved critical/high findings.

## Updating pins

1. Read upstream release notes and security advisories.
2. Resolve the exact OpenClaw commit/version and Claude Code version.
3. Review the diff for both directly consumed OpenClaw bootstrap scripts and
   the Claude wrapper manifest/install behavior.
4. Download from immutable official locations and compute SHA-256 locally.
5. Update all related values and provenance in `pins.env` in one change.
6. Run static tests, independent pin verification, clean-machine matrix, threat
   model review, and setup-time regression checks.
7. Record reviewer, date, upstream references, test evidence, and limitations
   in the release notes.

Never change a checksum merely because the old one stopped matching. A mismatch
is a release-blocking request for a new code review.
