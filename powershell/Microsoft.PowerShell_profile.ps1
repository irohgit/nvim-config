$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
function nvimrc { nvim "$env:LOCALAPPDATA\nvim\init.lua"}
function prompt {
   if ($env:VIRTUAL_ENV) {
       Write-Host "($(Split-Path -Leaf $env:VIRTUAL_ENV)) " -NoNewline -ForegroundColor Green
   }
   "$(Split-Path -Leaf $PWD)> "
}
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

function padel    { vsdev; Set-Location E:\cplusplus\Padel }
