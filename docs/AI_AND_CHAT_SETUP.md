# AI and chat setup

The shortest route is: sign in with an existing ChatGPT or Claude subscription,
receive one reply in WebChat, and add a dedicated chat bot only if phone access
is wanted. The primary installer does not ask for an AI API key.

## 1. Choose one subscription

### ChatGPT subscription (default)

What you need: ChatGPT Plus, Pro, or an eligible workspace plan that permits
Codex access.

1. Choose **ChatGPT** in the terminal wizard.
2. OpenClaw starts its `openai` subscription OAuth route.
3. A browser opens to OpenAI. Verify the HTTPS domain, then sign in with the
   account/workspace that owns the subscription.
4. Return to the terminal. OpenClaw tests a real reply before saving the route.

This does not require OpenAI Platform credits, API billing, or an API key.
Usage remains subject to the signed-in ChatGPT plan and workspace permissions.

Official references:

- https://learn.chatgpt.com/docs/auth
- https://docs.openclaw.ai/providers/openai

### Claude Code subscription

What you need: Claude Pro or Max with Claude Code access.

1. Choose **Claude Code** in the terminal wizard.
2. The kit downloads the pinned Claude Code wrapper package, verifies SHA-256,
   and installs it privately under the OpenClaw user directory.
3. It explicitly runs `claude auth login --claudeai`.
4. Verify the browser uses Claude.ai, then sign in with the account that owns
   the Pro or Max subscription. Do not select Anthropic Console billing.
5. OpenClaw adopts that Claude CLI session, uses an absolute path to the pinned
   runtime, and tests a real reply before saving it.

This does not require an Anthropic API key. Usage remains subject to Claude Code
subscription limits. On Windows, Claude Code requires Git for Windows; the kit
uses WinGet when available or opens Git's official instructions.

Official reference:

- https://docs.anthropic.com/en/docs/claude-code/getting-started

### API-key providers are advanced

OpenClaw supports API-key and local-model providers, but they are deliberately
absent from this beginner wizard. An experienced owner can add one later using
upstream OpenClaw documentation and a separate threat/billing review. Never add
an API-key fallback merely to bypass subscription limits or login trouble.

## 2. First chat: WebChat

WebChat ships with OpenClaw and requires no additional service account. Safe
Start opens it immediately after the AI route and safety baseline are ready.

For a local test, use the dashboard command or the loopback page shown by
OpenClaw. Never put a Gateway token in a URL or support message.

## 3. Optional chat accounts

| Interface | Identity requirement | Effort | Beginner posture |
|---|---|---:|---|
| WebChat | None | Lowest | Default first chat |
| Telegram | New dedicated BotFather bot | Low | Recommended phone option |
| Discord | New dedicated app/bot | Medium | Separate test server preferred |
| WhatsApp | Separate account and number | Medium | Never link personal history |

The bot should not share an identity, token, server, or chat history with an
existing production or personal system.

### Telegram

1. Open https://t.me/BotFather and verify the account is exactly
   `@BotFather` with Telegram's verification mark.
2. Send `/newbot`, choose a new name and unique username ending in `bot`.
3. Copy the newly issued token.
4. Choose Telegram in Safe Start. Paste the token only into OpenClaw's masked
   channel wizard.
5. Send `/start` to the new bot.
6. List and approve the one-time pairing request shown in the terminal.
7. Test a direct message before considering a group.

Recovery commands:

```text
openclaw channels add --channel telegram
openclaw gateway restart
openclaw pairing list telegram
openclaw pairing approve telegram YOUR_CODE
openclaw channels status --probe
```

Never configure an open wildcard for a one-owner bot. Revoke and regenerate a
token immediately if it appears in a screenshot, recording, log, issue, or AI
chat.

### Discord

1. Open https://discord.com/developers/applications and create a new application.
2. Create its bot and copy the new token.
3. Enable only the gateway intents OpenClaw's current wizard requires.
4. Generate an install URL with the minimum permissions and authorize it in a
   separate test server.
5. Paste the token only into OpenClaw's masked wizard and run the channel probe.

Recovery commands:

```text
openclaw channels add --channel discord
openclaw gateway restart
openclaw channels status --probe
```

### WhatsApp

Safe Start requires a separate WhatsApp account/number with no personal chat
history. If that is unavailable, choose WebChat or Telegram instead.

1. Choose WhatsApp and confirm the account is separate.
2. Allow OpenClaw to install its official plugin.
3. Under WhatsApp **Linked devices**, scan the QR shown by OpenClaw.
4. Restart the Gateway and probe the channel.

```text
openclaw channels add --channel whatsapp
openclaw channels login --channel whatsapp
openclaw gateway restart
openclaw channels status --probe
```

## 4. Private WebChat from another device

Install Tailscale on the OpenClaw computer and the viewing phone/laptop. Keep
only trusted people and devices in the tailnet. Safe Start keeps the Gateway on
loopback and enables Tailscale Serve with verified identity headers and HTTPS.

Public Tailscale Funnel, router port forwarding, LAN binding, and public reverse
proxies are outside the beginner design and must not be used as shortcuts.
