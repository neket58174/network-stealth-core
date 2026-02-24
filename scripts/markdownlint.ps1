param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $root ".markdownlint.json"
if (-not (Test-Path $configPath)) {
    throw "markdownlint config not found: $configPath"
}

if (-not $Paths -or $Paths.Count -eq 0) {
    $Paths = @(
        "README.md",
        "README.ru.md",
        "CONTRIBUTING.md",
        "ARCHITECTURE.md",
        "CHANGELOG.md",
        "SECURITY.md"
    )
}

$resolvedPaths = @()
foreach ($path in $Paths) {
    $target = if ([System.IO.Path]::IsPathRooted($path)) {
        $path
    }
    else {
        Join-Path $root $path
    }

    if (-not (Test-Path $target)) {
        throw "markdown file not found: $target"
    }
    $resolvedPaths += (Resolve-Path $target).Path
}

$oldNodeOptions = $env:NODE_OPTIONS
try {
    $env:NODE_OPTIONS = "--no-deprecation"

    $markdownlintCmd = Get-Command markdownlint -ErrorAction SilentlyContinue
    if ($markdownlintCmd) {
        & $markdownlintCmd.Source --config $configPath @resolvedPaths
        exit $LASTEXITCODE
    }

    $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
    if (-not $npxCmd) {
        throw "npx not found. install node.js or markdownlint-cli."
    }

    & $npxCmd.Source --yes markdownlint-cli@0.41.0 --config $configPath @resolvedPaths
    exit $LASTEXITCODE
}
finally {
    if ($null -eq $oldNodeOptions) {
        Remove-Item Env:NODE_OPTIONS -ErrorAction SilentlyContinue
    }
    else {
        $env:NODE_OPTIONS = $oldNodeOptions
    }
}
