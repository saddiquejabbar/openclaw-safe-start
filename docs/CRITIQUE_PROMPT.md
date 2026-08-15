# Prompt for an independent AI critic

Give the other model read access to the complete repository and use this prompt.

---

You are the independent release-blocking reviewer for **OpenClaw Safe Start**,
a cross-platform security-sensitive beginner installer. Review the complete
repository. Do not assume its README or comments are correct. Verify claims
against code and current primary documentation for OpenClaw, OpenAI, Anthropic,
Apple, Microsoft, Tailscale, npm, Telegram, Discord, and WhatsApp.

Product requirement: a first-time user in a fresh dedicated Mac or Windows OS
account must reach a real OpenClaw WebChat reply through either ChatGPT
subscription OAuth or Claude Code subscription login. The primary path must not
request an AI API key, switch to pay-per-token API billing, copy existing
credentials, reveal a secret, expose the Gateway publicly, or allow chat
messages to use host runtime/filesystem/elevated tools. Optional dedicated chat
accounts, Tailscale Serve, wake settings, and SSH come later.

Treat the claimed 90% setup-time reduction as unproven unless the repository
contains valid cross-platform benchmark evidence matching its protocol.

Audit adversarially:

1. **Correctness:** shell/PowerShell syntax, exact current CLI flags/config
   schema, version parsing, TTY/browser login, PATH, platform architecture,
   service behavior, process exit codes, quoting, reboot, and partial failure.
2. **Authentication and billing:** prove `--auth-choice openai` is subscription
   OAuth; prove Claude always uses `--claudeai` and `anthropic-cli`; find every
   path that could consume an API key, Console billing, stale credential, or
   wrong workspace/account.
3. **Secret safety:** inspect environment-variable checks, command arguments,
   process listings, terminal output, temp files, config permissions, logs,
   support/issue templates, archives, CI artifacts, and bot-token entry.
4. **Gateway and tool security:** loopback, token generation, rate limiting,
   device identity, insecure/dangerous flags, Tailscale identity, Serve versus
   Funnel, DM isolation, channel pairing, tool profile/deny precedence, exec,
   filesystem, automation, patching, session spawning, elevated mode, and
   plugin/skill supply chain.
5. **Fresh-account assumption:** determine what the code truly detects versus
   merely asks the user to confirm; browser sync, Keychain/Credential Manager,
   existing CLI sessions, cloud drives, password managers, backups, and local
   malware are relevant residual risks.
6. **Determinism:** immutable pins, checksum reproducer, installer/package
   review scope, npm optional platform packages, transitive dependencies,
   Homebrew/WinGet drift, TOCTOU, update process, and truthful documentation.
7. **Mac:** Apple Silicon/Intel, macOS permissions, local Node/OpenClaw, launchd,
   FileVault/login behavior, Tailscale variants, power/lid/Wake behavior, and
   Remote Login network scope.
8. **Windows:** Windows 11 x64/ARM64, PowerShell 5.1/7, ASCII/encoding,
   execution policy, WinGet absence, Git/Claude runtime layout, console TTY,
   PATH refresh, Scheduled Tasks, Device Encryption, Modern Standby, OpenSSH,
   and firewall scope.
9. **User experience:** reading level, first-chat interaction budget, default
   choices, cancellation/recovery, redaction guidance, comprehension, optional
   step ordering, and any unsafe shortcut a novice is likely to take.
10. **Testing/release:** static, unit, integration, clean VM, failure injection,
    secret canaries, no-write dry-run assertions, permission checks, provider
    login e2e, Tailscale/channel e2e, independent review, and benchmark evidence.
11. **GitHub/public release:** `.gitignore`, history/archives, Actions pinning and
    permissions, issue templates, private vulnerability reporting, license,
    trademarks, personal information, branch protection, secret scanning, and
    release asset provenance.

Required response:

- Start with exactly **BLOCK**, **CONDITIONAL PASS**, or **PASS**, followed by a
  one-sentence ship decision.
- Order findings Critical, High, Medium, Low.
- For each finding give exact file/line, evidence, realistic scenario, whether
  confirmed or uncertain, and the smallest concrete fix.
- Include an end-to-end first-chat friction budget with every user interaction.
- Include a data-flow/secret-flow review and revised threat model.
- State precisely what “deterministic” can and cannot mean.
- Test the 90% claim against `SETUP_TIME_BENCHMARK.md`; reject unsupported
  marketing language.
- Provide at least 20 executable tests with preconditions and expected results,
  covering both operating systems and injected failures.
- Split the patch plan into: before any test user, before public beta, before
  stable release, and later.
- End with the three highest-leverage changes and why they beat larger rewrites.

Do not give generic praise, restate the README, expose any real credential you
find, or rewrite the project before reporting defects. If a secret is present,
redact it, identify only the containing file/location, and recommend immediate
revocation through a private channel.

---
