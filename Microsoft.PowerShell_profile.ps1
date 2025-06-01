using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# Set prompt before anything else
function prompt {
  $IsAdmin = IsAdmin

  if ($IsAdmin) {
    Write-Host "# " -NoNewline -ForegroundColor Red
  }

    $date = Get-Date -format 'HH:mm:ss'

  $loc = $executionContext.SessionState.Path.CurrentLocation;
  # Show smart path, which is only the last two folders.
  try {
    $shortLoc = Split-Path -leaf -path (Split-Path -parent -path ($loc));
    if (Split-Path -parent -path (Split-Path -parent -path ($loc))) {
      $shortLoc = "..\" + $shortLoc;
    }
    if (!$shortLoc) {
      $shortLoc = Split-Path -leaf -path ($loc);
    } else {
      $shortLoc = $shortLoc.TrimEnd("\")
      $shortLoc += "\"
      $shortLoc += Split-Path -leaf -path ($loc);
    }
  }
  catch {
    $shortLoc = $loc;
  }

  $host.UI.RawUI.WindowTitle = $IsAdmin ? "PS7 [ADMIN] | " : "PS7 | "; 
  $host.UI.RawUI.WindowTitle += $shortLoc 

  Write-Host $date -NoNewLine -ForegroundColor "DarkYellow"
  # Set the path in the prompt (invisible), so <C-S-d> and <Alt-S-+> work.
  if ($loc.Provider.Name -eq "FileSystem") {
    Write-Host "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\" -NoNewLine 
  }
  Write-Host " $shortLoc" -NoNewLine -ForegroundColor "DarkGray"
  Write-BranchName
  Write-Host $('>' * ($nestedPromptLevel + 1)) -NoNewLine 

  # Need to return non-empty string in order not to spawn another `PS` at the prompt.
  return " ";
}

function IsAdmin {  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Write-BranchName {
  # TODO: split getting the branch and writing the prompt into two separate parts.
  try {
    $branch = git rev-parse --abbrev-ref HEAD

    if ($branch) {
      Write-Host " [" -ForegroundColor "Yellow" -NoNewline 
      if ($branch -eq "HEAD") {
        # Detached head
        $branch = git rev-parse --short HEAD
        Write-Host "$branch" -ForegroundColor "Red" -NoNewline 
      } else {
        # Actual branch
        Write-Host "$branch" -ForegroundColor "Cyan" -NoNewline 
      }
      Write-Host "]" -ForegroundColor "Yellow" -NoNewline 
    }
  } catch {
    # When in newly initiated git repo
    Write-Host "no branches" -ForegroundColor "Yellow" -NoNewline 
    Write-Host "]" -ForegroundColor "Yellow" -NoNewline 
  }
}

$env:TERM='xterm-256color'

# Check whether the following packages are installed.
# See `C:\ProgramData\chocolatey\bin` for all installed packages.
$check_installed = "choco.exe","git.exe","rg.exe","nvim.exe", "jq.exe", "zoxide.exe", "fzf.exe"
# carapace, PsFzf are installed with scoop

foreach ($package in $check_installed) {
  if (!(Get-Command -Name $package -ErrorAction SilentlyContinue)) {
    Write-Host "$($package) not available"
  }
}

# Aliases
Set-Alias -Name vim -Value nvim
Set-Alias -Name ex -Value explorer
Set-Alias -Name fe -Value FindFile # See function `FindFile` below.
Set-Alias -Name g -Value git -Option AllScope
function Get-GitStatus {
  & git status $args 
}
New-Alias -Name gs -Value Get-GitStatus -Option AllScope
function Set-GitAdd {
  & git add . 
}
New-Alias -Name ga -Value Set-GitAdd -Option AllScope
function Set-GitCommit {
  & git commit -m $args 
}
New-Alias -Name gc -Value Set-GitCommit -Option AllScope -Force # Force to override existing `gc` -> Get-Content
function Set-GitDiff {
  & git diff $args
}
New-Alias -Name gd -Value Set-GitDiff -Option AllScope -Force
function Set-GitRestore {
  & git restore $args 
}
New-Alias -Name gr -Value Set-GitRestore -Option AllScope -Force
function Set-GitQuickCommit {
  & git commit -am $args 
}
New-Alias -Name gq -Value Set-GitQuickCommit -Option AllScope
function Set-GitPull {
  & git pull 
}
New-Alias -Name gl -Value Set-GitPull -Force -Option AllScope
function Set-GitPush {
  & git push 
}
New-Alias -Name gp -Value Set-GitPush -Force -Option AllScope
function Set-GitFetch {
  & git fetch 
}
New-Alias -Name gf -Value Set-GitFetch -Force -Option AllScope
function Get-GitCheckout {
  $output = & git checkout $args | Out-String
  if ($output.StartsWith("Your branch is")) {
    Write-Output "Checking for updates.."
    git fetch 
    $gitBehind = cmd.exe /c 'git status | find /i "Your branch is behind"'
    $gitNormal = cmd.exe /c 'git status | find /i "Your branch is up to date with"'
    $gitAhead = cmd.exe /c 'git status | find /i "Your branch is ahead"'
    if ($gitBehind) {
      Write-Output ("Your branch is behind on remote '{0}'." -f $output.Split("'")[1])
      return
    }
    elseif ($gitNormal) {
      Write-Output ("Your branch is up to date with remote '{0}'." -f $output.Split("'")[1])
      return
    }
    elseif ($gitAhead) {
      Write-Output ($output.Split([Environment]::NewLine) | Select -First 1)
    }
    else {
      Write-Output "Run git status to see actual status"
    }
  }
  else {
    Write-Output $output
  }
}
New-Alias -Name gco -Value Get-GitCheckout -Force -Option AllScope
function Get-GitTree {
  & git log --all --graph --decorate $args
}
New-Alias -Name gt -Value Get-GitTree -Force -Option AllScope
function Get-GitBranch {
  & git branch $args 
}
New-Alias -Name gb -Value Get-GitBranch -Force -Option AllScope
function Clean-Local-Branches {
  & git fetch -p && git branch -vv | awk '!/\*/' | awk '/: gone]/{print $1}'
  }
New-Alias -Name gclb -Value Clean-Local-Branches -Force -Option AllScope

# Carapace options
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# Show history. History mode has two options: predition and listview. It can be toggled with `F2`.
Set-PSReadLineOption -PredictionViewStyle ListView
# Scroll through history suggestions with `Ctrl+n` and `Ctrl+p` key combinations.
Set-PSReadLineKeyHandler -Chord Ctrl+n -Function NextHistory 
Set-PSReadLineKeyHandler -Chord Ctrl+p -Function PreviousHistory 

# Open PS fzf with <C-t>
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' 

# Init zoxide in PS, then set alias.
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Set-Alias -Name cd -Value z -Option AllScope
# Open PS fzf with <C-t>
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' 

# Init zoxide in PS, then set alias.
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Set-Alias -Name cd -Value z -Option AllScope

# Create a function to trigger fzf from the current directory to bind to `fe`: 'Find Everything'.
function FindFile {
  Get-ChildItem . -Recurse -Attributes !Directory | Invoke-Fzf | ForEach-Object { nvim $_ }
}

#region Smart Insert/Delete

Set-PSReadLineKeyHandler -Key '"',"'" `
  -BriefDescription SmartInsertQuote `
  -LongDescription "Insert paired quotes if not already on a quote" `
  -ScriptBlock {
  param($key, $arg)

  $quote = $key.KeyChar

  $selectionStart = $null
  $selectionLength = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  # If text is selected, just quote it without any smarts
  if ($selectionStart -ne -1) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    return
  }

  $ast = $null
  $tokens = $null
  $parseErrors = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

  function FindToken {
    param($tokens, $cursor)

    foreach ($token in $tokens) {
      if ($cursor -lt $token.Extent.StartOffset) {
        continue 
      }
      if ($cursor -lt $token.Extent.EndOffset) {
        $result = $token
        $token = $token -as [StringExpandableToken]
        if ($token) {
          $nested = FindToken $token.NestedTokens $cursor
          if ($nested) {
            $result = $nested 
          }
        }

        return $result
      }
    }
    return $null
  }

  $token = FindToken $tokens $cursor

  # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
  if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
    # If we're at the start of the string, assume we're inserting a new string
    if ($token.Extent.StartOffset -eq $cursor) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
      return
    }

    # If we're at the end of the string, move over the closing quote if present.
    if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
      return
    }
  }

  if ($null -eq $token -or
    $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
    if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
      # Odd number of quotes before the cursor, insert a single quote
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
    } else {
      # Insert matching quotes, move cursor to be in between the quotes
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    return
  }

  # If cursor is at the start of a token, enclose it in quotes.
  if ($token.Extent.StartOffset -eq $cursor) {
    if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
      $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
      $end = $token.Extent.EndOffset
      $len = $end - $cursor
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
      return
    }
  }

  # We failed to be smart, so just insert a single quote
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(','{','[' `
  -BriefDescription InsertPairedBraces `
  -LongDescription "Insert matching braces" `
  -ScriptBlock {
  param($key, $arg)

  $closeChar = switch ($key.KeyChar) {
    <#case#> '(' {
      [char]')'; break 
    }
    <#case#> '{' {
      [char]'}'; break 
    }
    <#case#> '[' {
      [char]']'; break 
    }
  }

  $selectionStart = $null
  $selectionLength = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
  if ($selectionStart -ne -1) {
    # Text is selected, wrap it in brackets
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
  } else {
    # No text is selected, insert a pair
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  }
}

Set-PSReadLineKeyHandler -Key ')',']','}' `
  -BriefDescription SmartCloseBraces `
  -LongDescription "Insert closing brace or skip" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($line[$cursor] -eq $key.KeyChar) {
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  } else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
  }
}

Set-PSReadLineKeyHandler -Key Backspace `
  -BriefDescription SmartBackspace `
  -LongDescription "Delete previous character or matching quotes/parens/braces" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($cursor -gt 0) {
    $toMatch = $null
    if ($cursor -lt $line.Length) {
      switch ($line[$cursor]) {
        <#case#> '"' {
          $toMatch = '"'; break 
        }
        <#case#> "'" {
          $toMatch = "'"; break 
        }
        <#case#> ')' {
          $toMatch = '('; break 
        }
        <#case#> ']' {
          $toMatch = '['; break 
        }
        <#case#> '}' {
          $toMatch = '{'; break 
        }
      }
    }

    if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
    } else {
      [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
    }
  }
}

#endregion Smart Insert/Delete
