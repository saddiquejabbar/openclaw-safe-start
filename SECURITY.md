# Security policy

## Supported versions

Until the first stable release, only the latest commit on the default branch is
supported. Release notes will identify supported stable versions later.

## Report a vulnerability privately

Do not open a public issue for a suspected vulnerability, leaked credential,
unsafe default, authentication bypass, or supply-chain concern.

Use GitHub's private reporting flow:

https://github.com/saddiquejabbar/openclaw-safe-start/security/advisories/new

Include:

- affected file, release, and operating system;
- exact reproduction steps using fake credentials;
- expected versus actual behavior;
- impact and realistic attack scenario; and
- a minimal fix if known.

Never attach real tokens, passwords, account identifiers, OpenClaw state,
provider login files, chat transcripts, browser profiles, or unredacted logs.
Replace sensitive values with stable placeholders such as `[TOKEN-REDACTED]`.

The maintainer will acknowledge a complete report, validate impact, coordinate
a fix, and publish an advisory when users have a safe upgrade path. Response
times are best-effort until a formal maintainer team exists.

## Security boundaries

This repository controls its wrapper scripts and documentation. OpenClaw,
provider authentication, chat platforms, Tailscale, package managers, operating
systems, and transitive dependencies remain separate upstream trust domains.
Report upstream flaws to their own security teams as well.

See [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) for the design assumptions and
residual risks.
