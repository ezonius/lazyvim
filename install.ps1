#Requires -Version 5.1
<#
.SYNOPSIS
  Installs Git, Neovim, ripgrep and fd, then clones the LazyVim setup into
  %LOCALAPPDATA%\nvim.

.DESCRIPTION
  Uses winget when it is available and falls back to portable GitHub builds,
  so it also works on Windows Server without the App Installer.

.EXAMPLE
  irm https://raw.githubusercontent.com/ezonius/lazyvim/master/install.ps1 | iex

.EXAMPLE
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/ezonius/lazyvim/master/install.ps1))) -BuildTools

.EXAMPLE
  .\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string]$Repo = "https://github.com/ezonius/lazyvim.git",
  # empty = use the remote's default branch
  [string]$Branch = "",
  [string]$Destination = (Join-Path $env:LOCALAPPDATA "nvim"),
  [switch]$BuildTools,
  [switch]$NoPlugins,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$script:DryRunMode = $DryRun.IsPresent

function Write-Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Note { param([string]$Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Warn { param([string]$Message) Write-Host "warn: $Message" -ForegroundColor Yellow }

function Test-Tool([string]$Command) {
  return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Update-PathFromRegistry {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ";"
}

function Add-ToUserPath([string]$Directory) {
  if ($script:DryRunMode) { Write-Note "[dry-run] add to user PATH: $Directory"; return }
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($current) { $parts = @($current -split ";" | Where-Object { $_ }) }
  if ($parts -notcontains $Directory) {
    [Environment]::SetEnvironmentVariable("Path", (@($parts) + $Directory) -join ";", "User")
  }
  if (($env:Path -split ";") -notcontains $Directory) { $env:Path = "$Directory;$env:Path" }
}

function Install-WingetPackage([string]$Id) {
  if (-not (Test-Tool "winget")) { return $false }
  Write-Step "winget: installing $Id"
  if ($script:DryRunMode) { Write-Note "[dry-run] winget install --id $Id"; return $true }
  & winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 |
    ForEach-Object { Write-Note "$_" }
  Update-PathFromRegistry
  return $true
}

function Get-ReleaseAssetUrl([string]$Repository, [string]$AssetPattern) {
  $headers = @{ "User-Agent" = "lazyvim-installer" }
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers $headers
  $asset = $release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
  if (-not $asset) { throw "no release asset matching /$AssetPattern/ in $Repository" }
  return $asset.browser_download_url
}

function Install-Portable {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory)][string]$Repository,
    [Parameter(Mandatory)][string]$AssetPattern,
    # keep the whole archive instead of only the folder holding the exe
    [switch]$KeepRoot
  )

  $dest = Join-Path $env:LOCALAPPDATA "Programs\$Name"
  Write-Step "$Name -> $dest (portable download)"
  if ($script:DryRunMode) { Write-Note "[dry-run] asset /$AssetPattern/ from $Repository"; return }

  $url = Get-ReleaseAssetUrl -Repository $Repository -AssetPattern $AssetPattern
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("lazyvim-" + $Name + "-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  try {
    Write-Note $url
    $archive = Join-Path $tmp "download.zip"
    Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
    $extract = Join-Path $tmp "extract"
    Expand-Archive -Path $archive -DestinationPath $extract -Force

    $exeFile = Get-ChildItem -Path $extract -Filter $Exe -Recurse -File | Select-Object -First 1
    if (-not $exeFile) { throw "$Exe not found in the $Name archive" }

    $source = $exeFile.Directory.FullName
    if ($KeepRoot) {
      $first = Get-ChildItem -Path $extract -Directory | Select-Object -First 1
      if ($first) { $source = $first.FullName }
    }

    if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force }
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
    Copy-Item -Path $source -Destination $dest -Recurse -Force

    $installed = Get-ChildItem -Path $dest -Filter $Exe -Recurse -File | Select-Object -First 1
    if (-not $installed) { throw "$Exe missing after copying to $dest" }
    Add-ToUserPath $installed.Directory.FullName
  }
  finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Ensure-Tool {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string]$DisplayName,
    [string]$WingetId,
    [scriptblock]$Portable,
    [string]$Hint
  )

  if (Test-Tool $Command) {
    Write-Step "$DisplayName already installed"
    return $true
  }

  Write-Step "$DisplayName missing"
  if ($WingetId) { Install-WingetPackage $WingetId | Out-Null }
  if (-not (Test-Tool $Command) -and $Portable) {
    Write-Step "winget route unavailable, using a portable build"
    & $Portable
  }

  if ($script:DryRunMode) { return $true }
  if (-not (Test-Tool $Command)) {
    Write-Warn "$DisplayName is still not on PATH. $Hint"
    return $false
  }
  return $true
}

# --- prerequisites ---------------------------------------------------------
Write-Step "checking prerequisites (git, neovim, ripgrep, fd)"

Ensure-Tool -Command "git" -DisplayName "Git" -WingetId "Git.Git" -Hint "install Git for Windows and re-run." -Portable {
  Install-Portable -Name "MinGit" -Exe "git.exe" -Repository "git-for-windows/git" `
    -AssetPattern '^MinGit-\d[\d.]*-64-bit\.zip$' -KeepRoot
} | Out-Null

Ensure-Tool -Command "nvim" -DisplayName "Neovim" -WingetId "Neovim.Neovim" -Hint "install Neovim 0.11+ and re-run." -Portable {
  Install-Portable -Name "nvim" -Exe "nvim.exe" -Repository "neovim/neovim" `
    -AssetPattern '^nvim-win64\.zip$' -KeepRoot
} | Out-Null

Ensure-Tool -Command "rg" -DisplayName "ripgrep" -WingetId "BurntSushi.ripgrep.MSVC" -Hint "install ripgrep and re-run." -Portable {
  Install-Portable -Name "ripgrep" -Exe "rg.exe" -Repository "BurntSushi/ripgrep" `
    -AssetPattern '^ripgrep-[\d.]+-x86_64-pc-windows-msvc\.zip$'
} | Out-Null

Ensure-Tool -Command "fd" -DisplayName "fd" -WingetId "sharkdp.fd" -Hint "install fd and re-run." -Portable {
  Install-Portable -Name "fd" -Exe "fd.exe" -Repository "sharkdp/fd" `
    -AssetPattern '^fd-v[\d.]+-x86_64-pc-windows-msvc\.zip$'
} | Out-Null

if ($BuildTools) {
  Write-Step "installing LLVM (C compiler for tree-sitter parsers)"
  Install-WingetPackage "LLVM.LLVM" | Out-Null
}

# --- configuration ---------------------------------------------------------
Write-Step "installing configuration into $Destination"

if (-not (Test-Tool "git") -and -not $script:DryRunMode) {
  throw "git is required to clone the configuration; install it and re-run."
}

if (-not $Branch) {
  Write-Step "detecting the default branch of $Repo"
  $ref = $null
  try { $ref = (& git ls-remote --symref $Repo HEAD 2>$null | Select-Object -First 1) } catch { }
  if ($ref -match '^ref: refs/heads/(\S+)') { $Branch = $Matches[1] } else { $Branch = "master" }
}
Write-Step "branch: $Branch"

$isRepo = Test-Path (Join-Path $Destination ".git")
if ($isRepo) {
  Write-Step "updating existing clone"
  if ($script:DryRunMode) {
    Write-Note "[dry-run] git pull --ff-only origin $Branch"
  }
  else {
    & git -C $Destination pull --ff-only --quiet origin $Branch
    if ($LASTEXITCODE -ne 0) { Write-Warn "could not fast-forward $Destination - leaving it untouched" }
  }
}
else {
  if (Test-Path $Destination) {
    $backup = "$Destination.bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    Write-Step "backing up existing config -> $backup"
    if (-not $script:DryRunMode) { Move-Item -Path $Destination -Destination $backup }
  }

  Write-Step "cloning $Repo ($Branch)"
  if ($script:DryRunMode) {
    Write-Note "[dry-run] git clone --depth 1 --branch $Branch $Repo $Destination"
  }
  else {
    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    & git clone --quiet --depth 1 --branch $Branch $Repo $Destination
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
  }
}

# --- plugins ---------------------------------------------------------------
if ($NoPlugins) {
  Write-Note "skipping plugin install (-NoPlugins)"
}
elseif ($script:DryRunMode) {
  Write-Note "[dry-run] nvim --headless ""+Lazy! sync"" +qa"
}
elseif (Test-Tool "nvim") {
  Write-Step "installing plugins (this takes a few minutes)"
  & nvim --headless "+Lazy! sync" +qa 2>&1 | ForEach-Object { Write-Note "$_" }
  if ($LASTEXITCODE -ne 0) { Write-Warn "plugin install did not finish; run ':Lazy sync' inside Neovim" }
}
else {
  Write-Warn "nvim not available - start Neovim once it is on PATH to install plugins"
}

Write-Step "done"
Write-Note "config: $Destination"
Write-Note "start:  nvim"
Write-Note "optional: install a Nerd Font (e.g. winget install DEVCOM.JetBrainsMonoNerdFont) and set it in your terminal"
