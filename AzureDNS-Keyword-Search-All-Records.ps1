<#------------------------------------------------------------------------------------------------------------------------------------------------------------------
AzureDNS-Keyword-Search-All-Records.ps1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Searches across all DNS Zones for specific records based on keywords
Author: Luke Wilkinson
Created: 8/08/2023
Last Modified: 8/08/2023
Last Modified By: Luke Wilkinson 

Script Function:
1. Installs required modules to connect to Azure DNS and export results to excel.
2. Searches all DNS Zones contained within a specific resource group, looking for records that contain specific keywords in the value. 
3. Exports the results to excel.
------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

# Install required modules if not already installed
$modules = "Az.Accounts", "ImportExcel"

foreach ($module in $modules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Force
    }
}

# Connect to Azure account
Connect-AzAccount

# Define the subscription ID and resource group name
$subscriptionId = "subscriptionID"
$resourceGroupName = "resourceGroupName"
$keywords = @("keyword1", "example.com", "anotherkeyword.com")

# Get the DNS zones in the resource group
$dnsZones = Get-AzDnsZone -ResourceGroupName $resourceGroupName

# Create an array to store the matched DNS records
$outputArray = @()

# Iterate over the DNS zones
foreach ($dnsZone in $dnsZones) {
    $dnsRecords = Get-AzDnsRecordSet -Zone $dnsZone

    # Search for records with the keywords in their values
    $matchedRecords = $dnsRecords | Where-Object {
        $_.Records | Where-Object { $keywords -contains $_ }
    }

    if ($matchedRecords) {
        # Iterate over the matched records and add them to the output array
        $matchedRecords | ForEach-Object {
            $recordType = $_.RecordType

            # Map the record type to its string representation
            switch ($recordType) {
                "A" { $recordType = "A" }
                "AAAA" { $recordType = "AAAA" }
                "CNAME" { $recordType = "CNAME" }
                "MX" { $recordType = "MX" }
                "NS" { $recordType = "NS" }
                "PTR" { $recordType = "PTR" }
                "SOA" { $recordType = "SOA" }
                "SRV" { $recordType = "SRV" }
                "TXT" { $recordType = "TXT" }
                "CAA" { $recordType = "CAA" }
                default { $recordType = "" }
            }

            $record = [PSCustomObject]@{
                'Record Name' = $_.Name
                'Record Type' = $recordType
                'Record Value' = $_.Records -join ', '
                'DNS Zone' = $dnsZone.Name
            }
            $outputArray += $record
        }
    }
}

if ($outputArray) {
    # Export the matched DNS records to Excel
    $outputPath = "C:\Location\to\export\export.xlsx"
    $outputArray | Export-Excel -Path $outputPath -AutoSize -FreezeTopRow -AutoFilter
    Write-Output "Matched DNS records exported to: $outputPath"
} else {
    Write-Output "No DNS records matched the keywords in the specified resource group."
}

# Disconnect from Azure account
# Disconnect-AzAccount
