$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

# Open init.lua in Neovim
function nvimrc { nvim "$env:LOCALAPPDATA\nvim\init.lua"}

Set-PSReadLineKeyHandler -Chord 'Ctrl+Oem1' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl+f'    -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+e'    -Function AcceptLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+h' -Function BeginningOfLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+e' -Function EndOfLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+x' -Function DeleteChar

# Go to the old Lua ping-pong project
function pingpong {Set-location "E:\Game Development\lua_pingpong"}

# Load the Visual Studio developer shell (64-bit MSVC and MSBuild), once per tab
function vsdev {
   if (Get-Command cl -ErrorAction SilentlyContinue) { return }   # already loaded in this tab
   $vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
   Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
   Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=amd64" | Out-Null
}

$PadelRoot = @('E:\cplusplus\Padel', 'C:\Users\User\cplusplus\Padel') | Where-Object { Test-Path $_ } | Select-Object -First 1

# Go to the Padel project, with the compiler loaded
function padel    { vsdev; Set-Location $PadelRoot }

# Go to Padel, load the compiler and open it in Neovim
function padelv   { vsdev; Set-Location $PadelRoot; nvim . }
# Go to Padel and run the x64 Debug build
function padelrun { Set-Location $PadelRoot; .\x64\Debug\Padel.exe }
# Go to the Algorithms practice folder, with the compiler loaded
function algo     { vsdev; Set-Location 'E:\cplusplus\Algorithms' }
$PortfolioRoot = @('E:\tuantriet\tuantriet-portfolio')
    | Where-Object {Test-Path $_} | Select-Object -First 1

# Go to the portfolio site
function portfolio {Set-Location $PortfolioRoot}

# Go to the Neovim config folder
function nvimdir {Set-Location "$env:LOCALAPPDATA\nvim"}

# Prompt: folder name, then the git branch in cyan
function prompt {
   if ($env:VIRTUAL_ENV) {
       Write-Host "($(Split-Path -Leaf $env:VIRTUAL_ENV)) " -NoNewline -ForegroundColor Green
   }
   $Folder = Split-Path -Leaf $PWD
   $Branch = git branch --show-current 2>$null
   if ($Branch) {
       $Host.UI.RawUI.WindowTitle = "$Folder git:($Branch)"
       Write-Host "$Folder " -NoNewline
       Write-Host "git:(" -NoNewline -ForegroundColor DarkGray
       Write-Host "$Branch" -NoNewline -ForegroundColor Cyan
       Write-Host ")" -NoNewline -ForegroundColor DarkGray
       return "> "
   }
   $Host.UI.RawUI.WindowTitle = $Folder
   "$Folder> "
}

# Run Padel under cdb and print the call stack each time a function runs
function padeltrace {
       param([string]$Fn = 'AudioSystem::~AudioSystem')
       Set-Location $PadelRoot
       cdb -G -c "bu Padel!$Fn `"k; g`"; g" .\x64\Debug\Padel.exe
}

# List a folder with names first
function ll { Get-ChildItem @args | Format-Table Name, LastWriteTime, Length -AutoSize }

# Go to the Audiokinetic folder (Cube, Wwise and the Fundamentals course)
function ak { Set-Location 'C:\Audiokinetic' }

# Open a narrow pane on the right, in this folder, already listing it
function side { wt -w 0 split-pane -V -s 0.45 -d . pwsh -NoExit -Command ll }

# Open a short pane at the bottom, in this folder, already listing it
function bottom { wt -w 0 split-pane -H -s 0.45 -d . pwsh -NoExit -Command ll }

# Show my last 20 commands, newest at the top
function hist { Get-History | Sort-Object Id -Descending | Select-Object -First 20 | Format-Table Id, CommandLine -AutoSize }


# Go to my Downloads folder, wherever Windows has it
function dl { Set-Location ((New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path) }

# List the 20 most recently changed items, newest at the bottom
function llr {
    param([string]$Path = '.', [int]$Count = 20)
    Get-ChildItem -Path $Path |
        Sort-Object LastWriteTime |
        Select-Object -Last $Count |
        Format-Table Name, LastWriteTime, Length -AutoSize
}

# List every item, oldest to newest, newest at the bottom
function llra {
    param([string]$Path = '.')
    Get-ChildItem -Path $Path |
        Sort-Object LastWriteTime |
        Format-Table Name, LastWriteTime, Length -AutoSize
}


# Go to cplusplus
function cplusplus { Set-Location 'E:\cplusplus' }


# Open the real PowerShell profile (kept in the nvim repo) in Neovim
function psrc { nvim "$env:LOCALAPPDATA\nvim\powershell\Microsoft.PowerShell_profile.ps1" }


# Move files into a folder, creating it first if needed; add -Go to go there afterwards
function moveto {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Items,
        [switch]$Go
    )
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Move-Item -Path $Items -Destination $Destination
    if ($Go) { Set-Location $Destination }
}

# Copy files into a folder, creating it first if needed; add -Go to go there afterwards
function copyto {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Items,
        [switch]$Go
    )
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -Path $Items -Destination $Destination -Recurse
    if ($Go) { Set-Location $Destination }
}
