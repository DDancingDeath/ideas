<#
.SYNOPSIS
    Scaffold a new Copilot CLI skill locally and either create a GitHub repo (DDancingDeath/skill-<slug>)
    or open a PR to the configured ADO skills repo.

.PARAMETER Slug
    Lowercase-hyphenated short name (e.g., "ado-bug-triage").

.PARAMETER Target
    "github" (default) -> creates DDancingDeath/skill-<slug> via gh.
    "ado"              -> clones the ADO repo from tools/config.json, branches, scaffolds, pushes, opens PR.

.PARAMETER Title
    Display title. Default: title-cased slug.

.PARAMETER Description
    One-paragraph description used in the skill manifest. Default: TODO placeholder.

.PARAMETER WorkRoot
    Where to clone/create the working directory. Default: D:\work.

.PARAMETER NoPush
    Scaffold locally; do not push or create PR.

.EXAMPLE
    .\tools\add-skill.ps1 -Slug ado-bug-triage -Target github -Title "ADO Bug Triage"

.EXAMPLE
    .\tools\add-skill.ps1 -Slug winui-perf-review -Target ado -Title "WinUI Perf Review"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Slug,
    [ValidateSet('github','ado')][string]$Target,
    [string]$Title,
    [string]$Description,
    [string]$WorkRoot = 'D:\work',
    [switch]$NoPush
)

. "$PSScriptRoot\_common.ps1"

function Scaffold-SkillFiles {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$TemplateDir,
        [Parameter(Mandatory)][hashtable]$Tokens
    )
    Write-Step "Scaffolding skill at $Root ..."
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    Get-ChildItem -Path $TemplateDir -File -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($TemplateDir.Length).TrimStart('\','/')
        $dest = Join-Path $Root $rel
        Expand-TemplateFile -SourcePath $_.FullName -DestinationPath $dest -Tokens $Tokens
    }
    Write-Ok "Scaffold complete."
}

Test-Slug $Slug
$cfg = Get-ToolsConfig
if (-not $Target) { $Target = $cfg.skills.defaultTarget }
if (-not $Title) { $Title = ($Slug -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' ' }
if (-not $Description) { $Description = "TODO: one-paragraph description of the '$Slug' skill (what it does, when to use it, key triggers)." }

$repoRoot = Get-RepoRoot
$templates = Join-Path $repoRoot '_templates\skill'
if (-not (Test-Path $templates)) { throw "Missing skill template at $templates" }
$today = (Get-Date -Format 'yyyy-MM-dd')

$tokens = @{
    SLUG        = $Slug
    TITLE       = $Title
    DESCRIPTION = $Description
    DATE        = $today
    TARGET      = $Target
}

if (-not (Test-Path $WorkRoot)) { New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null }

switch ($Target) {
    'github' {
        Assert-GhAuth
        $owner = $cfg.skills.github.owner
        $repoName = Resolve-Pattern $cfg.skills.github.repoPattern @{ slug = $Slug }
        $fullName = "$owner/$repoName"
        $clonePath = Join-Path $WorkRoot $repoName

        Write-Step "Creating private GitHub repo $fullName ..."
        if (Test-Path $clonePath) { throw "Local clone target already exists: $clonePath" }
        $visibility = if ($cfg.skills.github.private) { '--private' } else { '--public' }
        gh repo create $fullName $visibility --description $Description 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "gh repo create failed." }
        Push-Location $WorkRoot
        try { gh repo clone $fullName $repoName | Out-Null } finally { Pop-Location }
        Write-Ok "Repo created and cloned to $clonePath"

        Scaffold-SkillFiles -Root $clonePath -TemplateDir $templates -Tokens $tokens

        if ($cfg.skills.github.topic) {
            gh repo edit $fullName --add-topic $cfg.skills.github.topic 2>&1 | Out-Null
        }

        if ($NoPush) { Write-Warn "Skipping initial push (-NoPush)."; break }
        Invoke-Git -WorkingDir $clonePath add -A
        Invoke-Git -WorkingDir $clonePath commit -m "Initial scaffold of skill '$Slug'`n`n$($cfg.git.coAuthor)"
        Invoke-Git -WorkingDir $clonePath push -u origin HEAD
        Write-Ok "Pushed to $fullName."
        Write-Host ""
        Write-Host "Done. Skill repo: https://github.com/$fullName" -ForegroundColor Cyan
    }

    'ado' {
        if ($cfg.skills.ado.repoName -like 'TODO*') {
            throw "tools/config.json -> skills.ado.repoName is not set. Edit it before using -Target ado."
        }
        Assert-AzDevOps
        $org   = $cfg.skills.ado.organization
        $proj  = $cfg.skills.ado.project
        $repo  = $cfg.skills.ado.repoName
        $orgUrl = "https://dev.azure.com/$org"
        $cloneUrl = "$orgUrl/$proj/_git/$repo"
        $clonePath = Join-Path $WorkRoot $repo

        Write-Step "Cloning $cloneUrl ..."
        if (-not (Test-Path $clonePath)) {
            Push-Location $WorkRoot
            try { git clone $cloneUrl } finally { Pop-Location }
            if ($LASTEXITCODE -ne 0) { throw "git clone failed." }
        } else {
            Invoke-Git -WorkingDir $clonePath fetch origin
            Invoke-Git -WorkingDir $clonePath checkout main
            Invoke-Git -WorkingDir $clonePath pull --ff-only
        }

        $user = Get-GitUserAlias
        $branch = Resolve-Pattern $cfg.skills.ado.branchPattern @{ slug = $Slug; user = $user }
        Invoke-Git -WorkingDir $clonePath checkout -b $branch

        $skillRel = Resolve-Pattern $cfg.skills.ado.skillsDir @{ slug = $Slug }
        $skillAbs = Join-Path $clonePath $skillRel
        Scaffold-SkillFiles -Root $skillAbs -TemplateDir $templates -Tokens $tokens

        if ($NoPush) { Write-Warn "Skipping push/PR (-NoPush)."; break }
        Invoke-Git -WorkingDir $clonePath add -- $skillRel
        Invoke-Git -WorkingDir $clonePath commit -m "Add skill: $Slug`n`n$($cfg.git.coAuthor)"
        Invoke-Git -WorkingDir $clonePath push -u origin $branch

        $prTitle = Resolve-Pattern $cfg.skills.ado.prTitlePattern @{ slug = $Slug }
        Write-Step "Opening PR ..."
        $reviewerArgs = @()
        if ($cfg.skills.ado.reviewers) { $reviewerArgs = @('--reviewers') + $cfg.skills.ado.reviewers }
        az repos pr create `
            --organization $orgUrl `
            --project $proj `
            --repository $repo `
            --source-branch $branch `
            --target-branch main `
            --title $prTitle `
            --description "Initial scaffold of skill '$Slug'." `
            @reviewerArgs `
            --open
        if ($LASTEXITCODE -ne 0) { throw "az repos pr create failed." }
        Write-Ok "PR opened."
    }
}
