# Third-party notices

Safe Start is independent community software. Product names and trademarks
belong to their respective owners. No affiliation or endorsement is implied.

## OpenClaw

This project downloads an official OpenClaw bootstrap script from an immutable
Git commit, verifies SHA-256, and asks it to install the exact version recorded
in `pins.env`. OpenClaw is not redistributed in this repository.

- Project: https://github.com/openclaw/openclaw
- License: MIT
- Pinned commit/version and digests: `pins.env`

OpenClaw's own copyright and license apply to OpenClaw.

## Claude Code

When the Claude subscription path is selected, Safe Start downloads the exact
`@anthropic-ai/claude-code` npm wrapper package recorded in `pins.env`, verifies
SHA-256, and installs it into the user's private OpenClaw tool directory. The
package is not redistributed in this repository. Claude Code and Anthropic
services remain subject to Anthropic's terms and license notices delivered with
the package.

- Setup documentation: https://docs.anthropic.com/en/docs/claude-code/getting-started
- Package/version/digest: `pins.env`

## Other services and installers

Optional Tailscale and Git for Windows installations use official Homebrew,
WinGet, or vendor download routes. OpenAI, Tailscale, Git, Telegram, Discord,
WhatsApp/Meta, Apple, Microsoft, Homebrew, WinGet, and npm software/services
retain their own licenses, privacy policies, account rules, and terms.

Safe Start does not redistribute those products, grant rights to their marks,
or replace their security/support processes.
