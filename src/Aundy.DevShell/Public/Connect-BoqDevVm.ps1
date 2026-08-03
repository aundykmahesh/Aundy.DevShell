function Connect-BoqDevVm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$name = 'npedcT2paw257',

        [Parameter(Mandatory = $false)]
        [string]$resourceGroupName = 'NP-EDC-PAWT2-RG01',
        
        [Parameter(Mandatory = $false)]
        [string]$subscription = '43a448ab-c2b2-4fc8-9c27-ed4e9fd05a79',

        [Parameter(Mandatory = $false)]
        [string]$bastionName = 'np-edc-hub-vnet01-bastion'
    )

    process {
        az login

        az account set --subscription $subscription

        $resourceId = "/subscriptions/$subscription/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$name/overview"
        az network bastion rdp --name "$bastionName" --resource-group "$resourceGroupName" --target-resource-id "$resourceId"
    }
}
