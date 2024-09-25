# Check whether the following packages are installed.
# See `C:\ProgramData\chocolatey\bin` for all installed packages.
$check_installed = "choco.exe","git.exe","rg.exe","nvim.exe", "jq.exe", "zoxide.exe", "fzf.exe"
# carapace is installed with scoop

foreach ($package in $check_installed) {
    if (!(Get-Command -Name $package -ErrorAction SilentlyContinue)) {
      Write-Host "$($package) not available"
  }
}

# Aliases
Set-Alias -Name vim -Value nvim
Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name ex -Value explorer

# Carapace options
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# Show history
# FYI: History mode can be toggled with `F2`.
Set-PSReadLineOption -PredictionViewStyle ListView
# Scroll through history suggestions with `Ctrl+n` and `Ctrl+p` key combinations.
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory 
Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory 

# Init zoxide in PS
Invoke-Expression (& { (zoxide init powershell | Out-String) })

function prompt {
  $IsAdmin = IsAdmin

  if ($IsAdmin) {
    Write-Host "[ADMIN] " -NoNewline -ForegroundColor Red
  }

  $date = Get-Date -format 'HH:mm:ss'
  $loc = $executionContext.SessionState.Path.CurrentLocation;

  $host.UI.RawUI.WindowTitle = $IsAdmin ? "PS7 [ADMIN] | " : "PS7 | "; 
  $host.UI.RawUI.WindowTitle += $loc 

  Write-Host $date -NoNewLine -ForegroundColor "Yellow"
  if ($loc.Provider.Name -eq "FileSystem") {
    Write-Host "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\" -NoNewLine 
  }
  Write-Host " $loc$('>' * ($nestedPromptLevel + 1))" -NoNewLine ` -ForegroundColor "DarkGray"

  if (Test-Path .git) {
    Write-BranchName
  }

  # Need to return non-empty string in order not to spawn another `PS` at the prompt.
  return " ";
}

function IsAdmin {  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Write-BranchName () {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        Write-Host " [" -ForegroundColor "Yellow" -NoNewline 
        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host "$branch" -ForegroundColor "Red" -NoNewline 
        }
        else {
            # we're on an actual branch, so print it
            Write-Host "$branch" -ForegroundColor "Cyan" -NoNewline 
        }
    } catch {
        # we'll end up here if we're in a newly initiated git repo
        Write-Host "no branches" -ForegroundColor "Yellow" -NoNewline 
    }

    Write-Host "]" -ForegroundColor "Yellow" -NoNewline 
}
