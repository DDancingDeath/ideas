# Shared helpers for the add-idea / add-skill / add-agent scripts.
# Dot-source this file from each script: `. "$PSScriptRoot\_common.ps1"`

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    # tools/ lives at the repo root; the parent of $PSScriptRoot is the repo root.
    $root = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $root '.git'))) {
        throw "Could not locate repo root from '$PSScriptRoot' (no .git found at '$root')."
    }
    return $root
}

function Get-ToolsConfig {
    $cfgPath = Join-Path $PSScriptRoot 'config.json'
    if (-not (Test-Path $cfgPath)) {
        throw "Missing tools/config.json at '$cfgPath'."
    }
    return Get-Content $cfgPath -Raw | ConvertFrom-Json
}

function Test-Slug {
    param([string]$Slug)
    if ($Slug -notmatch '^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$') {
        throw "Slug '$Slug' is invalid. Use lowercase letters, digits, and hyphens (3-50 chars, no leading/trailing hyphen)."
    }
}

function Resolve-Pattern {
    param(
        [string]$Pattern,
        [hashtable]$Tokens
    )
    $result = $Pattern
    foreach ($k in $Tokens.Keys) {
        $result = $result.Replace("{$k}", [string]$Tokens[$k])
    }
    return $result
}

function Assert-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' not found in PATH.$(if ($InstallHint) { " Install: $InstallHint" })"
    }
}

function Assert-GhAuth {
    Assert-Command gh 'https://cli.github.com/'
    $status = gh auth status 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $status -notmatch 'Logged in') {
        throw "gh CLI is not authenticated. Run: gh auth login"
    }
}

function Assert-AzDevOps {
    Assert-Command az 'https://aka.ms/installazurecliwindows'
    $ext = az extension list --query "[?name=='azure-devops'].name" -o tsv 2>$null
    if (-not $ext) {
        Write-Host "Installing az 'azure-devops' extension..." -ForegroundColor Yellow
        az extension add --name azure-devops --only-show-errors | Out-Null
    }
}

function Get-GitUserAlias {
    if ($env:USERNAME) { return ($env:USERNAME -replace '[^a-zA-Z0-9]', '').ToLowerInvariant() }
    return 'me'
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$WorkingDir,
        [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Args
    )
    Push-Location $WorkingDir
    try {
        $cfg = Get-ToolsConfig
        $allArgs = @(
            '-c', "user.name=$($cfg.git.userName)",
            '-c', "user.email=$($cfg.git.userEmail)"
        ) + $Args
        & git @allArgs
        if ($LASTEXITCODE -ne 0) {
            throw "git $($Args -join ' ') failed (exit $LASTEXITCODE)"
        }
    } finally {
        Pop-Location
    }
}

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor Yellow }

function Expand-TemplateFile {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][hashtable]$Tokens
    )
    $content = Get-Content -Raw -Path $SourcePath
    foreach ($k in $Tokens.Keys) {
        $content = $content -replace [regex]::Escape("{{$k}}"), [string]$Tokens[$k]
    }
    $dir = Split-Path -Parent $DestinationPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $DestinationPath -Value $content -Encoding UTF8
}
