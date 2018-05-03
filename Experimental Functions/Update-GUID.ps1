function Update-GUID
{
    [CmdletBinding()]
    param (

        [Parameter(Mandatory,
            ValueFromPipelineByPropertyName)]
        [String]$Username,

        [Parameter(Mandatory,
            ValueFromPipelineByPropertyName)]
        [String]$SystemID
        
    )

    begin
    { 
        Write-Verbose 'Verifying JCAPI Key'
        if ($JCAPIKEY.length -ne 40) {Connect-JCOnline}
        $ResultsArray = @()

    }
    
    process
    {           

        if (Get-JCSystem | Where-Object {($_.active -eq $true) -and ($_._id -eq $SystemID)})
        {   
            # Gets the JCUser information including unix_guid info

            $JCUser = Get-JCUser | Where-Object Username -EQ $Username
            
            # Paramters for command to update GUID

            $GUIDUpdateParams = @{
                commandType = 'mac'
                name        = "Temp_GUID Update $Username on System: $SystemID"
                command     = @"
sudo dscl . -create /Groups/$username name $username
sudo dscl . -create /Groups/$username gid $($JCUser.unix_guid)
sudo dscl . -create /Users/$username PrimaryGroupID $($JCUser.unix_guid)
"@
                launchType  = 'trigger'
                trigger     = "$($SystemID)$(Get-Date -Format MMddyyTHHmmss)"
                timeout     = 120
            }

            # Creates command to update user GUID
                
            $GUIDUpdate_TempCommand = New-JCCommand @GUIDUpdateParams

            # Adds System vis $SystemID to the new temp command
                
            Add-JCCommandTarget -CommandID $GUIDUpdate_TempCommand._id  -SystemID $SystemID

            # Runs the command
    
            Invoke-JCCommand -trigger $GUIDUpdate_TempCommand.trigger

            # Waits for 60 seconds for command to run

            Start-Sleep -Seconds 60

            # Removes temp command

            Remove-JCCommand -CommandID $GUIDUpdate_TempCommand._id -force

            # Looks for command output

            $GUIDUpdateOutputRaw = Get-JCCommandResult | Where-Object Name -EQ $GUIDUpdate_TempCommand.name

            # While loop to wait for command output if not imediatly present

            while (-not $GUIDUpdateOutputRaw)

            {
                Write-Host "Output not found trying again"
                Start-Sleep -Seconds 5
                $GUIDUpdateOutputRaw = Get-JCCommandResult | Where-Object Name -EQ $GUIDUpdate_TempCommand.name

            }

            # Looks at exit code of GUID update command

            If ($GUIDUpdateOutputRaw.exitCode -eq "0")
            {

                Write-Debug "GUID Update Successful for User: $Username on System: $SystemID"

                # Paramters to create command to restart agent

                $AgentRestartParams = @{
                    commandType = 'mac'
                    name        = "Temp_AgentRestart System: $SystemID"
                    command     = 'cd /opt/jc; stop=`launchctl stop com.jumpcloud.darwin-agent`'
                    launchType  = 'trigger'
                    trigger     = "$($SystemID)$(Get-Date -Format MMddyyTHHmmss)"
                    timeout     = 120
                }

                # Creates temp command to restart agent
                    
                $AgentRestart_TempCommand = New-JCCommand @AgentRestartParams

                # Adds System vis $SystemID to the new temp command
                    
                Add-JCCommandTarget -CommandID $AgentRestart_TempCommand._id  -SystemID $SystemID

                # Runs the command using the unique trigger
        
                Invoke-JCCommand -trigger $AgentRestart_TempCommand.trigger

                # Waits for 60 seconds for command to run

                Start-Sleep -Seconds 60

                # Removes temp command

                Remove-JCCommand -CommandID $AgentRestart_TempCommand._id -force

                # Looks for command output

                $AgentRestartResults = Get-JCCommandResult | Where-Object Name -EQ $AgentRestart_TempCommand.name

                while (-not $AgentRestartResults)

                {
                    Write-Host "Agent Restart Output not found trying again"
                    Start-Sleep -Seconds 5
                    $GUIDUpdateOutputRaw = AgentRestartResults = Get-JCCommandResult | Where-Object Name -EQ $AgentRestart_TempCommand.name
    
                }

                # Removes temp command (Does not provide an exit code)

                $RemoveAgentRestart = Remove-JCCommandResult -CommandResultID $AgentRestartResults._id -force

                # Formats successful object

                $FormattedResults = [PSCustomObject]@{

                    'Username'     = $username
                    'SystemID'     = $SystemID
                    'SystemStatus' = 'AgentRestarted'
                    'GUIDUpdate'   = 'Successful'
                }
        
                $ResultsArray += $FormattedResults
                    
            }

            else
            {
                # Formats unsuccessful object

                $FormattedResults = [PSCustomObject]@{

                    'Username'     = $username
                    'SystemID'     = $SystemID
                    'SystemStatus' = 'System Online'
                    'GUIDUpdate'   = $GUIDUpdateOutputRaw.exitCode
                }
        
                $ResultsArray += $FormattedResults
        
                    
            } # End else 'Exit code not 0'

        }

        else
        {
            # Formats unsuccessful object

            $FormattedResults = [PSCustomObject]@{

                'Username'     = $username
                'SystemID'     = $SystemID
                'SystemStatus' = 'System Offline'
                'GUIDUpdate'   = 'Not Attempted'
            }
    
            $ResultsArray += $FormattedResults
    
        } # End if 'System Online' for GUID Update
    } # End process 
                        
    
    end
    {
        Return $ResultsArray
    }

}



