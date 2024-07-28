<#
.SYNOPSIS
    Script to Remove Secure input & output from a logic app standard in Azure.

.DESCRIPTION
    This script connects to an azure logic app standard and removes ALL secure input/output configuration.
    WARNING: Don't use this in PRODUCTION

.PARAMETER LogicAppName
    The name of the Logic app standard

.NOTES
    Make sure the Azure context is set correctly to use managed identity for authentication.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$LogicAppName
)

# Connect to Azure if not already connected
#if (-not (Get-AzContext)) {
#    Connect-AzAccount -Identity
#}


function Update-SecureData {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$jsonObject
    )

    $foundMatch = $false

    foreach ($key in $jsonObject.PSObject.Properties.Name) {
        $value = $jsonObject.$key

        if ($key -eq "secureData" -and $value -is [PSCustomObject] -and $value.properties -is [System.Collections.IEnumerable] -and ($value.properties -contains "inputs" -or $value.properties -contains "outputs")) {
            $jsonObject.PSObject.Properties.Remove($key)
            $foundMatch = $true
        }

        if ($value -is [PSCustomObject]) {
            $childMatchFound = Update-SecureData -jsonObject $value
            if ($childMatchFound) {
                $foundMatch = $true
            }
        }
        elseif ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            foreach ($item in $value) {
                if ($item -is [PSCustomObject]) {
                    $childMatchFound = Update-SecureData -jsonObject $item
                    if ($childMatchFound) {
                        $foundMatch = $true
                    }
                }
            }
        }
    }

    return $foundMatch
}

# Get the access token
$token = (Get-AzAccessToken).Token
$kuduApiEndpoint = "https://$LogicAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/"
$headers = @{
    Authorization = "Bearer $token"
    'If-Match' = '*'
}

# Get the list of files and directories in the wwwroot folder
Write-Output "Attempting to connect to $($kuduApiEndpoint)"
$wwwRootFolder = Invoke-RestMethod -Uri $kuduApiEndpoint -Headers $headers -Method Get

# Loop directories
foreach ($item in $wwwRootFolder) {
    if ($item.mime -eq "inode/directory") {
        $subDirUri = [System.Uri]::EscapeUriString("$kuduApiEndpoint$($item.name)/")
        $subFiles = Invoke-RestMethod -Uri $subDirUri -Headers $headers -Method Get | Where-Object { $_.name -eq 'workflow.json' }
        if ($subFiles.Count -gt 0) {
            Write-Output "[$($item.name)] - Inspecing presence of secure input/output"
            # Receive workflow.json file content
            $fileContent = Invoke-RestMethod -Uri $subFiles[0].href -Headers $headers -Method Get

            # Update the JSON object
            $matchFound = Update-SecureData -jsonObject $fileContent

            # Match found, need to update file now.
            if ($matchFound) {
                $newFileContent = $fileContent | ConvertTo-Json -Depth 100
                $byteArray = [System.Text.Encoding]::UTF8.GetBytes($newFileContent)
                Write-Output "[$($item.name)] - Match found, uploading to azure"
                $result = Invoke-RestMethod -Uri $subFiles[0].href -Headers $headers -Method Put -Body $byteArray
                Write-Output  "[$($item.name)] - Succesfully Updated"
            }
        }
    }
}
