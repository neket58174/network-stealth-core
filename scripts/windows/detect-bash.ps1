param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Convert-ToShellPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $resolved = $Path.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        return ""
    }

    if ($resolved -match "\s" -and (Test-Path -LiteralPath $resolved)) {
        $short = cmd /c "for %I in (""$resolved"") do @echo %~sI" 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($short)) {
            $shortTrimmed = $short.Trim()
            if (Test-Path -LiteralPath $shortTrimmed) {
                $resolved = $shortTrimmed
            }
        }
    }

    return ($resolved -replace "\\", "/")
}

function Resolve-CandidatePath {
    param(
        [Parameter(Mandatory = $false)]
        [string] $Candidate
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return ""
    }

    $trimmed = $Candidate.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $trimmed)) {
        return ""
    }

    return (Convert-ToShellPath -Path $trimmed)
}

$resolved = Resolve-CandidatePath -Candidate $env:BASH_EXE
if (-not [string]::IsNullOrWhiteSpace($resolved)) {
    Write-Output $resolved
    exit 0
}

$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd) {
    $sourcePath = $bashCmd.Source
    if ($sourcePath -match "\.exe$") {
        $resolved = Resolve-CandidatePath -Candidate $sourcePath
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            Write-Output $resolved
            exit 0
        }
    } elseif ($sourcePath -match "\.(cmd|bat)$" -and (Test-Path -LiteralPath $sourcePath)) {
        $lines = Get-Content -LiteralPath $sourcePath -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '"([^"]*bash\.exe)"') {
                $resolved = Resolve-CandidatePath -Candidate $matches[1]
                if (-not [string]::IsNullOrWhiteSpace($resolved)) {
                    Write-Output $resolved
                    exit 0
                }
            }
            if ($line -match "([A-Za-z]:\\[^ ]*bash\.exe)") {
                $resolved = Resolve-CandidatePath -Candidate $matches[1]
                if (-not [string]::IsNullOrWhiteSpace($resolved)) {
                    Write-Output $resolved
                    exit 0
                }
            }
        }
    }
}

$whereCandidates = & where.exe bash.exe 2>$null
if ($LASTEXITCODE -eq 0 -and $whereCandidates) {
    foreach ($entry in $whereCandidates) {
        $resolved = Resolve-CandidatePath -Candidate $entry
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            Write-Output $resolved
            exit 0
        }
    }
}

$knownCandidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\usr\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\usr\bin\bash.exe",
    "C:\Progra~1\Git\bin\bash.exe",
    "C:\Progra~1\Git\usr\bin\bash.exe"
)

foreach ($candidate in $knownCandidates) {
    $resolved = Resolve-CandidatePath -Candidate $candidate
    if (-not [string]::IsNullOrWhiteSpace($resolved)) {
        Write-Output $resolved
        exit 0
    }
}

exit 0
