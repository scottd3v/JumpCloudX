#########################################################################################
#
# JumpCloud Account Specific Variables
# 
# The Connect Key for your organization is located within in the 'Systems' tab in the JumpCloud admin console. To find it navigate to the 'Sytems' tab and press the (+) and select the 'Windows' or 'Mac' tab to see and copy the connect key.
#
#########################################################################################

$CONNECT_KEY="" #Enter your connect key here. If you're unsure where to find your connect key see the text above. 

#########################################################################################
#
# Default Variables
#
#########################################################################################


$AGENT_PATH="${env:ProgramFiles(x86)}\JumpCloud"
$AGENT_CONF_FILE="\Plugins\Contrib\jcagent.conf"
$AGENT_BINARY_NAME="jumpcloud-agent.exe"

$AGENT_SERVICE_NAME="jumpcloud-agent"

$AGENT_INSTALLER_URL="https://s3.amazonaws.com/jumpcloud-windows-agent/production/JumpCloudInstaller.exe"
$AGENT_INSTALLER_PATH="$env:TEMP\JumpCloudInstaller.exe"
$AGENT_UNINSTALLER_NAME="unins000.exe"


$EVENT_LOGGER_KEY_NAME="hklm:\SYSTEM\CurrentControlSet\services\eventlog\Application\jumpcloud-agent"

$INSTALLER_BINARY_NAMES="JumpCloudInstaller.exe,JumpCloudInstaller.tmp"

#########################################################################################
#
# Agent Installer Funcs
#
#########################################################################################

Function DownloadAgentInstaller() {
    (New-Object System.Net.WebClient).DownloadFile("${AGENT_INSTALLER_URL}", "${AGENT_INSTALLER_PATH}")
}

Function AgentInstallerExists() {
    Test-Path ${AGENT_INSTALLER_PATH}
}

Function InstallAgent() {
    $params = ("${AGENT_INSTALLER_PATH}", "-k ${CONNECT_KEY}", "/VERYSILENT", "/NORESTART", "/SUPRESSMSGBOXES", "/NOCLOSEAPPLICATIONS", "/NORESTARTAPPLICATIONS", "/LOG=$env:TEMP\jcUpdate.log")
    Invoke-Expression "$params"
}

Function UninstallAgent() {
    # Due to PowerShell's incredible weakness in dealing with paths containing SPACEs, we need to
    # to hard-code this path...
    $params = ('C:\Program?Files??x86?\JumpCloud\unins000.exe', "/VERYSILENT", "/SUPPRESSMSGBOXES")
    Invoke-Expression "$params"
}

Function KillInstaller() {
    try {
        Stop-Process -processname ${INSTALLER_BINARY_NAMES} -ErrorAction Stop
    } catch {
        Write-Error "Could not kill JumpCloud installer processes"
    }
}

Function KillAgent() {
    try {
        Stop-Process -processname ${AGENT_BINARY_NAME} -ErrorAction Stop
    } catch {
        Write-Error "Could not kill running jumpcloud-agent process"
    }
}

Function InstallerIsRunning() {
    try {
        Get-Process ${INSTALLER_BINARY_NAMES} -ErrorAction Stop
        $true
    } catch {
        $false
    }
}

Function AgentIsRunning() {
    try {
        Get-Process ${AGENT_BINARY_NAME} -ErrorAction Stop
        $true
    } catch {
        $false
    }
}

Function AgentIsOnFileSystem() {
    Test-Path ${AGENT_PATH}/${AGENT_BINARY_NAME}
}

Function DeleteAgent() {
    try {
        Remove-Item ${AGENT_PATH}/${AGENT_BINARY_NAME} -ErrorAction Stop
    } catch {
        Write-Error "Could not remove remaining jumpcloud-agent.exe binary"
    }
}



#########################################################################################
#
# System Rename Installer Funcs
#
#########################################################################################

Function Rename-JCComputer
{
    <#
    .SYNOPSIS
    Renames a computer using the command 'Rename-Computer' 

    .DESCRIPTION
    Renames a computer and then restarts the computer using confirmation and prompt

    .EXAMPLE
    Rename-JCComputer -NewComputerName MyComputer1
    
    .PARAMETER NewComputerName
    The new computer name

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [ValidateLength(3, 15)]
        [ValidateScript({If ($_ -ne $env:computername) {
            $True
        } Else {
            Throw "Cannot update computer name to current computer name. Current computer name already is set to $_"
        }})]
        [string]$NewComputerName
    )
  
    begin
    {

        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`

                [Security.Principal.WindowsBuiltInRole] "Administrator"))

        {

            Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"

            Break

        }

    }
  
    process
    {


        Write-Warning "Are you sure you wish to rename computer $($env:computername) to $NewComputerName ?" -WarningAction Inquire

        Try{

            $RenameAdd = Rename-Computer $NewComputerName 

            $Status = "Succes name has been updated to: " +  $NewComputerName + " PENDING RESTART"

        }
        

        Catch{

            $Status = $_.ErrorDetails
            Write-Host $Status

        }
      
    }
    end {


        while ($Confirm -ne 'Y' -and $Confirm -ne 'N')
        {
            Write-Host "Success! The computer name has been updated PENDING RESTART`n" -ForegroundColor Green
           
            Write-Host "Would you like to restart now?`n"

            $Confirm = Read-Host "Enter 'Y' to restart. Enter 'N' to return to the menu" 
        }

        if ($Confirm -eq 'Y'){

            Restart-Computer -ComputerName $env:computername -Force

        }

        elseif ($Confirm -eq 'N')
        {
            #Invoke-Menu
        }

    }
}

#########################################################################################
#
# Account Rename Funcs
#
#########################################################################################

Function Get-Hash_SID_Username ()
{
    $UsersHash = New-Object System.Collections.Hashtable

    $Users = get-wmiobject -Class win32_useraccount -Filter "domain= '$env:COMPUTERNAME'"


        foreach ($User in $Users)
        {
            $UsersHash.Add($User.Name, $User.SID)

        }
    return $UsersHash
}
Function Get-Hash_LoggedIn_SessionID ()
{
    $UsersHash = New-Object System.Collections.Hashtable

    $Users = Get-LoggedInUsers

        foreach ($User in $Users)
        {
            $UsersHash.Add($User.Username, $User.ID)

        }
    return $UsersHash
}

Function Get-LoggedInUsers {
    [CmdletBinding()] 
    param(
        [Parameter(ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = 'localhost'
    )
    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                    $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
                    $HashProps = @{
                        UserName = $CurrentLine[0]
                        ComputerName = $Computer
                    }

                    # If session is disconnected different fields will be selected
                    if ($CurrentLine[2] -eq 'Disc') {
                            $HashProps.SessionName = $null
                            $HashProps.Id = $CurrentLine[1]
                            $HashProps.State = $CurrentLine[2]
                            $HashProps.IdleTime = $CurrentLine[3]
                            $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                            $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '
                    } else {
                            $HashProps.SessionName = $CurrentLine[1]
                            $HashProps.Id = $CurrentLine[2]
                            $HashProps.State = $CurrentLine[3]
                            $HashProps.IdleTime = $CurrentLine[4]
                            $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '
                    }

                    New-Object -TypeName PSCustomObject -Property $HashProps |
                    Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
                }
            } catch {
                New-Object -TypeName PSCustomObject -Property @{
                    ComputerName = $Computer
                    Error = $_.Exception.Message
                } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
            }
        }
    }

}

Function Get-Hash_Username_Enabled ()
{
    $UsersHash = New-Object System.Collections.Hashtable

    $Users = get-wmiobject -Class win32_useraccount -Filter "domain= '$env:COMPUTERNAME'" | ? Disabled -EQ $False

        foreach ($User in $Users)
        {
            $UsersHash.Add($User.Name, $User.SID)

        }
    return $UsersHash
}

Function Get-Hash_UsersWProfiles_SID_PSPath ()
{
    $UsersWithProfile = New-Object System.Collections.Hashtable

    $Users = Get-ChildItem  "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select @{Name = 'SID'; Expression = {($_.Name).replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\",'')}}, PSPath


        foreach ($User in $Users)
        {
            $UsersWithProfile.Add($User.SID, $User.PSPath)

        }
    return $UsersWithProfile
}

Function Rename-JCUser {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True,
        ValueFromPipelineByPropertyName = $True)]
        [ValidateLength(3, 20)]
        [ValidateScript({If ($_ -ne $env:username) {
        $True
        } Else {
        Throw "Cannot update logged in user. Log in with a different account to update this account."
        }})]
        [string]$CurrentUserName,

        [Parameter(Mandatory = $True,
        ValueFromPipelineByPropertyName = $True)]
        [ValidateLength(3, 20)]
        [string]$NewUserName
    )
  
    begin
    {

        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`

                [Security.Principal.WindowsBuiltInRole] "Administrator"))

        {

            Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"

            Break

        }

        $AllUsers = Get-Hash_SID_Username

        $ActiveUsers = Get-Hash_Username_Enabled

        $ProfileUsers = Get-Hash_UsersWProfiles_SID_PSPath
        
        $ActiveUsers.Remove($env:USERNAME)

        $FormattedResults = @()



    }
    
    process {

        #Rename user account

       if ( $ActiveUsers.Get_Item($CurrentUserName) -and !($AllUsers.ConTainsKey($NewUserName))) {

        if ($ProfileUsers.Containskey($ActiveUsers.get_item("$CurrentUserName"))){

            try {
                    net user $CurrentUserName /fullname:"$NewUserName" | Out-Null #Updates displayName

                    $DisplayNameStatus = 'Success'


                try {

                    $NameUpdate = get-wmiobject -Class win32_useraccount -Filter "domain= '$env:COMPUTERNAME'"  | where name -like "$CurrentUsername" #Update Username
                    
                    $NameUpdate.rename($NewUserName) | Out-Null

                    $NameUpdateStatus = 'Success'


                        try{
                            
            

                            $CurrentPath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($ActiveUsers.$CurrentUsername)" | Select ProfileImagePath

                            Rename-Item -Path $CurrentPath.ProfileImagePath -NewName $NewUserName | Out-Null #Renames home folder

                            $FolderUpdateStatus = 'Success'


                            try {

                                Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($ActiveUsers.$CurrentUsername)" -Name ProfileImagePath -Value "C:\Users\$NewUserName" | Out-Null #Updates registry profile
        
                                $RegistryUpdateStatus = 'Success'

                            }

                            catch {

                                $RegistryUpdateStatus = 'Failed'


                            }
        
                        }
        
                        catch {

                            $FolderUpdateStatus = 'Failed'
        
        
                        }

                    }

                    catch {

                        $NameUpdateStatus = 'Failed'

                    }
                }
                
                catch {

                    net user $CurrentUserName /fullname:"$CurrentUserName"

                    $DisplayNameStatus = 'Failed'
        
                }

                $FormattedResults =[PSCustomObject]@{

                    'Username Update' = $NameUpdateStatus
                    'Home Folder Update' = $FolderUpdateStatus
                    'Registry Profile Update' = $RegistryUpdateStatus
                    'Display Name' = $DisplayNameStatus
                    
                    }

        }

            else {

                    try {
                        net user $CurrentUserName /fullname:"$NewUserName" | Out-Null #Updates displayName

                        $DisplayNameStatus = 'Success'


                        try {

                            $NameUpdate = get-wmiobject -Class win32_useraccount -Filter "domain= '$env:COMPUTERNAME'"  | where name -like "$CurrentUsername" #Update Username
                            
                            $NameUpdate.rename($NewUserName) | Out-Null

                            $NameUpdateStatus = 'Success'

                        }
                        
                        catch {

                            $NameUpdateStatus = 'Failed'

                        }

                    }

                    catch {

                        $DisplayNameStatus = 'Failed'


                    }
                    
                    $FormattedResults =[PSCustomObject]@{

                        'Username Update' = $NameUpdateStatus                        
                        'Display Name' = $DisplayNameStatus
                        
                        }

            }

        }

        else {

            Write-Error "Cannot update this user"
    
        }


    }
    
    end {

        Return $FormattedResults    
        
    }
}




#########################################################################################
#
# Service Manager Funcs
#
#########################################################################################
Function AgentIsInServiceManager() {    
    try {
        $services = Get-Service -Name "${AGENT_SERVICE_NAME}" -ErrorAction Stop
        $true
    } catch {
        $false
    }
}

Function RemoveAgentService() {
    $service = Get-WmiObject -Class Win32_Service -Filter "Name='${AGENT_SERVICE_NAME}'"
    if ($service) {
        try {
            $service.Delete()
        } catch {
            Write-Error "Could not remove jumpcloud-agent service entry"
        }
    }
}

Function RemoveEventLoggerKey() {
    try {
        Remove-Item -Path "$EVENT_LOGGER_KEY_NAME" -ErrorAction Stop
    } catch {
        Write-Error "Could not remove event logger key from registry"
    }
}



############################################################################################
#
# Work functions (uninstall, clean up, and reinstall)
#
############################################################################################
Function AgentIsInstalled() {
    $inServiceMgr = AgentIsInServiceManager
    $onFileSystem = AgentIsOnFileSystem

    $inServiceMgr -Or $onFileSystem
}

Function CheckForAndUninstallExistingAgent() {
    #
    # Is the installer running/hung?
    #
    if (InstallerIsRunning) {
        # Yep, kill it
        KillInstaller
        
        Write-Host "Killed running agent installer."
    }

    #
    # Is the agent running/hung?
    #
    if (AgentIsRunning) {
        # Yep, kill it
        KillAgent
        
        Write-Host "Killed running agent binary."
    }

    #
    # Is the agent still fully installed in both the service manager and on the file system?
    #
    if (AgentIsInstalled) {
        # Yep, try a normal uninstall
        UninstallAgent
        
        Write-Host "Completed agent uninstall."
    }
}

Function CleanUpAgentLeftovers() {
    # Remove any remaining event logger key...
    RemoveEventLoggerKey

    #
    # Is the agent still in the service manager?
    #
    if (AgentIsInServiceManager) {
        # Try to remove it, though it probably won't remove because we may in the state
        # where the service is "marked for deletion" (requires reboot before further
        # modifications can be done on this service).
        RemoveAgentService
        
        if (AgentIsInServiceManager) {
            Write-Host "Unable to remove agent service, this system needs to be rebooted."
            Write-Host "Then you can re-run this script to re-install the agent."
            exit 1
        }
        
        Write-Host "Removed agent service entry."
    }

    #
    # Is the agent still on the file system?
    #
    if (AgentIsOnFileSystem) {
        # Yes, the installer was unsuccessful in removing it.
        DeleteAgent
        
        Write-Host "Removed remaining agent binary file."
    }
}

############################################################################################
#
# Do a normal agent install, and verify correct installation
#
############################################################################################
Function DownloadAndInstallAgent() {
    $agentIsInstalled = AgentIsInstalled
    if (-Not $agentIsInstalled) {
        Write-Host -nonewline "Downloading agent installer..."

        DownloadAgentInstaller

        if (AgentInstallerExists) {
            Write-Host " complete."

            Write-Host -nonewline "Installing agent..."
            InstallAgent
            Start-Sleep -s 5
            $exitCode = $?
            $agentIsInstalled = AgentIsInstalled

            Write-Host " complete. (exit code=$exitCode)"

            if ($exitCode -ne $true) {
                Write-Error "Agent installation failed. Please rerun this script,`nand if that doesn't work, please reboot and try again.`nIf neither work, please contact support@jumpcloud.com"
                exit 1
            } else {
               Write-Host "`n* * * SUCCESS! Agent installation complete. * * *" 
            }                
        } else {
            Write-Error "Could not download agent installer from ${AGENT_INSTALLER_URL}. Install FAILED."
            exit 1
        }
    } else {
        Write-Host "Agent is already installed, not installing again."
    }
}

#########################################################################################
#
# Invoke-JCSystemCloudPrep Menu
#
#########################################################################################

Function Invoke-JCSystemCloudPrep {

    [cmdletbinding()]
    Param()

    begin{

        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){

            Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"

            Break

        }

        $ActiveUsers = Get-Hash_Username_Enabled

        $AllUsers = Get-Hash_SID_Username

        $LoggedInUsers = Get-Hash_LoggedIn_SessionID

        $ProfileUsers = Get-Hash_UsersWProfiles_SID_PSPath
         

    }
    
    process{


        $JCAgentStatus = Get-Service | ? Name -Like *JumpCloud* | Select Status

        Clear-Host
          
        $Banner = @"
        __
       / /  __  __   ____ ___     ____
  __  / /  / / / /  / __  __ \   / __ \
 / /_/ /  / /_/ /  / / / / / /  / /_/ /
 \____/   \____/  /_/ /_/ /_/  /  ___/
                              /_/
   ______   __                      __
  / ____/  / /  ____   __  __  ____/ /
 / /      / /  / __ \ / / / / / __  /
/ /___   / /  / /_/ // /_/ / / /_/ /
\____/  /_/   \____/ \____/  \____/
                 
                    System Cloud Prep

"@
        
        
        $menu = @"

================ MENU ==================
            
  1. Rename a local user account
       
  2. Rename computer (Restart Required)

  3. Install JumpCloud Agent

  4. Uninstall JumpCloud Agent

  5. Quit

========================================
        
"@
        
        Write-Host $Banner -ForegroundColor Green

        Write-Host "============= SYSTEM INFO ============== `n"

        Write-Host "System Name: " -NoNewline  
         
        Write-Host "$env:COMPUTERNAME `n" -ForegroundColor Yellow

        Write-Host "Logged In User: " -NoNewLine  

        Write-Host "$env:USERNAME `n" -ForegroundColor Yellow
        
        Write-Host "JumpCloud Agent Status:" -NoNewline  

        switch ($JCAgentStatus.Status) {
            'Running' { Write-Host " $($JCAgentStatus.Status)" -ForegroundColor Green  }
            'Stopped' { Write-Host " $($JCAgentStatus.Status)" -ForegroundColor Red }
             Default {Write-Host ' Not Installed' -ForegroundColor Red}
        }


        Write-Host $menu
    
        [int]$r = Read-Host "Select a menu choice"
        
        #validate the input choice
        if ((1..5) -notcontains $r ) {
                write-warning "$r is not a valid choice"
                pause
                Invoke-JCRenameHelper
        }
        #code to execute
        Switch ($r) {
            1 {
                Clear-host

                Write-Host $Banner -ForegroundColor Green

                Write-Host "============= RENAME USER ============== `n"

                Write-Host "Enter the number of the user you wish to rename `n" -ForegroundColor Yellow
                 
                $ActiveUserHash = Get-Hash_Username_Enabled

                $ActiveUserHash.Remove($env:Username)

                $AvaliableUsers = @()

                $Number = 1

                Foreach ($User in $ActiveUserHash.GetEnumerator()) {

                    $EditUsers = New-Object -TypeName PSCustomObject

                    $EditUsers | Add-Member -MemberType NoteProperty -Name Username $User.name

                    $EditUsers | Add-Member -MemberType NoteProperty -Name Number $i

                    $Number ++

                    $AvaliableUsers += $EditUsers
        
                }

                $menu = @{}

                for ($i=1;$i -le $AvaliableUsers.count; $i++) {
                Write-Host "$i. $($AvaliableUsers[$i-1].Username)"
                $menu.Add($i,($AvaliableUsers[$i-1].Username))
                }

                [int]$ans = Read-Host "`nEnter a number between 1 and $($AvaliableUsers.count)"
                $selection = $menu.Item($ans)

                while ((1..$AvaliableUsers.count) -notcontains $ans ) {
                    write-warning "$ans is not a valid choice"
                    [int]$ans = Read-Host "`nEnter a number between 1 and $($AvaliableUsers.count)"
                    $selection = $menu.Item($ans)
                }   

                Write-host "`nEnter a new username for user: $($selection). Enter Q to return to the MENU."
                Write-host "`nIt is best practice to create usernames in all lowercase`n" -ForegroundColor Yellow


                $NewUserName = Read-Host "New UserName:"

                if ($NewUserName -eq 'q') {
                    
                    break
                }

                if ($AllUsers.$NewUsername){

                    Write-Warning "$NewUserName cannot be used because a user with this username already exists"
                    Write-host "`nEnter a new username for user: $($selection). Enter Q to return to the MENU."
                    $NewUserName = Read-Host "New UserName:"

                    if ($NewUserName -eq 'q') {
                        
                        break
                    }

                }

                    Clear-host

                    Write-Host $Banner -ForegroundColor Green
        
                    Write-Host "============= RENAME USER ============== `n"

                    Write-Host "Current Username: $($selection) `n"
                    Write-Host "New Username: $($NewUserName) `n"

                    if ($ProfileUsers.Containskey($ActiveUsers.get_item("$selection"))) {

                        Write-Host "`nWARNING: Any applications that may have depended on the old username will not be updated by the System Cloud Prep Rename Utility." -ForegroundColor Red
                        Start-Sleep -s 2
                        Write-Host "`nThe System Cloud Prep Rename Utility will update the DisplayName, Username, HomeFolder, and ProfileImagePath for user: $($selection)" -ForegroundColor Yellow
                        Start-Sleep -s 2
                        Write-Host "`nIt is possible that certain applications that depend on the old uername may need to be reconfigurd or reinstalled after updating the username" -ForegroundColor Yellow
                        Start-Sleep -s 2 
                        Write-Host "`nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE." -ForegroundColor Yellow
                        Start-Sleep -s 3

                    }

                    else {

                        Write-Host "`nWARNING: Any applications that may have depended on the old username will not be updated by the System Cloud Prep Rename Utility." -ForegroundColor Red
                        Start-Sleep -s 2
                        Write-Host "`nThe System Cloud Prep Rename Utility will update the DisplayName and Username for user: $($selection)" -ForegroundColor Yellow
                        Start-Sleep -s 2
                        Write-Host "`nIt is possible that certain applications that depend on the old uername may need to be reconfigurd or reinstalled after updating the username" -ForegroundColor Yellow
                        Start-Sleep -s 2 
                        Write-Host "`nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.`n" -ForegroundColor Yellow
                        Start-Sleep -s 3


                    }

                    if ($LoggedInUsers.containskey($selection )) {

                        Write-Warning "$selection is logged in user will be logged of during name change"
                    
                    }


                    $Accept = Read-Host  "`nType: 'Yes' if you wish to continue or Q to cancel and return to the MENU`n"


                    if ($Accept -eq 'q') {

                        break
                    }

                    While ($Accept -notcontains 'Yes'){

                        write-warning " Typo? $Accept != 'Yes'"

                        $Accept = Read-Host "`nType: 'Yes' if you wish to continue or Q to cancel and return to the MENU"

                        if ($Accept -eq 'q') {

                            break
                        }

                    }

                    if ($LoggedInUsers.containskey($selection )) {

                        Logoff $LoggedInUsers.($selection )
                    
                    }
      
                    $Rename = Rename-JCUser -CurrentUserName $selection -NewUserName $NewUserName

                    $Rename | ft

                    Pause 
                    
                    Break
            
            }

            2 {
                Clear-host

                Write-Host $Banner -ForegroundColor Green

                Write-Host "=========== RENAME COMPUTER ============ `n"
                
                $NewComputerName = Read-Host "Enter a new computer name"

                Rename-JCComputer -NewComputerName $NewComputerName

                Pause

                Break
               
            }
            3 {
                
                Clear-host

                Write-Host $Banner -ForegroundColor Green

                Write-Host "======= INSTALL JUMPCLOUD AGENT ======== `n"

                # $CONNECT_KEY = Read-Host "Enter Connect Key" #Uncomment if you wish to enter Connect Key and not hardcode this value 

                DownloadAndInstallAgent

                Start-Sleep -s 2

                Pause

                Break
            }

            4 {
                Clear-host

                Write-Host $Banner -ForegroundColor Green

                Write-Host "====== UNINSTALL JUMPCLOUD AGENT ======= `n"

                Write-Host "Are you sure you wish to uninstall the JumpCloud Agent`n" -ForegroundColor Yellow

                $UninstallConfirm = Read-Host  "`nEnter: 'Y' to continue or 'Q' to cancel and return to the MENU"

                if ($UninstallConfirm -eq 'q') {

                    break
                }

                While ($UninstallConfirm -notcontains 'Y'){

                    write-warning " Typo? $Accept != 'Y'"
                    $UninstallConfirm  = Read-Host "`nEnter: 'Y' to continue or 'Q' to cancel and return to the MENU"

                    if ($UninstallConfirm -eq 'q') {

                        break
                    }

                }

                UninstallAgent

                Pause
                
                Break
            }
            5 {
                CLS
                Write-Host "Have a nice day" -ForegroundColor Green
                Start-Sleep -s 1
                ClS
                Exit
                
                
            }
        } 
    
        Invoke-JCSystemCloudPrep
    
    }

    end{}
    
}
Invoke-JCSystemCloudPrep