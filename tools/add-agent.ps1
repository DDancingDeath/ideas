<#
.SYNOPSIS
    Scaffold a new agent locally and either create a GitHub repo (DDancingDeath/agent-<slug>)
    or open a PR to the configured ADO agents repo.

    Mirror of add-skill.ps1 with the "agents" config block + agent template.

.PARAMETER Slug
    Lowercase-hyphenated short name.

.PARAMETER Target
    "github" (default) or "ado".

.PARAMETER Domain
    Only used with -Target ado. Domain folder under agents/ (e.g. os, ado, winui, triage, meta).
    Defaults to agents.ado.defaultDomain from config.json.

.PARAMETER Title
    Display title.

.PARAMETER Description
    One-paragraph description.

.PARAMETER WorkRoot
    Working directory root. Default D:\work.

.PARAMETER NoPush
    Scaffold locally only.

.EXAMPLE
    .\tools\add-agent.ps1 -Slug morning-brief -Target github
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Slug,
    [ValidateSet('github','ado')][string]$Target,
    [string]$Domain,
    [string]$Title,
    [string]$Description,
    [string]$WorkRoot = 'D:\work',
    [switch]$NoPush
)

. "$PSScriptRoot\_common.ps1"

function Scaffold-AgentFiles {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$TemplateDir,
        [Parameter(Mandatory)][hashtable]$Tokens
    )
    Write-Step "Scaffolding agent at $Root ..."
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
if (-not $Target) { $Target = $cfg.agents.defaultTarget }
if (-not $Title) { $Title = ($Slug -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' ' }
if (-not $Description) { $Description = "TODO: one-paragraph description of the '$Slug' agent (what task it owns, how it is invoked, what it returns)." }

$repoRoot = Get-RepoRoot
$templates = Join-Path $repoRoot '_templates\agent'
if (-not (Test-Path $templates)) { throw "Missing agent template at $templates" }
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
        $owner = $cfg.agents.github.owner
        $repoName = Resolve-Pattern $cfg.agents.github.repoPattern @{ slug = $Slug }
        $fullName = "$owner/$repoName"
        $clonePath = Join-Path $WorkRoot $repoName

        Write-Step "Creating private GitHub repo $fullName ..."
        if (Test-Path $clonePath) { throw "Local clone target already exists: $clonePath" }
        $visibility = if ($cfg.agents.github.private) { '--private' } else { '--public' }
        gh repo create $fullName $visibility --description $Description 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "gh repo create failed." }
        Push-Location $WorkRoot
        try { gh repo clone $fullName $repoName | Out-Null } finally { Pop-Location }
        Write-Ok "Repo created and cloned to $clonePath"

        Scaffold-AgentFiles -Root $clonePath -TemplateDir $templates -Tokens $tokens

        if ($cfg.agents.github.topic) {
            gh repo edit $fullName --add-topic $cfg.agents.github.topic 2>&1 | Out-Null
        }

        if ($NoPush) { Write-Warn "Skipping initial push (-NoPush)."; break }
        Invoke-Git -WorkingDir $clonePath add -A
        Invoke-Git -WorkingDir $clonePath commit -m "Initial scaffold of agent '$Slug'`n`n$($cfg.git.coAuthor)"
        Invoke-Git -WorkingDir $clonePath push -u origin HEAD
        Write-Ok "Pushed to $fullName."
        Write-Host ""
        Write-Host "Done. Agent repo: https://github.com/$fullName" -ForegroundColor Cyan
    }

    'ado' {
        if ($cfg.agents.ado.repoName -like 'TODO*') {
            throw "tools/config.json -> agents.ado.repoName is not set. Edit it before using -Target ado."
        }
        Assert-AzDevOps
        if (-not $Domain) { $Domain = $cfg.agents.ado.defaultDomain }
        if (-not $Domain) { throw "Provide -Domain or set agents.ado.defaultDomain in config.json." }
        $known = @($cfg.agents.ado.knownDomains)
        if ($known -and ($Domain -notin $known)) {
            Write-Warn "Domain '$Domain' is not in knownDomains ($($known -join ', ')). Proceeding anyway; update agents/README.md to register the new domain."
        }

        $org   = $cfg.agents.ado.organization
        $proj  = $cfg.agents.ado.project
        $repo  = $cfg.agents.ado.repoName
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
        $branch = Resolve-Pattern $cfg.agents.ado.branchPattern @{ slug = $Slug; user = $user; domain = $Domain }
        Invoke-Git -WorkingDir $clonePath checkout -b $branch

        $agentRel = Resolve-Pattern $cfg.agents.ado.agentsDir @{ slug = $Slug; domain = $Domain }
        $agentAbs = Join-Path $clonePath $agentRel
        if (Test-Path $agentAbs) { throw "Agent directory already exists in repo: $agentRel" }
        Scaffold-AgentFiles -Root $agentAbs -TemplateDir $templates -Tokens $tokens

        if ($NoPush) {
            Write-Warn "Skipping push/PR (-NoPush)."
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  1. Edit $agentRel/AGENT.md - replace TODOs with real content." -ForegroundColor Gray
            Write-Host "  2. Update $($cfg.agents.ado.catalogFile) - add a row to the catalog table." -ForegroundColor Gray
            Write-Host "  3. Re-run without -NoPush to commit and open the PR." -ForegroundColor Gray
            break
        }
        Invoke-Git -WorkingDir $clonePath add -- $agentRel
        Invoke-Git -WorkingDir $clonePath commit -m "Add agent: $Slug`n`n$($cfg.git.coAuthor)"
        Invoke-Git -WorkingDir $clonePath push -u origin $branch

        $prTitle = Resolve-Pattern $cfg.agents.ado.prTitlePattern @{ slug = $Slug; domain = $Domain }
        Write-Step "Opening PR ..."
        $reviewerArgs = @()
        if ($cfg.agents.ado.reviewers) { $reviewerArgs = @('--reviewers') + $cfg.agents.ado.reviewers }
        az repos pr create `
            --organization $orgUrl `
            --project $proj `
            --repository $repo `
            --source-branch $branch `
            --target-branch main `
            --title $prTitle `
            --description "Initial scaffold of agent '$Slug' under domain '$Domain'.`n`nReminder: update $($cfg.agents.ado.catalogFile) catalog table before merge." `
            @reviewerArgs `
            --open
        if ($LASTEXITCODE -ne 0) { throw "az repos pr create failed." }
        Write-Ok "PR opened."
        Write-Warn "Don't forget to update $($cfg.agents.ado.catalogFile) catalog table in a follow-up commit on this branch."
    }
}
