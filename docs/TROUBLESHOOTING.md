# Troubleshooting

Start with the diagnostic command in the README, then match the first symptom.
Do not paste unredacted output into an issue or AI chat.

## The safe-start check stops

If an API-key or bot-token environment variable is detected, the installer
prints its **name only**. It does not read or print the value. Close that
terminal, remove the variable from the dedicated user's startup configuration,
and open a clean terminal. Do not copy the value elsewhere.

If an unmanaged `openclaw.json` exists, stop and use a fresh dedicated OS user
unless you intentionally know how to audit and migrate that state. Never upload
the file for support; it may identify accounts or reference credentials.

## `openclaw` is not found

Close the terminal, open a new one, and try again.

Expected Mac path:

```text
~/.openclaw/bin/openclaw
```

On Windows, reopen PowerShell to refresh the user and machine PATH. Then rerun
the installer; it keeps matching completed steps.

## ChatGPT subscription sign-in fails

1. Confirm the account has an eligible ChatGPT subscription and workspace
   access to Codex.
2. Rerun this installer, agree to onboarding, and choose ChatGPT.
3. Use the fresh dedicated browser profile with sync disabled.
4. Confirm the page is OpenAI's official HTTPS sign-in page.
5. If a workspace chooser appears, select the workspace holding the entitlement.

This route is separate from OpenAI Platform API billing and must not ask for an
API key. Do not create a Platform key to fix a subscription OAuth error.

If a browser cannot return to the local callback, OpenClaw may offer a supported
device-code flow. Follow only the exact URL and code displayed by the official
CLI and never send that code to anyone.

## Claude Code subscription sign-in fails

1. Confirm Claude Pro or Max includes Claude Code for that account.
2. Rerun this installer, agree to onboarding, and choose Claude Code.
3. On Windows, finish the standard Git for Windows installation if prompted.
4. Confirm the browser is Claude.ai, not Anthropic Console.
5. The explicit recovery login is:

   ```text
   claude auth login --claudeai
   ```

6. Check login without printing a credential:

   ```text
   claude auth status --text
   ```

Claude Code subscription limits still apply. Wait for the plan limit to reset
instead of creating an API key or switching to Console billing accidentally.

## WebChat does not open

Run:

```text
openclaw gateway status --json
openclaw doctor --non-interactive
openclaw dashboard
```

Use only the loopback URL shown locally. The wrapper generates the Gateway
token inside OpenClaw and does not display it. Do not post it or place it in a
URL. A new remote browser may need explicit device approval.

## A security audit reports a finding

Run:

```text
openclaw security audit --deep
```

Stop remote/channel use for critical or high findings. Do not “fix” the problem
by enabling insecure authentication, disabling device identity, binding to LAN,
using Funnel, or weakening tool restrictions. Open a private security report if
the wrapper created the unsafe state.

## Gateway stops after logout or reboot

```text
openclaw gateway install
openclaw gateway restart
openclaw gateway status --json
```

Mac uses a per-user LaunchAgent, so the dedicated user must log in after a full
restart. Windows uses a per-user Scheduled Task. Tailscale unattended/pre-login
operation requires its separate documented setup and may need administrator
approval.

## Telegram bot is silent

```text
openclaw pairing list telegram
openclaw channels status --probe
openclaw channels logs --channel telegram
```

- Approve the current pairing request.
- A `401` usually means the token is wrong or revoked. Create a fresh token in
  BotFather and rerun the masked channel wizard.
- Test a direct message first. Groups need explicit policy and normally a
  mention.
- Redact handles, IDs, message text, and tokens before sharing logs.

## WhatsApp must be relinked

```text
openclaw channels login --channel whatsapp
openclaw gateway restart
openclaw channels status --probe
```

Scan the new QR from the separate bot account under **Linked devices**. Do not
fall back to a personal account.

## Tailscale remote WebChat fails

1. Confirm both devices are in the same trusted tailnet.
2. Remove unknown tailnet members/devices.
3. Run `tailscale status` on the OpenClaw computer.
4. Confirm `gateway.bind` remains `loopback` and Tailscale mode is `serve`.
5. Use the HTTPS `.ts.net` address reported by OpenClaw/Tailscale.

Never open router ports, switch to LAN bind, disable authentication, or enable
Funnel as a workaround.

## Computer still sleeps

Mac: confirm plugged-in sleep is disabled and **Wake for network access** is
enabled. A closed MacBook lid can still sleep unless used in a supported
clamshell arrangement.

Windows: confirm plugged-in sleep is **Never**. Modern Standby and laptop lid
behavior are separate settings. Battery sleep intentionally remains unchanged.

## SSH fails

SSH is optional and unnecessary for WebChat.

Mac Remote Login can be reachable over trusted local networks as well as
Tailscale. Restrict allowed users and keep a strong login password.

Windows requires Administrator PowerShell to install OpenSSH and creates a
firewall rule limited to Tailscale address ranges. Verify `sshd` and the
`OpenClaw-SSH-Tailnet` rule.

## Safe repair sequence

```text
openclaw doctor --non-interactive
openclaw gateway restart
openclaw channels status --probe
openclaw security audit --deep
```

Read proposed repairs before accepting them. Do not delete `~/.openclaw`, share
it, or reset authentication as a generic first step.
