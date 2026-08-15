# Setup-time benchmark

## Claim policy

“Cuts setup time by 90%” is currently a product target, not an established
fact. Do not publish that claim in a release description, social post, website,
or repository topic until this protocol passes. Until then use: “designed to
remove most manual setup decisions.”

## Metric

Measure **active beginner time** from opening the instructions to sending and
receiving the first successful WebChat reply. Exclude provider outage time and
large operating-system update downloads, but include reading, choices, browser
login, error recovery, and installer interaction.

Also record:

- elapsed wall-clock time;
- number of user decisions;
- number of copied commands;
- number of documentation lookups;
- number of errors and recoveries;
- whether the participant can correctly explain where credentials are stored,
  who can reach the Gateway, and which tools the bot can use; and
- any accidental secret disclosure or unsafe choice.

## Baseline

Each participant first follows only upstream OpenClaw, provider, security,
Tailscale, wake, and channel documentation to produce the same target state:

- subscription login;
- background Gateway;
- loopback/token/rate-limit security baseline;
- messaging-only tools and isolated DMs;
- first WebChat reply;
- optional private Tailscale Serve; and
- one dedicated Telegram bot.

The baseline instructions and version/date must be archived with results. Do
not invent a baseline duration.

## Test population

- At least five first-time OpenClaw users on clean current macOS machines.
- At least five first-time OpenClaw users on clean Windows 11 machines using
  Windows PowerShell 5.1.
- A balanced mix of ChatGPT and Claude subscription paths.
- Participants must be comfortable using ordinary apps but unfamiliar with
  OpenClaw and its CLI.

Use fresh virtual machines or reset physical test accounts for every run. Use
test subscriptions and dedicated chat bots; never observe personal accounts.

## Pass criteria

The 90% claim may be used only when:

1. median active time with Safe Start is at least 90% lower than the paired
   manual baseline on both operating systems;
2. every participant reaches a verified first reply without facilitator action;
3. no participant exposes a secret or chooses API billing;
4. at least 90% answer all three security-comprehension questions correctly;
5. no critical/high security finding remains open; and
6. raw anonymized timings and the calculation are published in a release note.

If only decision count falls by 90%, state “90% fewer setup decisions,” not
“90% faster.” Never convert one metric into the other.
