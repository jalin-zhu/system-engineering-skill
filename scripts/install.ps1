# Installer for the system-engineering agent skill (Windows PowerShell).
[CmdletBinding()]
param(
  [ValidateSet('qoder', 'claude', 'project', 'all')]
  [string]$Target = 'qoder',

  [ValidateSet('zh', 'en')]
  [string]$Lang = 'zh',

  [string]$Dir = '',

  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Name = 'system-engineering'
$SrcDir = Split-Path -Parent $PSScriptRoot

function Get-Destination([string]$t) {
  switch ($t) {
    'qoder'   { Join-Path $HOME ".qoder\skills\$Name" }
    'claude'  { Join-Path $HOME ".claude\skills\$Name" }
    'project' {
      $root = if ($Dir) { $Dir } else { Join-Path (Get-Location) '.qoder\skills' }
      Join-Path $root $Name
    }
    default   { throw "unknown target '$t' — use qoder, claude, project, or all" }
  }
}

function Get-Version {
  $pkg = Join-Path $SrcDir 'package.json'
  if (Test-Path $pkg) { (Get-Content $pkg -Raw | ConvertFrom-Json).version } else { 'unknown' }
}

function Install-Into([string]$dest, [string]$Version) {
  if (Test-Path $dest) {
    if ($Force) {
      Remove-Item $dest -Recurse -Force
    } else {
      $backup = "$dest.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
      Move-Item $dest $backup
      Write-Host "  backup  $backup"
    }
  }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null

  if ($Lang -eq 'en') {
    Copy-Item (Join-Path $SrcDir 'SKILL.en.md') (Join-Path $dest 'SKILL.md') -Force
    Copy-Item (Join-Path $SrcDir 'SKILL.md') (Join-Path $dest 'SKILL.zh-CN.md') -Force
  } else {
    Copy-Item (Join-Path $SrcDir 'SKILL.md') (Join-Path $dest 'SKILL.md') -Force
    Copy-Item (Join-Path $SrcDir 'SKILL.en.md') (Join-Path $dest 'SKILL.en.md') -Force
  }

  foreach ($f in @('reference.md', 'project-wiki.md', 'README.md', 'README.zh-CN.md')) {
    $src = Join-Path $SrcDir $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $dest $f) -Force }
  }

  $meta = [ordered]@{
    name        = $Name
    version     = $Version
    lang        = $Lang
    installedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  }
  $meta | ConvertTo-Json | Set-Content (Join-Path $dest '.installed.json') -Encoding utf8
}

$version = Get-Version
$targets = if ($Target -eq 'all') { @('qoder', 'claude') } else { @($Target) }

foreach ($t in $targets) {
  $dest = Get-Destination $t
  Write-Host "installing $Name ($Lang) -> $dest"
  Install-Into $dest $version
  Write-Host '  done'
}

Write-Host ''
Write-Host 'Restart your agent so it rescans the skills directory.'
