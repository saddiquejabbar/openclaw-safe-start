# Contributing

Thank you for helping make first-time OpenClaw setup safer and simpler.

## Before changing code

1. Read `docs/SAFE_START.md`, `docs/THREAT_MODEL.md`, and `docs/DESIGN.md`.
2. For a security flaw, use the private process in `SECURITY.md`.
3. Open a normal issue for user experience, documentation, compatibility, or
   feature proposals that contain no sensitive information.
4. Keep version 1 focused on first safe chat. New providers, channels, tools,
   and remote-access modes need an explicit threat-model update.

## Pull-request requirements

- Never commit real secrets, account identifiers, transcripts, local state, or
  screenshots showing personal information.
- Do not add download-to-shell pipelines.
- Pin every directly executed remote bootstrap to an immutable source and
  reviewed SHA-256 digest.
- Preserve ChatGPT/Claude subscription login as the two primary choices. API
  keys belong only in clearly separated advanced documentation.
- Keep Gateway loopback-only and never add public Funnel or port forwarding.
- Add or update tests for every behavior change.
- Update undo and troubleshooting guidance when state or system settings change.
- Use plain language a first-time computer user can follow.

Run before submitting:

```bash
./tests/test-static.sh
./tools/verify-pins.sh
```

On Windows, also run the PowerShell 5.1 dry-run and verify commands documented
in the README. A release-affecting change needs the clean-machine matrix in
`docs/DESIGN.md`.

## Commit and review hygiene

Keep changes small, explain the user-visible outcome, list the security impact,
and state what was tested. Reviewers should treat installer changes as
security-sensitive and verify code rather than trusting prose.
