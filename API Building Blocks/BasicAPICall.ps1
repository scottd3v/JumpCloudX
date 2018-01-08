
# API Call - GET Example

$APIkey = "Replace with API KEY"

$Url = "Replace with URL"

$hdrs = @{
    
    'Content-Type' = 'application/json'
    'Accept'       = 'application/json'
    'X-API-KEY'    = $APIkey

}

$APIresults = Invoke-RestMethod -Method GET -Uri $Url  -Header $hdrs

$APIresults | ConvertTo-Json
