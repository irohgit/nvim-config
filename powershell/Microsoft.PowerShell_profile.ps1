$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
function nvimrc { nvim "$env:LOCALAPPDATA\nvim\init.lua"}
Set-PSReadLineKeyHandler -Chord 'Ctrl+Oem1' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl+f'    -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+e'    -Function AcceptLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+h' -Function BeginningOfLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+e' -Function EndOfLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+x' -Function DeleteChar
function aa {
   Set-Location E:\AA\a-a-take-home-assignment-irohgit
   & .\.venv\Scripts\Activate.ps1
}
function pingpong {Set-location "E:\Game Development\lua_pingpong"}
function vsdev {
    $vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
    Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=x86" | Out-Null
}
$PadelRoot = @('E:\cplusplus\Padel', 'C:\Users\User\cplusplus\Padel') |
   Where-Object { Test-Path $_ } | Select-Object -First 1
function padel    { Set-Location $PadelRoot }
function padelv   { Set-Location $PadelRoot; nvim . }
function padelrun { Set-Location $PadelRoot; .\Debug\Padel.exe }
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
