param(
    [AllowEmptyString()]
    [string]$ContainerName,
    [string]$ProfilePath = $PROFILE,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$defaultContainerName = "sspworkflow"
if ([string]::IsNullOrWhiteSpace($ContainerName)) {
    $ContainerName = $defaultContainerName
}

function Get-ContainerRuntime {
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        return "podman"
    }
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        return "docker"
    }
    throw "Neither podman nor docker is available in PATH."
}

function Get-RecipeNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Runtime,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $helpLines = & $Runtime exec $Name /bin/bash -lc "cd /root/sspworkflow/work && runConversionChain help" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $joined = $helpLines -join [Environment]::NewLine
        throw "Could not read recipes from container '$Name'. Start the container first with sspworkflow-run-prod.ps1. Details:$([Environment]::NewLine)$joined"
    }

    $recipes = [System.Collections.Generic.List[string]]::new()
    $inRecipeSection = $false

    foreach ($line in $helpLines) {
        if ($line -match '^\s*Available recipes:\s*$') {
            $inRecipeSection = $true
            continue
        }

        if (-not $inRecipeSection) {
            continue
        }

        if ($line -match '^\s{4}([a-zA-Z0-9-]+)\s+#') {
            $recipes.Add($matches[1])
            continue
        }

        if ($line -match '^\S') {
            break
        }
    }

    return $recipes | Sort-Object -Unique
}

$runtime = Get-ContainerRuntime
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wrapperPath = Join-Path $repoRoot "runConversionChain.ps1"
$completionPath = Join-Path $HOME ".sspworkflow-completion.ps1"

$staticCompletions = @(
    "theme=",
    "debug=true",
    "validate=true",
    "develop=true",
    "pagedjs-polyfill=true",
    "docx-file=",
    "xml-file=",
    "html-file="
)

$recipeNames = Get-RecipeNames -Runtime $runtime -Name $ContainerName
$allCompletions = @($staticCompletions + $recipeNames) | Sort-Object -Unique
$quotedCompletions = $allCompletions | ForEach-Object { "'$_'" }
$completionLiteral = ($quotedCompletions -join ", ")

$completionScript = @"
`$global:SspworkflowCompletions = @($completionLiteral)

function global:runConversionChain {
    param(
        [Parameter(Position = 0)]
        [ArgumentCompleter({
            param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)

            foreach (`$entry in `$global:SspworkflowCompletions) {
                if (`$entry -like "`$wordToComplete*") {
                    [System.Management.Automation.CompletionResult]::new(`$entry, `$entry, 'ParameterValue', `$entry)
                }
            }
        })]
        [string]`$FirstArgument,

        [Parameter(Position = 1, ValueFromRemainingArguments = `$true)]
        [string[]]`$RemainingArgs
    )

    if ([string]::IsNullOrWhiteSpace(`$FirstArgument)) {
        & "$wrapperPath" @RemainingArgs
    }
    else {
        & "$wrapperPath" `$FirstArgument @RemainingArgs
    }
}

Set-Alias -Name rcc -Value runConversionChain -Scope Global

Register-ArgumentCompleter -CommandName 'runConversionChain.ps1' -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)

    foreach (`$entry in `$global:SspworkflowCompletions) {
        if (`$entry -like "`$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new(`$entry, `$entry, 'ParameterValue', `$entry)
        }
    }
}
"@

if ((Test-Path $completionPath) -and -not $Force) {
    Write-Host "Updating existing completion file at $completionPath"
}

Set-Content -Path $completionPath -Value $completionScript -Encoding UTF8

$profileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

$sourceLine = ". `"$completionPath`""
$profileContent = Get-Content -Path $ProfilePath -Raw
if (-not ($profileContent -match [regex]::Escape($sourceLine))) {
    Add-Content -Path $ProfilePath -Value "`n$sourceLine"
    Write-Host "Added completion import to profile: $ProfilePath"
}
else {
    Write-Host "Profile already imports completion file: $ProfilePath"
}

. $completionPath
. $ProfilePath

Write-Host "PowerShell completion is configured for runConversionChain, runConversionChain.ps1 and rcc."
Write-Host "Current session reloaded profile: $ProfilePath"
