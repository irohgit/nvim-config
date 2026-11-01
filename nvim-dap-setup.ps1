<#
  nvim-dap-setup.ps1: one-time setup for a new Windows machine.

  How to use on a new computer:
    1. git clone <your nvim config repo> "$env:LOCALAPPDATA\nvim"
    2. pwsh -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\nvim\nvim-dap-setup.ps1"

  Safe to run more than once: every step checks before it changes anything.
  Contains no passwords, keys or tokens.
#>

$ErrorActionPreference = 'Stop'
$NvimDir = $PSScriptRoot
$SharedProfile = Join-Path $NvimDir 'powershell\Microsoft.PowerShell_profile.ps1'

function Step($Text) { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Ok($Text)   { Write-Host "    $Text" -ForegroundColor Green }
function Warn($Text) { Write-Host "    $Text" -ForegroundColor Yellow }

# 1. Allow your own scripts (the profile) to run
Step 'Script execution policy'
if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Ok 'Set to RemoteSigned for this user.'
} else { Ok 'Already allows local scripts.' }

# 2. Core tools, installed with winget if missing
Step 'Core tools'
$Tools = @(
    @{ Cmd = 'git';  Id = 'Git.Git' },
    @{ Cmd = 'nvim'; Id = 'Neovim.Neovim' },
    @{ Cmd = 'pwsh'; Id = 'Microsoft.PowerShell' }
)
foreach ($T in $Tools) {
    if (Get-Command $T.Cmd -ErrorAction SilentlyContinue) {
        Ok "$($T.Cmd) found."
    } else {
        Warn "$($T.Cmd) missing, installing $($T.Id)..."
        winget install --id $T.Id --exact --silent --accept-package-agreements --accept-source-agreements
    }
}

# 3. Point both PowerShell profiles at the shared profile in this repo
Step 'PowerShell profiles'
$Docs = [Environment]::GetFolderPath('MyDocuments')   # handles OneDrive-redirected Documents
$Profiles = @(
    (Join-Path $Docs 'PowerShell\Microsoft.PowerShell_profile.ps1'),        # PowerShell 7
    (Join-Path $Docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')  # Windows PowerShell 5
)
$Pointer = @'
$Shared = "$env:LOCALAPPDATA\nvim\powershell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $Shared) { . $Shared }
'@
foreach ($P in $Profiles) {
    New-Item -ItemType Directory -Force -Path (Split-Path $P) | Out-Null
    if ((Test-Path $P) -and (Get-Content $P -Raw) -match [regex]::Escape('nvim\powershell\Microsoft.PowerShell_profile.ps1')) {
        Ok "Already points to the shared profile: $P"
    } else {
        if (Test-Path $P) {
            Copy-Item $P "$P.bak" -Force
            Warn "Backed up the old profile to $P.bak"
        }
        Set-Content -Path $P -Value $Pointer
        Ok "Pointer written: $P"
    }
}
if (-not (Test-Path $SharedProfile)) { Warn "Shared profile not found at $SharedProfile" }

# 4. cdb, the console debugger (part of the Windows SDK)
Step 'cdb debugger'
$CdbDir = "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64"
if (Get-Command cdb -ErrorAction SilentlyContinue) {
    Ok 'cdb found.'
} elseif (Test-Path "$CdbDir\cdb.exe") {
    $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($UserPath -notlike "*$CdbDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$UserPath;$CdbDir", 'User')
    }
    Ok "cdb added to your PATH. Open a new terminal to use it."
} else {
    Warn 'cdb not installed.'
    Warn 'Install the Windows SDK and tick "Debugging Tools for Windows", then run this script again.'
}

# 5. Neovim plugins (lazy.nvim installs them; dap.lua installs codelldb through Mason)
Step 'Neovim plugins'
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    nvim --headless '+Lazy! sync' +qa
    Ok 'Plugins installed. codelldb installs itself the first time Neovim opens.'
} else {
    Warn 'nvim not on PATH yet. Open a new terminal and run this script again.'
}

Step 'Done'
Ok 'Open a new terminal, then try: padel, portfolio, nvimdir.'
