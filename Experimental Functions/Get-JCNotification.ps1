function Get-JCNotification
{
    [CmdletBinding(DefaultParameterSetName = 'All')]

    param (

        [Parameter(
            ParameterSetName = 'GUIDConflict')]        
        [Switch]
        $GUIDConflict

        
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

        Write-Verbose "Paramter Set: $($PSCmdlet.ParameterSetName)"
    }
    
    process
    {   
        
        $Url = 'https://console.jumpcloud.com/api/notifications/grouped'

        $Results = Invoke-RestMethod -Method Get -Uri $Url -Headers $hdrs
        
        switch ($PSCmdlet.ParameterSetName)
        {
            All
            {  
               
                foreach ($R in $Results)
                {
        
                    $Username = $R.systemuser.name
                    $UserID = $R.systemuser.id
        
                    Foreach ($C in $R.conflicts)
                    {
        
                        $Conflict = $C.type
                        $ConflictMessage = $C.message

                        foreach ($S in $C.systems)
                        {

                            $SystemID = $S._id
                            $DisplayName = $S.DisplayName

                            $FormattedResults = [PSCustomObject]@{
                        
                                'ConflictType'    = $Conflict
                                'ConflictMessage' = $ConflictMessage
                                'Username'        = $Username
                                'UserID'          = $UserID
                                'DisplayName'     = $DisplayName
                                'SystemID'        = $SystemID
                
                
                            }
            
                            $resultsArray += $FormattedResults

                        }                        
        
                    }
                    
                }


            }
            GUIDConflict
            {

                foreach ($R in $Results)
                {
        
                    $Username = $R.systemuser.name
                    $UserID = $R.systemuser.id
        
                    Foreach ($C in $R.conflicts)
                    {
        
                        $Conflict = $C.type
                        $ConflictMessage = $C.message

                        if ($Conflict -eq "GID-CONFLICT")
                        {
                        
                            foreach ($S in $C.systems)
                            {

                                $SystemID = $S._id
                                $DisplayName = $S.DisplayName
    
                                $FormattedResults = [PSCustomObject]@{
                            
                                    'ConflictType'    = $Conflict
                                    'ConflictMessage' = $ConflictMessage
                                    'Username'        = $Username
                                    'UserID'          = $UserID
                                    'DisplayName'     = $DisplayName
                                    'SystemID'        = $SystemID
                    
                    
                                }
                
                                $resultsArray += $FormattedResults
    
                            }
                        }                            
                    }              
                }
            }
        }
    }
    
    end
    {
        Return $resultsArray
    }
   
}