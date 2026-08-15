# Undo and removal

Use only the section matching the change you intentionally want to reverse.
Back up non-secret work you created inside the OpenClaw workspace first. Never
upload the backup for support; it may contain private conversation content.

## Disable optional remote access

Return OpenClaw to local-only access:

```text
openclaw config set gateway.tailscale.mode off
openclaw config set gateway.auth.allowTailscale false --strict-json
openclaw config set gateway.bind loopback
openclaw gateway restart
```

Use the Tailscale app to remove this device from the tailnet if it is no longer
needed. Do not replace Serve with Funnel or a LAN/public bind.

## Restore normal sleep

Mac: open **System Settings > Battery/Energy** and restore the desired plugged-in
sleep and Wake for network access settings. If Safe Start enabled restart after
power failure on a desktop, disable that setting in the same power/energy area
or with the corresponding `systemsetup` command.

Windows: open **Settings > System > Power & battery** and restore the desired
plugged-in sleep timeout. The wrapper does not change battery sleep.

## Disable SSH

Mac: turn off **System Settings > General > Sharing > Remote Login**.

Windows (Administrator PowerShell):

```powershell
Stop-Service sshd
Set-Service -Name sshd -StartupType Disabled
Disable-NetFirewallRule -Name OpenClaw-SSH-Tailnet
```

Do not remove the Windows OpenSSH capability if another application or user
depends on it.

## Remove the managed Claude Code runtime

Only remove this directory and wrapper if they were created by Safe Start and
no other OpenClaw setup uses them.

Mac:

```text
~/.openclaw/tools/claude-code
~/.openclaw/bin/claude
```

Windows:

```text
%USERPROFILE%\.openclaw\tools\claude-code
%USERPROFILE%\.openclaw\bin\claude.cmd
```

Git for Windows is a shared system application. Do not uninstall it merely
because Claude Code was removed; first confirm nothing else uses Git.

## Remove OpenClaw

Follow the uninstall command in the official documentation for the installed
OpenClaw version. Stop and remove the managed Gateway service before deleting
state. Delete `~/.openclaw` (or `%USERPROFILE%\.openclaw`) only if you understand
that it removes configuration, credentials, device identities, memory, sessions,
workspace content, and the Safe Start marker.

Revoking local files does not revoke remote sessions. Separately revoke:

- ChatGPT/OpenAI or Claude authorized sessions;
- Telegram/Discord bot tokens;
- WhatsApp linked devices; and
- the computer from Tailscale.

## Security incident

If a credential may have been exposed, disconnect optional remote/chat access,
revoke the affected credential at its issuing service, create a new credential,
review recent access, and run `openclaw security audit --deep`. Do not simply
delete a local file and assume the remote credential is safe.
