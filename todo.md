# To do

- Check if carapace can work with aliases, escpecially with git `gco`.
- Add terminal settings (Ctrl+,) to git

# Done (in reverse chronological order)

- Decided not to add git diff view: 
    - https://github.com/dandavison/delta - Diff view (posh?)
- Removed deferred loading. Too many errors during initializing.
- Use smart path to shorten elongated paths in prompt
- Added git aliases for quickly executing git actions
- Installed [PsFzf](https://github.com/kelleyma49/PSFzf?tab=readme-ov-file) with `scoop install psfzf`
- Added deferred loading [ref](https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/)
- Added the current dir to prompt, so Ctrl+D works for duplicating a tab ([ref](https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory))
- Removed posh-git and added a manual check for git repo to show current branch in prompt ([ref](https://stackoverflow.com/questions/1287718/how-can-i-display-my-current-git-branch-name-in-my-powershell-prompt))
- Installed carapace with scoop
- Installed scoop with `Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression`
- Added PS profile to git. Repo on [git](https://github.com/Lvdspek/powershell-config)
- Add `[ADMIN]` in front of the prompt when running as administrator.
- Set default folder to `C:\git` through Terminal settings.
- Use posh-git to format prompt.
- Installed posh-git with
  `Install-Module posh-git -Scope CurrentUser -Force -AllowClobber` rather than `choco`, because posh-git wasn't installed correctly by choco.
- Coloured blocks.
- Add timestamp to prompt: [here](https://www.reddit.com/r/PowerShell/comments/a2hs0i/adding_datetime_to_powershell_prompt/) and [here](https://jdhitsolutions.com/blog/powershell/6240/friday-fun-with-timely-powershell-prompts/) Also made the prompt update after executing it to show the time when the command executed.
- Configured PS profile to show packages that are not installed.
- Installed zoxide and aliased to `cd`.
- Installed FiraCode NF
