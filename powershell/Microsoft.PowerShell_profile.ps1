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

# Load the Visual Studio developer shell (64-bit MSVC and MSBuild)
function vsdev {
    $vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
    Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=amd64" | Out-Null
}

$PadelRoot = @('E:\cplusplus\Padel', 'C:\Users\User\cplusplus\Padel') | Where-Object { Test-Path $_ } | Select-Object -First 1

# Go to the Padel project
function padel    { Set-Location $PadelRoot }

# Go to Padel and open it in Neovim
function padelv   { Set-Location $PadelRoot; nvim . }

# Go to Padel and run the x64 Debug build
function padelrun { Set-Location $PadelRoot; .\x64\Debug\Padel.exe }

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
