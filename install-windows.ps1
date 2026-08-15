[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Check,
    [switch]$Verify,
    [switch]$Defaults,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PinsFile = Join-Path $ScriptRoot "pins.env"
$Pins = @{}
$ManagedClaudePath = $null
$SafeStartMarker = Join-Path $HOME ".openclaw\.safe-start-managed"

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "! $Message" -ForegroundColor Yellow }
function Stop-WithError([string]$Message) { throw $Message }

function Show-Usage {
    @"
OpenClaw Safe Start - Windows

Usage: powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [option]

  -DryRun    Show the exact plan without changing anything
  -Check     Diagnose an existing setup without changing anything
  -Verify    Verify pinned OpenClaw and Claude Code files without running them
  -Defaults  Accept recommended choices (subscription login still opens)
  -Help      Show this help
"@ | Write-Host
}

function Import-Pins {
    if (-not (Test-Path -LiteralPath $PinsFile)) {
        Stop-WithError "Missing pins file: $PinsFile"
    }
    foreach ($line in Get-Content -LiteralPath $PinsFile) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) { continue }
        if ($trimmed -notmatch '^([A-Z0-9_]+)=([A-Za-z0-9._:/+\-]+)$') {
            Stop-WithError "Invalid line in pins.env: $trimmed"
        }
        $Pins[$Matches[1]] = $Matches[2]
    }
    foreach ($required in @(
        "OPENCLAW_VERSION",
        "OPENCLAW_COMMIT",
        "OPENCLAW_INSTALL_PS1_SHA256",
        "CLAUDE_CODE_VERSION",
        "CLAUDE_CODE_TARBALL_SHA256"
    )) {
        if (-not $Pins.ContainsKey($required)) { Stop-WithError "pins.env is missing $required" }
    }
}

function Confirm-Step([string]$Prompt, [bool]$DefaultYes = $true) {
    if ($Defaults) { return $DefaultYes }
    $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host "$Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $DefaultYes }
    return $answer -match '^(?i:y|yes)$'
}

function Wait-Ready {
    if (-not $Defaults) { [void](Read-Host "Press Enter when ready") }
}

function Format-Command([string]$File, [string[]]$Arguments) {
    $rendered = @($File)
    foreach ($argument in $Arguments) {
        if ($argument -match '[\s"'']') {
            $rendered += '"' + ($argument -replace '"', '\"') + '"'
        } else {
            $rendered += $argument
        }
    }
    return ($rendered -join ' ')
}

function Invoke-Native([string]$File, [string[]]$Arguments = @(), [switch]$AllowFailure) {
    Write-Host "  PS> $(Format-Command $File $Arguments)" -ForegroundColor DarkCyan
    if ($DryRun) { return 0 }
    $global:LASTEXITCODE = 0
    & $File @Arguments | Out-Host
    $code = $LASTEXITCODE
    if ($code -ne 0 -and -not $AllowFailure) {
        Stop-WithError "$File exited with code $code"
    }
    return $code
}

function Invoke-InteractiveNative([string]$File, [string[]]$Arguments = @()) {
    Write-Host "  PS> $(Format-Command $File $Arguments)" -ForegroundColor DarkCyan
    if ($DryRun) { return }
    $process = Start-Process -FilePath $File -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Stop-WithError "$File exited with code $($process.ExitCode)"
    }
}

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Get-OpenClaw {
    Refresh-Path
    foreach ($name in @("openclaw.cmd", "openclaw.exe", "openclaw")) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command -and $command.Source -notlike "*.ps1") { return $command.Source }
    }
    return $null
}

function Get-OpenClawVersion([string]$CommandPath) {
    $text = (& $CommandPath --version 2>$null | Out-String).Trim()
    $match = [regex]::Match($text, '(?<![0-9])([0-9]{4}\.[0-9]+\.[0-9]+(?:-[0-9]+)?)(?![0-9])')
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value
}

function Get-Npm {
    Refresh-Path
    foreach ($name in @("npm.cmd", "npm.exe", "npm")) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command -and $command.Source -notlike "*.ps1") { return $command.Source }
    }
    return $null
}

function Get-ManagedClaude {
    $candidate = Join-Path $HOME ".openclaw\tools\claude-code\node_modules\@anthropic-ai\claude-code\bin\claude.exe"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    return $null
}

function Get-ClaudeVersion([string]$CommandPath) {
    $text = (& $CommandPath --version 2>$null | Out-String).Trim()
    $match = [regex]::Match($text, '(?<![0-9])([0-9]+\.[0-9]+\.[0-9]+)(?![0-9])')
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value
}

function Get-GitBash {
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidates += Join-Path $env:ProgramFiles "Git\bin\bash.exe"
    }
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $candidates += Join-Path $programFilesX86 "Git\bin\bash.exe"
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Get-Tailscale {
    Refresh-Path
    $command = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }
    $candidate = Join-Path $env:ProgramFiles "Tailscale\tailscale.exe"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    return $null
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Plan {
    @"

OpenClaw Safe Start - safe dry run

Pinned OpenClaw: $($Pins.OPENCLAW_VERSION)
Pinned upstream commit: $($Pins.OPENCLAW_COMMIT)

The guided run will:
  1. Confirm a fresh dedicated computer account with no imported credentials.
  2. Refuse to run while common API-key or bot-token variables are present.
  3. Verify the official installer from an immutable commit, then install
     exactly OpenClaw $($Pins.OPENCLAW_VERSION).
  4. Choose ChatGPT subscription (default) or Claude Code subscription, sign
     in only through the provider's browser page, and test a real reply.
  5. Apply loopback-only networking, token auth, rate limiting, private file
     permissions, separate DM sessions, and a messaging-only tool profile.
  6. Open WebChat so the first conversation can start immediately.
  7. Offer a dedicated Telegram or Discord bot, or a separate WhatsApp account.
  8. Offer private Tailscale Serve, plugged-in wake settings, and optional SSH.
  9. Run health, channel, pin, and deep security checks.

No AI API key is needed or requested on the primary path. Provider passwords
belong only in provider HTTPS pages; bot tokens use OpenClaw's masked prompts.
"@ | Write-Host
}

function Get-VerifiedInstaller {
    $url = "https://raw.githubusercontent.com/openclaw/openclaw/$($Pins.OPENCLAW_COMMIT)/scripts/install.ps1"
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("openclaw-safe-start-" + [Guid]::NewGuid().ToString("N") + ".ps1")
    Write-Info "Downloading the reviewed OpenClaw installer snapshot"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $downloaded = $false
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $temp -TimeoutSec 120
            $downloaded = $true
            break
        } catch {
            if ($attempt -eq 3) { throw }
            Write-Warn "Download attempt $attempt failed; retrying."
            Start-Sleep -Seconds 2
        }
    }
    if (-not $downloaded) { Stop-WithError "Could not download the pinned OpenClaw installer." }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $temp).Hash.ToLowerInvariant()
    if ($actual -ne $Pins.OPENCLAW_INSTALL_PS1_SHA256.ToLowerInvariant()) {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Stop-WithError "Installer checksum mismatch. Nothing was run."
    }
    Write-Ok "Installer checksum passed (SHA-256)"
    return $temp
}

function Get-VerifiedClaudePackage {
    $url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$($Pins.CLAUDE_CODE_VERSION).tgz"
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("openclaw-claude-code-" + [Guid]::NewGuid().ToString("N") + ".tgz")
    Write-Info "Downloading the reviewed Claude Code package"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $downloaded = $false
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $temp -TimeoutSec 120
            $downloaded = $true
            break
        } catch {
            if ($attempt -eq 3) { throw }
            Write-Warn "Download attempt $attempt failed; retrying."
            Start-Sleep -Seconds 2
        }
    }
    if (-not $downloaded) { Stop-WithError "Could not download the pinned Claude Code package." }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $temp).Hash.ToLowerInvariant()
    if ($actual -ne $Pins.CLAUDE_CODE_TARBALL_SHA256.ToLowerInvariant()) {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Stop-WithError "Claude Code package checksum mismatch. Nothing was run."
    }
    Write-Ok "Claude Code package checksum passed (SHA-256)"
    return $temp
}

function Install-GitForClaude {
    $bash = Get-GitBash
    if ($null -ne $bash) { return $bash }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -ne $winget) {
        Write-Info "Installing Git for Windows, which Claude Code requires"
        [void](Invoke-Native $winget.Source @(
            "install", "--id", "Git.Git", "--exact",
            "--accept-package-agreements", "--accept-source-agreements"
        ))
    } else {
        Write-Warn "Claude Code on Windows requires Git for Windows. Opening its official download page."
        Start-Process "https://git-scm.com/download/win"
        Write-Host "Install Git for Windows with the standard options, then return here."
        Wait-Ready
    }
    $bash = Get-GitBash
    if ($null -eq $bash) {
        Stop-WithError "Git Bash was not found. Finish installing Git for Windows, then rerun this kit."
    }
    return $bash
}

function Install-ManagedClaudeCode {
    [void](Install-GitForClaude)
    $script:ManagedClaudePath = Get-ManagedClaude
    $current = if ($null -ne $script:ManagedClaudePath) { Get-ClaudeVersion $script:ManagedClaudePath } else { $null }
    if ($current -ne $Pins.CLAUDE_CODE_VERSION) {
        $npm = Get-Npm
        if ($null -eq $npm) {
            Stop-WithError "The OpenClaw Node installation did not provide npm. Rerun installation, then try again."
        }
        $package = Get-VerifiedClaudePackage
        $prefix = Join-Path $HOME ".openclaw\tools\claude-code"
        try {
            Write-Info "Installing private Claude Code $($Pins.CLAUDE_CODE_VERSION) for OpenClaw"
            [void](Invoke-Native $npm @("install", "--global", "--prefix", $prefix, $package))
        } finally {
            Remove-Item -LiteralPath $package -Force -ErrorAction SilentlyContinue
        }
        $script:ManagedClaudePath = Get-ManagedClaude
        if ($null -eq $script:ManagedClaudePath) {
            Stop-WithError "Claude Code installed, but its native executable was not found."
        }
        $current = Get-ClaudeVersion $script:ManagedClaudePath
        if ($current -ne $Pins.CLAUDE_CODE_VERSION) {
            Stop-WithError "Claude Code version verification failed (expected $($Pins.CLAUDE_CODE_VERSION))."
        }
    }
    $binDir = Join-Path $HOME ".openclaw\bin"
    $wrapper = Join-Path $binDir "claude.cmd"
    if (-not (Test-Path -LiteralPath $binDir)) {
        [void](New-Item -ItemType Directory -Path $binDir -Force)
    }
    @("@echo off", "`"$($script:ManagedClaudePath)`" %*") |
        Set-Content -LiteralPath $wrapper -Encoding ASCII
    $env:Path = "$binDir;$env:Path"
    Write-Ok "Claude Code $($Pins.CLAUDE_CODE_VERSION) is ready"
}

function Confirm-SafeStart {
    $blockedNames = @(
        "OPENAI_API_KEY", "ANTHROPIC_API_KEY", "CLAUDE_CODE_OAUTH_TOKEN",
        "CLAUDE_CODE_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY", "XAI_API_KEY",
        "GROQ_API_KEY", "MISTRAL_API_KEY", "DISCORD_BOT_TOKEN", "TELEGRAM_BOT_TOKEN",
        "SLACK_BOT_TOKEN", "SLACK_APP_TOKEN", "OPENCLAW_GATEWAY_TOKEN",
        "OPENCLAW_GATEWAY_PASSWORD", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN",
        "AZURE_CLIENT_SECRET", "GITHUB_TOKEN", "GH_TOKEN", "NPM_TOKEN",
        "NODE_AUTH_TOKEN", "DATABASE_URL"
    )
    @"

Safe-start prerequisite

Use a fresh dedicated Windows user account for this bot. It should have:
  - a strong Windows login password or Windows Hello and device encryption;
  - no personal files, browser sync, password manager, email, or cloud drive;
  - no copied API keys, shell profiles, SSH keys, or credentials; and
  - a fresh browser profile used only for ChatGPT or Claude subscription login.

The installer never needs your provider password in PowerShell. Enter it only
on the provider's HTTPS browser page. Do not paste secrets into AI chats.
"@ | Write-Host
    $found = $false
    foreach ($name in $blockedNames) {
        if (Test-Path -LiteralPath "Env:$name") {
            Write-Warn "Secret-bearing environment variable detected: $name (value was not read or printed)"
            $found = $true
        }
    }
    if ($found) {
        Stop-WithError "Open a clean PowerShell window in the fresh user account with those variables unset, then rerun."
    }
    $unmanaged = $false
    if (-not (Test-Path -LiteralPath $SafeStartMarker)) {
        $riskPaths = @(
            (Join-Path $HOME ".openclaw"),
            (Join-Path $HOME ".claude"),
            (Join-Path $HOME ".codex\auth.json"),
            (Join-Path $HOME ".aws\credentials"),
            (Join-Path $HOME ".ssh")
        )
        foreach ($path in $riskPaths) {
            if (Test-Path -LiteralPath $path) {
                Write-Warn "Existing credential-capable state detected: $path (contents were not read)"
                $unmanaged = $true
            }
        }
    }
    if ($unmanaged) {
        if (-not (Confirm-Step "Continue with existing state? This is not the recommended safe start." $false)) {
            Stop-WithError "Stopped. Use a fresh dedicated Windows account or review and remove the old state first."
        }
    }
    if (-not (Confirm-Step "I confirm this is a fresh dedicated account with no imported personal credentials." $false)) {
        Stop-WithError "Stopped. Complete the safe-start checklist in docs\SAFE_START.md, then rerun."
    }
}

function Protect-OpenClaw {
    $claw = Get-OpenClaw
    Write-Host ""
    Write-Host "Applying the beginner safety baseline" -ForegroundColor White
    $settings = @(
        @("gateway.mode", '"local"'),
        @("gateway.bind", '"loopback"'),
        @("gateway.auth.mode", '"token"'),
        @("gateway.auth.allowTailscale", "false"),
        @("gateway.auth.rateLimit.maxAttempts", "10"),
        @("gateway.auth.rateLimit.windowMs", "60000"),
        @("gateway.auth.rateLimit.lockoutMs", "300000"),
        @("gateway.controlUi.allowInsecureAuth", "false"),
        @("gateway.controlUi.dangerouslyDisableDeviceAuth", "false"),
        @("gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback", "false"),
        @("gateway.allowRealIpFallback", "false"),
        @("session.dmScope", '"per-channel-peer"'),
        @("tools.profile", '"messaging"'),
        @("tools.deny", '["group:automation","group:runtime","group:fs","sessions_spawn","sessions_send"]'),
        @("tools.fs.workspaceOnly", "true"),
        @("tools.exec.mode", '"deny"'),
        @("tools.exec.applyPatch.enabled", "false"),
        @("tools.elevated.enabled", "false")
    )
    foreach ($setting in $settings) {
        [void](Invoke-Native $claw @("config", "set", $setting[0], $setting[1], "--strict-json"))
    }
    Write-Info "Generating the Gateway token inside OpenClaw without displaying it"
    & $claw doctor --generate-gateway-token | Out-Null
    if ($LASTEXITCODE -ne 0) { Stop-WithError "OpenClaw could not generate a Gateway token." }
    & $claw security audit --fix | Out-Null
    if ($LASTEXITCODE -ne 0) { Stop-WithError "OpenClaw could not apply its safe permission fixes." }
    $stateDir = Join-Path $HOME ".openclaw"
    if (-not (Test-Path -LiteralPath $stateDir)) {
        [void](New-Item -ItemType Directory -Path $stateDir -Force)
    }
    @(
        "managed_by=openclaw-safe-start",
        "safe_start_version=0.1.0-alpha",
        "openclaw_version=$($Pins.OPENCLAW_VERSION)"
    ) |
        Set-Content -LiteralPath $SafeStartMarker -Encoding ASCII
    [void](Invoke-Native $claw @("gateway", "install"))
    [void](Invoke-Native $claw @("gateway", "restart"))
    Write-Ok "Loopback, token auth, rate limiting, private files, isolated DMs, and messaging-only tools are set"
}

function Install-OpenClaw {
    $claw = Get-OpenClaw
    if ($null -ne $claw) {
        $current = Get-OpenClawVersion $claw
        if ($current -eq $Pins.OPENCLAW_VERSION) {
            Write-Ok "OpenClaw $($Pins.OPENCLAW_VERSION) is already installed"
            return
        }
        Write-Warn "You already run OpenClaw $current. This kit was reviewed against $($Pins.OPENCLAW_VERSION)."
        if (-not (Confirm-Step "Replace it with the reviewed pinned version?" $false)) {
            Write-Ok "Keeping the existing OpenClaw version. Nothing was changed."
            exit 0
        }
    }
    $installer = Get-VerifiedInstaller
    try {
        $powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
        $exitCode = Invoke-Native $powershell @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $installer,
            "-Tag", $Pins.OPENCLAW_VERSION, "-NoOnboard"
        ) -AllowFailure
        if ($exitCode -ne 0) { Stop-WithError "The official OpenClaw installer failed with exit code $exitCode." }
    } finally {
        Remove-Item -LiteralPath $installer -Force -ErrorAction SilentlyContinue
    }
    Refresh-Path
    $claw = Get-OpenClaw
    if ($null -eq $claw) {
        Stop-WithError "OpenClaw installed but is not on PATH. Close PowerShell, open a new one, and run this script again."
    }
    $installedVersion = Get-OpenClawVersion $claw
    if ($installedVersion -ne $Pins.OPENCLAW_VERSION) {
        Stop-WithError "OpenClaw installed, but version verification failed (expected $($Pins.OPENCLAW_VERSION))."
    }
    Write-Ok "Pinned OpenClaw is ready"
}

function Start-Onboarding {
    $claw = Get-OpenClaw
    $config = Join-Path $HOME ".openclaw\openclaw.json"
    if (Test-Path -LiteralPath $config) {
        if (-not (Confirm-Step "An OpenClaw setup already exists. Run onboarding again?" $false)) {
            Write-Ok "Keeping the existing model and agent setup"
            [void](Invoke-Native $claw @("gateway", "install"))
            return
        }
    }
    @"

Choose the AI subscription you already pay for:

  1) ChatGPT Plus/Pro/Business - recommended and simplest
  2) Claude Code with a Claude Pro or Max subscription

This primary setup never asks for an AI API key or enables pay-per-token API
billing. Sign in only on the provider's HTTPS browser page. The provider may
remember the login in this dedicated browser profile; do not enable browser
sync or import a password vault.
"@ | Write-Host
    $choice = if ($Defaults) { "1" } else { Read-Host "Choose [1-2, default 1]" }
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    switch ($choice) {
        "1" {
            Write-Host "Sign in with the ChatGPT account that owns the subscription. Do not choose an API-key route."
            Invoke-InteractiveNative $claw @(
                "onboard", "--auth-choice", "openai", "--install-daemon",
                "--skip-search", "--skip-channels", "--skip-skills"
            )
        }
        "2" {
            Install-ManagedClaudeCode
            $claude = $script:ManagedClaudePath
            Write-Host "Choose the Claude.ai Pro/Max subscription account, not Anthropic Console billing."
            Invoke-InteractiveNative $claude @("auth", "login", "--claudeai")
            if ((Invoke-Native $claude @("auth", "status", "--text") -AllowFailure) -ne 0) {
                Stop-WithError "Claude Code subscription sign-in did not complete."
            }
            Invoke-InteractiveNative $claw @(
                "onboard", "--auth-choice", "anthropic-cli", "--install-daemon",
                "--skip-search", "--skip-channels", "--skip-skills"
            )
            [void](Invoke-Native $claw @("config", "set", "agents.defaults.cliBackends.claude-cli.command", $claude))
        }
        default { Stop-WithError "Choose 1 for ChatGPT or 2 for Claude Code." }
    }
    [void](Invoke-Native $claw @("gateway", "install"))
    [void](Invoke-Native $claw @("gateway", "restart"))
}

function Install-Tailscale {
    $tailscale = Get-Tailscale
    if ($null -eq $tailscale) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -ne $winget) {
            Write-Info "Installing the official Tailscale Windows app"
            [void](Invoke-Native $winget.Source @("install", "--id", "Tailscale.Tailscale", "--exact", "--accept-package-agreements", "--accept-source-agreements"))
        } else {
            Write-Warn "WinGet is unavailable. Opening Tailscale's official Windows download page."
            Start-Process "https://tailscale.com/download/windows"
            Write-Host "Install Tailscale, open it, and sign in with your preferred account."
            Wait-Ready
        }
        $tailscale = Get-Tailscale
    }
    if ($null -eq $tailscale) {
        Write-Warn "Tailscale's command tool is not available yet. Finish app setup, then rerun this kit."
        return $false
    }
    $statusCode = Invoke-Native $tailscale @("status") -AllowFailure
    if ($statusCode -ne 0) {
        Write-Host "A browser may open. Sign in and approve this PC in your tailnet."
        if (Test-Administrator) {
            [void](Invoke-Native $tailscale @("up", "--unattended=true"))
        } else {
            [void](Invoke-Native $tailscale @("up"))
            Write-Warn "For access before Windows login, enable Tailscale tray > Preferences > Run unattended as an administrator."
        }
    }
    if ((Invoke-Native $tailscale @("status") -AllowFailure) -ne 0) {
        Write-Warn "Tailscale is not connected, so private remote WebChat was not enabled."
        return $false
    }
    Write-Ok "Tailscale is connected"
    return $true
}

function Set-PrivateRemoteAccess {
    Write-Host ""
    Write-Host "Private remote access" -ForegroundColor White
    Write-Host "Tailscale Serve makes WebChat reachable only from devices in your tailnet."
    Write-Host "It does not expose OpenClaw to the public internet."
    if (Confirm-Step "Set up private Tailscale access?" $true) {
        if (Install-Tailscale) {
            $claw = Get-OpenClaw
            [void](Invoke-Native $claw @("config", "set", "gateway.bind", "loopback"))
            [void](Invoke-Native $claw @("config", "set", "gateway.auth.mode", "token"))
            [void](Invoke-Native $claw @("config", "set", "gateway.auth.allowTailscale", "true", "--strict-json"))
            [void](Invoke-Native $claw @("config", "set", "gateway.controlUi.allowInsecureAuth", "false", "--strict-json"))
            [void](Invoke-Native $claw @("config", "set", "gateway.tailscale.mode", "serve"))
            [void](Invoke-Native $claw @("gateway", "restart"))
            Write-Ok "Tailscale Serve is configured; public Funnel remains disabled"
        }
    }
}

function Set-AlwaysOn {
    Write-Host ""
    Write-Host "Keep the bot alive" -ForegroundColor White
    Write-Host "OpenClaw already has a Scheduled Task that restarts it after a crash."
    Write-Host "The next setting prevents sleep while this PC is plugged into power."
    if (Confirm-Step "Keep the PC awake while plugged in?" $true) {
        [void](Invoke-Native "powercfg.exe" @("/change", "standby-timeout-ac", "0"))
        Write-Ok "Plugged-in sleep disabled; battery sleep was left unchanged"
    }
    if (-not (Test-Administrator)) {
        Write-Warn "Tailscale unattended mode and system-wide SSH need an Administrator PowerShell window."
    }
}

function Set-SshAccess {
    Write-Host ""
    Write-Host "Optional terminal access (SSH)" -ForegroundColor White
    Write-Host "Tailscale Serve is enough for WebChat. SSH is only for remote administration."
    Write-Host "Windows cannot host Tailscale SSH, so this uses Windows OpenSSH and a tailnet-only firewall rule."
    if (-not (Confirm-Step "Enable SSH for Tailscale devices?" $false)) { return }
    if (-not (Test-Administrator)) {
        Write-Warn "SSH was not changed. Rerun this script from 'PowerShell (Administrator)' to enable it."
        return
    }
    Write-Host "  PS> Install Windows OpenSSH Server; start it automatically" -ForegroundColor DarkCyan
    $capability = Get-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0"
    if ($capability.State -ne "Installed") {
        Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null
    }
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic

    $defaultRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
    if ($null -ne $defaultRule) { Disable-NetFirewallRule -Name "OpenSSH-Server-In-TCP" | Out-Null }
    $tailRule = Get-NetFirewallRule -Name "OpenClaw-SSH-Tailnet" -ErrorAction SilentlyContinue
    if ($null -eq $tailRule) {
        New-NetFirewallRule -Name "OpenClaw-SSH-Tailnet" -DisplayName "OpenClaw SSH (Tailscale only)" `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 `
            -RemoteAddress "100.64.0.0/10", "fd7a:115c:a1e0::/48" | Out-Null
    } else {
        Set-NetFirewallRule -Name "OpenClaw-SSH-Tailnet" -Enabled True -Direction Inbound -Action Allow | Out-Null
        Get-NetFirewallRule -Name "OpenClaw-SSH-Tailnet" | Get-NetFirewallAddressFilter | `
            Set-NetFirewallAddressFilter -RemoteAddress "100.64.0.0/10", "fd7a:115c:a1e0::/48" | Out-Null
    }
    Write-Ok "Windows OpenSSH is running and restricted to Tailscale addresses"
    Write-Host "Connect from another Tailscale device with: ssh $env:USERNAME@<this-pc-name>"
}

function Open-FirstChat {
    $claw = Get-OpenClaw
    Write-Host ""
    Write-Host "Your first chat" -ForegroundColor White
    Write-Host "Opening OpenClaw's built-in WebChat. It needs no extra account or token."
    [void](Invoke-Native $claw @("dashboard"))
}

function Add-ChatChannel {
    $claw = Get-OpenClaw
    @"

Add a separate phone-friendly bot account now:
  1) Telegram - recommended; create a new dedicated BotFather bot
  2) Discord - create a new dedicated bot in the Developer Portal
  3) WhatsApp - separate number/account only; never link a personal account
  4) Not now - keep using WebChat
"@ | Write-Host
    $choice = if ($Defaults) { "4" } else { Read-Host "Choose [1-4, default 1]" }
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    switch ($choice) {
        "1" {
            @"

Telegram setup:
  1. Open https://t.me/BotFather and confirm the handle is exactly @BotFather.
  2. Send /newbot, choose a name and username, then copy the bot token.
  3. Return here. OpenClaw's masked wizard will ask for the token.
"@ | Write-Host
            Start-Process "https://t.me/BotFather"
            Wait-Ready
            [void](Invoke-Native $claw @("channels", "add", "--channel", "telegram"))
            [void](Invoke-Native $claw @("gateway", "restart"))
            Write-Host "Send /start to your new bot in Telegram, then return here."
            Wait-Ready
            [void](Invoke-Native $claw @("pairing", "list", "telegram"))
            if (-not $Defaults) {
                $code = Read-Host "Pairing code shown above (leave blank to approve later)"
                if (-not [string]::IsNullOrWhiteSpace($code)) {
                    if ($code -notmatch '^[A-Za-z0-9_-]+$') { Stop-WithError "Pairing code contains unexpected characters." }
                    [void](Invoke-Native $claw @("pairing", "approve", "telegram", $code))
                }
            }
        }
        "2" {
            @"

Discord setup:
  1. Open https://discord.com/developers/applications and create an application.
  2. Open Bot, create/reset the token, and copy it.
  3. Enable only the intents OpenClaw's wizard requests.
  4. Return here and use the masked setup wizard.
"@ | Write-Host
            Start-Process "https://discord.com/developers/applications"
            Wait-Ready
            [void](Invoke-Native $claw @("channels", "add", "--channel", "discord"))
            [void](Invoke-Native $claw @("gateway", "restart"))
        }
        "3" {
            Write-Warn "Do not link your everyday WhatsApp account. Use a separate account with no personal chat history."
            if (-not (Confirm-Step "I have a separate WhatsApp account for this bot." $false)) {
                Stop-WithError "WhatsApp setup stopped; WebChat is still available."
            }
            Write-Host "OpenClaw will install its official WhatsApp plugin and guide QR login."
            [void](Invoke-Native $claw @("channels", "add", "--channel", "whatsapp"))
            [void](Invoke-Native $claw @("channels", "login", "--channel", "whatsapp"))
            [void](Invoke-Native $claw @("gateway", "restart"))
        }
        "4" { Write-Ok "WebChat remains the active chat interface" }
        default { Stop-WithError "Choose a number from 1 to 4." }
    }
}

function Test-Setup {
    $overall = 0
    Write-Host "OpenClaw Safe Start - diagnostics" -ForegroundColor White
    $claw = Get-OpenClaw
    if ($null -eq $claw) {
        Write-Warn "OpenClaw is not on PATH"
        $overall = 1
    } else {
        $version = (& $claw --version 2>$null | Out-String).Trim()
        Write-Ok "OpenClaw found: $version"
        $checks = @(
            @{ Args = @("doctor", "--non-interactive") },
            @{ Args = @("gateway", "status", "--json") },
            @{ Args = @("channels", "status", "--probe") },
            @{ Args = @("security", "audit", "--deep") }
        )
        foreach ($item in $checks) {
            if ((Invoke-Native $claw $item.Args -AllowFailure) -ne 0) { $overall = 1 }
        }
    }
    $tailscale = Get-Tailscale
    if ($null -eq $tailscale) {
        Write-Warn "Tailscale is not installed"
    } elseif ((Invoke-Native $tailscale @("status") -AllowFailure) -eq 0) {
        Write-Ok "Tailscale is connected"
    } else {
        Write-Warn "Tailscale is installed but not connected"
    }
    return $overall
}

function Complete-Checks {
    $claw = Get-OpenClaw
    $failed = $false
    Write-Host ""
    Write-Host "Final checks" -ForegroundColor White
    $checks = @(
        @{ Args = @("doctor", "--non-interactive") },
        @{ Args = @("gateway", "status", "--json") },
        @{ Args = @("channels", "status", "--probe") },
        @{ Args = @("security", "audit", "--deep") }
    )
    foreach ($item in $checks) {
        if ((Invoke-Native $claw $item.Args -AllowFailure) -ne 0) { $failed = $true }
    }
    if ($failed) {
        Write-Warn "First-chat setup finished, but at least one final check needs attention. Run -Check after using the troubleshooting guide."
    } else {
        Write-Ok "Setup is complete"
    }
    Write-Host ""
    Write-Host "Chat now: openclaw dashboard"
    Write-Host "Diagnose later: powershell -ExecutionPolicy Bypass -File `"$ScriptRoot\install-windows.ps1`" -Check"
    Write-Host "Troubleshooting: $ScriptRoot\docs\TROUBLESHOOTING.md"
}

if ($Help) { Show-Usage; exit 0 }
Import-Pins
if ($DryRun) { Show-Plan; exit 0 }
if ($Verify) {
    $installer = Get-VerifiedInstaller
    Remove-Item -LiteralPath $installer -Force -ErrorAction SilentlyContinue
    $claudePackage = Get-VerifiedClaudePackage
    Remove-Item -LiteralPath $claudePackage -Force -ErrorAction SilentlyContinue
    Write-Ok "Pinned Windows and Claude Code bootstrap files verified and were not run"
    exit 0
}
if ($Check) { exit (Test-Setup) }

Write-Host "OpenClaw Safe Start" -ForegroundColor White
Write-Host "A short, reviewed path from a new PC to a working AI chat."
Write-Host "Pinned OpenClaw: $($Pins.OPENCLAW_VERSION)"
Write-Host ""
if (Confirm-Step "Show the dry-run plan before starting?" $true) { Show-Plan }
Wait-Ready

Confirm-SafeStart
Install-OpenClaw
Start-Onboarding
Protect-OpenClaw
Open-FirstChat
Add-ChatChannel
Set-PrivateRemoteAccess
Set-AlwaysOn
Set-SshAccess
Complete-Checks
