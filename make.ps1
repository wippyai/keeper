# Windows wrapper that mirrors the Makefile targets one-for-one.
# Invoke through make.bat (`make build-keeper-frontend`, `make publish-dry-run`,
# etc.) or directly: `powershell -ExecutionPolicy Bypass -File make.ps1 <target>`.
#
# Pure ASCII on purpose: Windows PowerShell 5.1 reads BOM-less files as
# Windows-1252, so any non-ASCII char (em-dash, smart quote) corrupts on
# read. Don't introduce non-ASCII chars without also adding a UTF-8 BOM.
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = 'help'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Module versions - mirrors KEEPER_VERSION / USAGE_VERSION in the Makefile.
# Override at invocation: `$env:KEEPER_VERSION = '0.5.17'; make publish-keeper`
$keeperVersion = if ($env:KEEPER_VERSION) { $env:KEEPER_VERSION } else { '0.5.16' }
$usageVersion  = if ($env:USAGE_VERSION)  { $env:USAGE_VERSION  } else { '0.1.1'  }
$wippyExe = if ($env:WIPPY) { $env:WIPPY } else { Join-Path $PSScriptRoot 'wippy.exe' }

# (name, dir, out) tuples - single source of truth for every build-* target.
# `out` is relative to the build dir, NOT the repo root, to mirror the
# original Makefile's `--outDir ../../../...` recipe semantics.
$builds = @(
    @{ name = 'keeper-frontend';       dir = 'keeper/frontend/applications/keeper';        out = '../../../static/keeper' }
    @{ name = 'keeper-git-frontend';   dir = 'keeper/plugins/git/frontend/applications/git'; out = '../../../../../static/keeper-git' }
    @{ name = 'wippy-monaco-frontend'; dir = 'keeper/frontend/web-components/wippy-monaco'; out = '../../../static/wippy-monaco' }
    @{ name = 'usage-frontend';        dir = 'usage/frontend/applications/usage';          out = '../../../static/keeper-usage' }
)

# (target, modulePath, lintArgs) tuples for `lint-*` recipes. Mirrors the
# Makefile's `cd <module> && wippy lint ...` invocations.
$lints = @(
    @{ name = 'keeper'; dir = 'keeper'; args = @('lint', '--ns', 'keeper,keeper.*', '--summary', '--limit', '200', '--no-color') }
    @{ name = 'usage';  dir = 'usage';  args = @('lint',                                     '--summary', '--limit', '200', '--no-color') }
)

function Invoke-Build {
    param(
        [Parameter(Mandatory)][string]$Dir,
        [Parameter(Mandatory)][string]$Out
    )
    Push-Location $Dir
    try {
        Write-Host "==> $Dir" -ForegroundColor Cyan
        npm install --no-audit --no-fund --prefer-offline
        if ($LASTEXITCODE -ne 0) { throw "npm install failed in $Dir (exit $LASTEXITCODE)" }
        npm run build -- --outDir $Out --emptyOutDir
        if ($LASTEXITCODE -ne 0) { throw "npm run build failed in $Dir (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Lint {
    param(
        [Parameter(Mandatory)][string]$Dir,
        [Parameter(Mandatory)][string[]]$Args
    )
    Push-Location $Dir
    try {
        Write-Host "==> lint $Dir" -ForegroundColor Cyan
        & $wippyExe @Args
        if ($LASTEXITCODE -ne 0) { throw "wippy lint failed in $Dir (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Publish {
    param(
        [Parameter(Mandatory)][string]$Dir,
        [Parameter(Mandatory)][string]$Version,
        [switch]$DryRun
    )
    Push-Location $Dir
    try {
        Write-Host "==> publish $Dir @ $Version$(if ($DryRun) { ' (dry-run)' })" -ForegroundColor Cyan
        $args = @('publish', '--version', $Version)
        if ($DryRun) { $args = @('publish', '--dry-run', '--version', $Version) }
        & $wippyExe @args
        if ($LASTEXITCODE -ne 0) { throw "wippy publish failed in $Dir (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

function Invoke-BuildKeeperBundle {
    # publish-keeper / publish-keeper-dry-run depend on these three FE bundles.
    Invoke-Build -Dir 'keeper/frontend/applications/keeper'        -Out '../../../static/keeper'
    Invoke-Build -Dir 'keeper/plugins/git/frontend/applications/git' -Out '../../../../../static/keeper-git'
    Invoke-Build -Dir 'keeper/frontend/web-components/wippy-monaco' -Out '../../../static/wippy-monaco'
}

function Invoke-BuildAll {
    # Aggregator — every FE app + the monaco WC. Mirrors Makefile `build`.
    foreach ($i in $builds) {
        Invoke-Build -Dir $i.dir -Out $i.out
    }
}

function Invoke-CleanStatic {
    # Nuke all built FE artifacts. Forces the next `make build` to rebuild
    # from scratch when a stale chunk hash or hoisted asset blocks a fix.
    $paths = @(
        'keeper/static/keeper',
        'keeper/static/keeper-git',
        'keeper/static/wippy-monaco',
        'usage/static/keeper-usage'
    )
    foreach ($p in $paths) {
        $full = Join-Path $PSScriptRoot $p
        if (Test-Path $full) {
            Write-Host "==> rm -rf $p" -ForegroundColor Cyan
            Remove-Item -Recurse -Force $full
        }
    }
}

function Invoke-Dev {
    param(
        [Parameter(Mandatory)][string]$Dir,
        [Parameter(Mandatory)][string]$Out
    )
    Push-Location $Dir
    try {
        Write-Host "==> dev $Dir" -ForegroundColor Cyan
        npm install --no-audit --no-fund --prefer-offline
        if ($LASTEXITCODE -ne 0) { throw "npm install failed in $Dir (exit $LASTEXITCODE)" }
        npm run dev -- --outDir $Out
        if ($LASTEXITCODE -ne 0) { throw "npm run dev failed in $Dir (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Smoke {
    # Headless-browser smoke against the keeper-test harness on $env:BASE_URL
    # (defaults to http://localhost:8085 inside smoke.mjs). Phase 1 verifies
    # dist/app.html exists for each app; phase 2 logs into keeper-test and
    # boots keeper-main + keeper-git in dark + light themes, asserting no
    # console errors. See test/smoke/README.md.
    Push-Location 'test/smoke'
    try {
        Write-Host '==> smoke (test/smoke)' -ForegroundColor Cyan
        npm install --no-audit --no-fund --prefer-offline
        if ($LASTEXITCODE -ne 0) { throw "npm install failed in test/smoke (exit $LASTEXITCODE)" }
        npm run smoke
        if ($LASTEXITCODE -ne 0) { throw "npm run smoke failed (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

function Show-Help {
    Write-Host "make - Windows mirror of the Makefile (via make.bat -> make.ps1)`n"
    Write-Host "Build targets:"
    Write-Host "  build                          Build everything (every FE app + monaco WC)"
    Write-Host "  build-keeper-frontend          Build keeper main FE -> keeper/static/keeper"
    Write-Host "  build-keeper-git-frontend      Build keeper-git plugin FE -> keeper/static/keeper-git"
    Write-Host "  build-wippy-monaco-frontend    Build wippy-monaco WC -> keeper/static/wippy-monaco"
    Write-Host "  build-usage-frontend           Build usage FE -> usage/static/keeper-usage"
    Write-Host "  clean-static                   Remove all built FE artifacts under static/`n"
    Write-Host "Dev (watch) targets:"
    Write-Host "  dev                            Alias for dev-keeper (most common entry)"
    Write-Host "  dev-keeper                     Watch-rebuild keeper main FE into keeper/static/keeper"
    Write-Host "  dev-keeper-git                 Watch-rebuild keeper-git FE into keeper/static/keeper-git"
    Write-Host "  dev-wippy-monaco               Watch-rebuild wippy-monaco WC into keeper/static/wippy-monaco"
    Write-Host "  dev-usage                      Watch-rebuild usage FE into usage/static/keeper-usage`n"
    Write-Host "Smoke target:"
    Write-Host "  smoke                          Headless-browser smoke against keeper-test (test/smoke/README.md)`n"
    Write-Host "Lint targets:"
    Write-Host "  lint                           lint-keeper + lint-usage"
    Write-Host "  lint-keeper                    wippy lint --ns 'keeper,keeper.*' in keeper/"
    Write-Host "  lint-usage                     wippy lint in usage/`n"
    Write-Host "Publish targets:"
    Write-Host "  publish                        publish-keeper + publish-usage"
    Write-Host "  publish-dry-run                publish-keeper-dry-run + publish-usage-dry-run"
    Write-Host "  publish-keeper                 build keeper FE bundles, then wippy publish"
    Write-Host "  publish-keeper-dry-run         build keeper FE bundles, then wippy publish --dry-run"
    Write-Host "  publish-usage                  build usage FE, then wippy publish"
    Write-Host "  publish-usage-dry-run          build usage FE, then wippy publish --dry-run`n"
    Write-Host "Versions (override via env):"
    Write-Host "  KEEPER_VERSION = $keeperVersion"
    Write-Host "  USAGE_VERSION  = $usageVersion"
    Write-Host "  WIPPY          = $wippyExe"
}

try {
    switch -Regex ($Target) {
        '^help$|^-h$|^--help$' { Show-Help; break }

        '^build$'        { Invoke-BuildAll;     break }
        '^smoke$'        { Invoke-Smoke;        break }
        '^clean-static$' { Invoke-CleanStatic;  break }

        '^build-(.+)$' {
            $name = $Matches[1]
            $item = $builds | Where-Object { $_.name -eq $name }
            if (-not $item) { throw "Unknown build target: $name. Run 'make help' for the list." }
            Invoke-Build -Dir $item.dir -Out $item.out
            break
        }

        '^dev$' {
            # Alias — most common entry is the main keeper FE.
            $item = $builds | Where-Object { $_.name -eq 'keeper-frontend' }
            Invoke-Dev -Dir $item.dir -Out $item.out
            break
        }
        '^dev-(.+)$' {
            $name = "$($Matches[1])-frontend"
            $item = $builds | Where-Object { $_.name -eq $name }
            if (-not $item) { throw "Unknown dev target: $($Matches[1]). Run 'make help' for the list." }
            Invoke-Dev -Dir $item.dir -Out $item.out
            break
        }

        '^lint$' {
            foreach ($l in $lints) { Invoke-Lint -Dir $l.dir -Args $l.args }
            break
        }
        '^lint-(.+)$' {
            $name = $Matches[1]
            $item = $lints | Where-Object { $_.name -eq $name }
            if (-not $item) { throw "Unknown lint target: $name. Run 'make help' for the list." }
            Invoke-Lint -Dir $item.dir -Args $item.args
            break
        }

        '^publish$' {
            Invoke-BuildKeeperBundle
            Invoke-Publish -Dir 'keeper' -Version $keeperVersion
            Invoke-Build -Dir 'usage/frontend/applications/usage' -Out '../../../static/keeper-usage'
            Invoke-Publish -Dir 'usage' -Version $usageVersion
            break
        }
        '^publish-dry-run$' {
            Invoke-BuildKeeperBundle
            Invoke-Publish -Dir 'keeper' -Version $keeperVersion -DryRun
            Invoke-Build -Dir 'usage/frontend/applications/usage' -Out '../../../static/keeper-usage'
            Invoke-Publish -Dir 'usage' -Version $usageVersion -DryRun
            break
        }
        '^publish-keeper$' {
            Invoke-BuildKeeperBundle
            Invoke-Publish -Dir 'keeper' -Version $keeperVersion
            break
        }
        '^publish-keeper-dry-run$' {
            Invoke-BuildKeeperBundle
            Invoke-Publish -Dir 'keeper' -Version $keeperVersion -DryRun
            break
        }
        '^publish-usage$' {
            Invoke-Build -Dir 'usage/frontend/applications/usage' -Out '../../../static/keeper-usage'
            Invoke-Publish -Dir 'usage' -Version $usageVersion
            break
        }
        '^publish-usage-dry-run$' {
            Invoke-Build -Dir 'usage/frontend/applications/usage' -Out '../../../static/keeper-usage'
            Invoke-Publish -Dir 'usage' -Version $usageVersion -DryRun
            break
        }

        default {
            throw "Unknown target: $Target. Run 'make help' for the list."
        }
    }
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
