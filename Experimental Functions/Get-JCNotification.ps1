
function Get-JCNotification
{
    [CmdletBinding()]
    param (
        
    )
    
    begin
    {
        Write-Verbose 'Verifying JCAPI Key'
        if ($JCAPIKEY.length -ne 40) {Connect-JCOnline}

        Write-Verbose 'Populating API headers'
        $hdrs = @{

            'Content-Type' = 'application/json'
            'Accept'       = 'application/json'
            'X-API-KEY'    = $JCAPIKEY

        }


        Write-Verbose 'Initilizing resultsArray'
        $resultsArray = @()
    }
    
    process
    {

        $Url = 'https://console.jumpcloud.com/api/notifications/grouped'

        $Results = Invoke-RestMethod -Method Get -Uri $Url -Headers $hdrs

        foreach ($R in $Results)
        {

            $Username = $R.systemuser.name
            $UserID = $R.systemuser.id
            $Conflict = $R.conflicts.type

            Foreach ($C in $R.conflicts.systems)
            {

                $DisplayName = $C.DisplayName
                $SystemID = $C.id

                $FormattedResults = [PSCustomObject]@{
                
                    'ConflictType' = $Conflict
                    'Username'     = $Username
                    'UserID'       = $UserID
                    'DisplayName'  = $DisplayName
                    'SystemID'     = $SystemID
    
    
                }

                $resultsArray += $FormattedResults

            }
            
        }

    }
    
    end
    {
        Return $resultsArray
    }
}
