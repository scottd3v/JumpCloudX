#### Name

Windows - Remove Automatic Updates  | v1.0 JCCG

#### commandType

windows

#### Command

```
## Removes the task "JCWindowsUpdates" 
## Removes the update script "JC_ScheduledWindowsUpdate.ps1"


SCHTASKS /Delete /tn "JCWindowsUpdates" /F

$FileName = 'JC_ScheduledWindowsUpdate.ps1'
$FilePath = "C:\Windows\Temp\JC_ScheduledTasks\$FileName"

Remove-Item -Path $FilePath

```

#### Description


#### *Import This Command*

To import this command into your JumpCloud tenant run the below command using the [JumpCloud PowerShell Module](https://github.com/TheJumpCloud/support/wiki/Installing-the-JumpCloud-PowerShell-Module)

```
Import-JCCommand -URL 'Create and enter Git.io URL'
```
