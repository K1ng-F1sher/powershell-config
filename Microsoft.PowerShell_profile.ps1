# Check whether the following packages are installed.
# See `C:\ProgramData\chocolatey\bin` for all installed packages.
$check_installed = "choco.exe","git.exe","rg.exe","nvim.exe", "jq.exe", "zoxide.exe", "fzf.exe"
# posh-git is installed with `Intall-Module`, so can't be checked with the method below.

foreach ($package in $check_installed) {
    if (!(Get-Command -Name $package -ErrorAction SilentlyContinue)) {
      Write-Host "$($package) not available"
  }
}

# Aliases
Set-Alias -Name vim -Value nvim
Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name ex -Value explorer

Import-Module posh-git

# Show history
# FYI: History mode can be toggled with `F2`.
Set-PSReadLineOption -PredictionViewStyle ListView
# Scroll through history suggestions with `Ctrl+n` and `Ctrl+p` key combinations.
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory 
Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory 

# Format prompt
$GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-Date -f "HH:mm:ss") '
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::Yellow
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 'DarkGray'

# Add location to prompt, so duplicate tab works in PS. Call with `<C-S-d>`.
# [ref](https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directoryhttps://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directoryhttps://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory)
function prompt
{
  $loc = Get-Location

  $prompt = & $GitPromptScriptBlock
  
  $prompt += "$([char]27)]9;12$([char]7)"
  if ($loc.Provider.Name -eq "FileSystem")
  {
    $prompt += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
  }

  $prompt
}

# Set default folder to git, if it exists.
$folder = 'D:\git\'
if (Test-Path -Path $Folder) {
  Set-Location $folder
} else { 
  $folder = 'C:\git\'
  if (Test-Path -Path $Folder) {
    Set-Location $folder
  } 
}

# Init zoxide in PS
Invoke-Expression (& { (zoxide init powershell | Out-String) })

function isAdmin {  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
