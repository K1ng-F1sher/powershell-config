# Set prompt before anything else
function prompt {
  $IsAdmin = IsAdmin

  if ($IsAdmin) {
    Write-Host "[ADMIN] " -NoNewline -ForegroundColor Red
  }

  $date = Get-Date -format 'HH:mm:ss'

  # Smart path
  $loc = Split-Path -leaf -path (Split-Path -parent -path ($executionContext.SessionState.Path.CurrentLocation));
  if (Split-Path -parent -path (Split-Path -parent -path ($executionContext.SessionState.Path.CurrentLocation))) {
    $loc = "..\" + $loc;
  }
  if (!$loc) {
    $loc = Split-Path -leaf -path ($executionContext.SessionState.Path.CurrentLocation);
  } else {
    $loc = $loc.TrimEnd("\")
    $loc += "\"
    $loc += Split-Path -leaf -path ($executionContext.SessionState.Path.CurrentLocation);
  }

  $host.UI.RawUI.WindowTitle = $IsAdmin ? "PS7 [ADMIN] | " : "PS7 | "; 
  $host.UI.RawUI.WindowTitle += $loc 

  Write-Host $date -NoNewLine -ForegroundColor "DarkYellow"
  # Set the path in the prompt (invisible), so <C-S-d> and <Alt-S-+> work.
  if ($loc.Provider.Name -eq "FileSystem") {
    Write-Host "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\" -NoNewLine 
  }
  Write-Host " $loc" -NoNewLine -ForegroundColor "DarkGray"
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

# Lazy (or deferred) load slow modules below.
# All code below is copied from:
# https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/
$Deferred = {
  . "$HOME\Documents\PowerShell\console.ps1"
}

# https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes
$GlobalState = [psmoduleinfo]::new($false)
$GlobalState.SessionState = $ExecutionContext.SessionState

# to run our code asynchronously
$Runspace = [runspacefactory]::CreateRunspace($Host)
$Powershell = [powershell]::Create($Runspace)
$Runspace.Open()
$Runspace.SessionStateProxy.PSVariable.Set('GlobalState', $GlobalState)

# ArgumentCompleters are set on the ExecutionContext, not the SessionState
# Note that $ExecutionContext is not an ExecutionContext, it's an EngineIntrinsics 😡
$Private = [Reflection.BindingFlags]'Instance, NonPublic'
$ContextField = [Management.Automation.EngineIntrinsics].GetField('_context', $Private)
$Context = $ContextField.GetValue($ExecutionContext)

# Get the ArgumentCompleters. If null, initialise them.
$ContextCACProperty = $Context.GetType().GetProperty('CustomArgumentCompleters', $Private)
$ContextNACProperty = $Context.GetType().GetProperty('NativeArgumentCompleters', $Private)
$CAC = $ContextCACProperty.GetValue($Context)
$NAC = $ContextNACProperty.GetValue($Context)
if ($null -eq $CAC) {
  $CAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
  $ContextCACProperty.SetValue($Context, $CAC)
}
if ($null -eq $NAC) {
  $NAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
  $ContextNACProperty.SetValue($Context, $NAC)
}

# Get the AutomationEngine and ExecutionContext of the runspace
$RSEngineField = $Runspace.GetType().GetField('_engine', $Private)
$RSEngine = $RSEngineField.GetValue($Runspace)
$EngineContextField = $RSEngine.GetType().GetFields($Private) | Where-Object {$_.FieldType.Name -eq 'ExecutionContext'}
$RSContext = $EngineContextField.GetValue($RSEngine)

# Set the runspace to use the global ArgumentCompleters
$ContextCACProperty.SetValue($RSContext, $CAC)
$ContextNACProperty.SetValue($RSContext, $NAC)

$Wrapper = {
  # Without a sleep, you get issues:
  #   - occasional crashes
  #   - prompt not rendered
  #   - no highlighting
  # Assumption: this is related to PSReadLine.
  # 20ms seems to be enough on my machine, but let's be generous - this is non-blocking
  Start-Sleep -Milliseconds 200

  . $GlobalState {. $Deferred; Remove-Variable Deferred}
}

$null = $Powershell.AddScript($Wrapper.ToString()).BeginInvoke()
