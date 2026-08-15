# Independent review response

The first independent critique correctly blocked the initial concept because
it treated API-key onboarding as normal, overstated determinism, lacked a pin
reproducer, did not sufficiently validate Windows interactive behavior, and
did not document rollback and clean-machine release gates.

The current design makes the following release-level corrections:

- ChatGPT subscription OAuth is the default and Claude Code subscription login
  is the only alternative; API keys are absent from the beginner flow.
- Claude is pinned, checksum-verified, installed privately, forced through
  `--claudeai`, and adopted through OpenClaw's `anthropic-cli` route.
- Directly consumed upstream bootstrap/package pins are independently
  reproducible with `tools/verify-pins.sh` and CI.
- The wrapper requires a fresh dedicated OS account, refuses known secret
  environment variables, and removes the maintainer-machine baseline from all
  public documentation.
- Gateway, auth, rate limits, UI flags, DM scope, file permissions, and tool
  access receive an explicit beginner safety baseline.
- Tailscale Serve remains private; Funnel is prohibited. Chat services use
  dedicated identities and WhatsApp personal history is excluded.
- Undo, threat model, private security reporting, contribution rules, GitHub
  issue templates, and a clean-machine release matrix are included.
- The 90% time reduction is a measured product target, not a current claim.

These changes do not turn the project into a fully reproducible machine image
or prove production readiness. Clean Mac/Windows subscription e2e testing and a
second independent security audit remain stable-release gates.
