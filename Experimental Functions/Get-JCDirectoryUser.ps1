#Use this call to make the hash of directories 

$APIkey = 'REDACTED'

$Url = "https://console.jumpcloud.com/api/v2/directories"

$hdrs = @{
    
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
                'X-API-KEY' = $APIkey
    
                }

$APIresults = Invoke-RestMethod -Method GET -Uri $Url  -Header $hdrs

$APIresults | ConvertTo-Json


function Get-JCDirectoryUsers () {

    ## Returns office 365 / G-Suite / LDAP users
    
    ## Pull in directorys enpoint first / then return users based on the ID pulled. 

    ## Create a hash for directory / name and look for duplicates in error handling 

    ## Examples / comapre with users to find diff between all users and chosen directory 
    
}