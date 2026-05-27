<#
.SYNOPSIS
    Scaffold a new idea under projects/<kind>/<slug>/ in this repo, then commit and push.

.PARAMETER Slug
    Lowercase-hyphenated short name (e.g., "shop-floor-clock-in"). Becomes the folder name.

.PARAMETER Kind
    "apps" (real products) or "agents" (AI agent ideas). Default: agents.

.PARAMETER Title
    Display title for the project. Default: title-cased slug.

.PARAMETER Pitch
    One-paragraph pitch used as the README blockquote. Default: TODO placeholder.

.PARAMETER NoCommit
    Skip git add/commit (handy for review-before-commit).

.PARAMETER NoPush
    Commit locally but do not push.

.EXAMPLE
    .\tools\add-idea.ps1 -Slug shop-floor-clock-in -Kind apps -Title "Shop-floor clock-in" `
        -Pitch "A frictionless way for retail staff to clock in via a tablet at the counter."
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Slug,
    [ValidateSet('apps','agents')][string]$Kind = 'agents',
    [string]$Title,
    [string]$Pitch,
    [switch]$NoCommit,
    [switch]$NoPush
)

. "$PSScriptRoot\_common.ps1"

Test-Slug $Slug
if (-not $Title) { $Title = ($Slug -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' ' }
if (-not $Pitch) { $Pitch = 'TODO(idea): replace this with the one-paragraph pitch (who uses it, what it does, what makes it different).' }

$repoRoot = Get-RepoRoot
$projectDir = Join-Path $repoRoot "projects\$Kind\$Slug"
if (Test-Path $projectDir) {
    throw "Project already exists: $projectDir"
}

$templates = Join-Path $repoRoot '_templates'
$today = (Get-Date -Format 'yyyy-MM-dd')
$tokens = @{
    SLUG  = $Slug
    KIND  = $Kind
    TITLE = $Title
    PITCH = $Pitch
    DATE  = $today
}

Write-Step "Scaffolding projects/$Kind/$Slug ..."
New-Item -ItemType Directory -Path $projectDir, "$projectDir\spec", "$projectDir\plan", "$projectDir\prompts", "$projectDir\assets" -Force | Out-Null
New-Item -ItemType File -Path "$projectDir\assets\.gitkeep" -Force | Out-Null

function Copy-IdeaTemplate {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Title,
        [string]$Pitch,
        [string]$Date
    )
    $content = Get-Content -Raw -Path $Source

    # Replace the literal <Project name> placeholder used across the existing templates.
    $content = $content -replace '<Project name>', [regex]::Escape($Title).Replace('\','')

    # project-readme.md has a 2-line "One-paragraph pitch" blockquote we replace with the user's pitch.
    if ($Pitch) {
        $pattern = '> One-paragraph pitch\. Replace this with what the thing \*\*is\*\* in plain\r?\n> words: who uses it, what it does for them, what makes it different\.'
        $content = [regex]::Replace($content, $pattern, "> $($Pitch -replace '\r?\n',' ')")

        # idea.md has its own (different) one-sentence pitch line.
        $ideaPattern = '> One-sentence pitch\. Replace this line with what this thing \*is\* in plain\r?\n> language, no jargon\.'
        $content = [regex]::Replace($content, $ideaPattern, "> $($Pitch -replace '\r?\n',' ')")
    }

    # Stamp the "Recent changes" date on project-readme.md.
    if ($Date) {
        $content = $content -replace '- _YYYY-MM-DD_ · …', "- _${Date}_ · initial scaffold"
    }

    Set-Content -Path $Destination -Value $content -Encoding UTF8
}

Copy-IdeaTemplate -Source "$templates\project-readme.md" -Destination "$projectDir\README.md"            -Title $Title -Pitch $Pitch -Date $today
Copy-IdeaTemplate -Source "$templates\idea.md"           -Destination "$projectDir\idea.md"              -Title $Title -Pitch $Pitch
Copy-IdeaTemplate -Source "$templates\spec.md"           -Destination "$projectDir\spec\README.md"       -Title $Title
Copy-IdeaTemplate -Source "$templates\plan.md"           -Destination "$projectDir\plan\README.md"       -Title $Title
Copy-IdeaTemplate -Source "$templates\build-prompt.md"   -Destination "$projectDir\prompts\build-from-spec.md" -Title $Title
Write-Ok "Created 6 files in $projectDir"

Write-Warn "TODO: update the top-level README projects table to list this new idea."

if ($NoCommit) {
    Write-Warn "Skipping git commit (-NoCommit)."
    return
}

$cfg = Get-ToolsConfig
Write-Step "Committing ..."
Invoke-Git -WorkingDir $repoRoot add -- "projects/$Kind/$Slug"
$msg = "Add idea: $Kind/$Slug`n`n$Title`n`n$($cfg.git.coAuthor)"
Invoke-Git -WorkingDir $repoRoot commit -m $msg
Write-Ok "Committed."

if ($NoPush) { Write-Warn "Skipping git push (-NoPush)."; return }

Write-Step "Pushing to origin ..."
Invoke-Git -WorkingDir $repoRoot push origin HEAD
Write-Ok "Pushed."

Write-Host ""
Write-Host "Done. Next:" -ForegroundColor Cyan
Write-Host "  1. Open  projects/$Kind/$Slug/README.md  and fill in the pitch + 'How it works'." -ForegroundColor Gray
Write-Host "  2. Open  projects/$Kind/$Slug/idea.md    and resolve TODO(idea) markers." -ForegroundColor Gray
Write-Host "  3. Update the top-level README.md projects table to include this idea." -ForegroundColor Gray
