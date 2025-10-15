# Valid Region Names for Windows 365 Cloud PC

When using the `-RegionName` parameter with `New-LabCloudPCPolicy`, you must use **Azure region names** (not Windows 365-style region identifiers).

## Valid Azure Region Names

The API expects standard Azure region names in lowercase:

### Americas
- `eastus` - East US (default in module)
- `eastus2` - East US 2
- `westus` - West US
- `westus2` - West US 2
- `westus3` - West US 3
- `centralus` - Central US
- `southcentralus` - South Central US
- `northcentralus` - North Central US
- `westcentralus` - West Central US
- `canadacentral` - Canada Central
- `canadaeast` - Canada East
- `brazilsouth` - Brazil South

### Europe
- `northeurope` - North Europe (Ireland)
- `westeurope` - West Europe (Netherlands)
- `uksouth` - UK South
- `ukwest` - UK West
- `francecentral` - France Central
- `francesouth` - France South
- `germanywestcentral` - Germany West Central
- `germanynorth` - Germany North
- `norwayeast` - Norway East
- `norwaywest` - Norway West
- `switzerlandnorth` - Switzerland North
- `switzerlandwest` - Switzerland West
- `swedencentral` - Sweden Central

### Asia Pacific
- `southeastasia` - Southeast Asia (Singapore)
- `eastasia` - East Asia (Hong Kong)
- `australiaeast` - Australia East
- `australiasoutheast` - Australia Southeast
- `australiacentral` - Australia Central
- `japaneast` - Japan East
- `japanwest` - Japan West
- `koreacentral` - Korea Central
- `koreasouth` - Korea South
- `centralindia` - Central India
- `southindia` - South India
- `westindia` - West India

### Middle East & Africa
- `uaenorth` - UAE North
- `uaecentral` - UAE Central
- `southafricanorth` - South Africa North
- `southafricawest` - South Africa West

## Usage Examples

### Default (East US)
```powershell
New-LabCloudPCPolicy -PolicyName "My Policy"
# Uses default region: eastus
```

### Specific Region
```powershell
# Europe
New-LabCloudPCPolicy -PolicyName "EU Policy" -RegionName "westeurope"

# Asia Pacific
New-LabCloudPCPolicy -PolicyName "APAC Policy" -RegionName "southeastasia"

# US West Coast
New-LabCloudPCPolicy -PolicyName "West Coast Policy" -RegionName "westus2"

# UK
New-LabCloudPCPolicy -PolicyName "UK Policy" -RegionName "uksouth"
```

### With Azure Network Connection
```powershell
# When using Azure network connection, RegionName is ignored
$connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
New-LabCloudPCPolicy -PolicyName "Azure Network Policy" -OnPremisesConnectionId $connection.Id
```

## Important Notes

1. **Use Azure region names** - e.g., "eastus", not "usEast" or "East US"
2. **Lowercase** - Region names should be all lowercase (e.g., `eastus`, not `EastUS`)
3. **No spaces** - Use the Azure region identifier format (e.g., `westeurope`, not `west europe`)
4. **Azure network takes precedence** - If you specify `-OnPremisesConnectionId`, the `-RegionName` parameter is ignored
5. **Performance** - Choose a region closest to your users for best performance

## Troubleshooting

If you get "parameterValidationFailed" error:
1. Ensure you're using Azure region names in lowercase (e.g., "eastus")
2. Check for typos in the region name
3. Don't use "automatic" - specify an actual region
4. Make sure the region supports Windows 365 Cloud PC

## Getting List of Azure Regions

You can list all Azure regions using Azure CLI or PowerShell:

```powershell
# Using Azure PowerShell
Get-AzLocation | Select-Object Location, DisplayName | Sort-Object Location

# Using Azure CLI
az account list-locations --query "[].name" -o table
```

However, not all Azure regions may support Windows 365. Use the list above for known supported regions.
