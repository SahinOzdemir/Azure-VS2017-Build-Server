<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
 #[Parameter(Mandatory=$True)]
 [string]
 $subscriptionId = '[ID OF SUBSCRIPTION]',

 #[Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName = '[NAME OF RESOURCEGROUP THIS BUILD SERVER WILL BE DEPLOYED TO]',

 [string]
 $resourceGroupLocation = '[REGION OF THE BUILD SERVER]',

 #[Parameter(Mandatory=$True)]
 [string]
 $deploymentName = '[NAME OF THE DEPLOYMENT]',

 [string]
 $templateFilePath = "Build-Server-template.json",

 [string]
 $parametersFilePath = "Build-Server-parameters.json"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

#Verify azure login session
Try{
    $Context = Get-AzureRmContext -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($Context.Environment)) {
        throw "Run Login-AzureRmAccount to login.";
    }
}
Catch{
    $ContextErr = $Error[0]
    If($ContextErr -match "Run Login-AzureRmAccount to login."){
        Write-Output "No logon session to Azure Resource Manager found."
        Write-Output "Starting Azure Resource Manager login."
        Login-AzureRmAccount  
        
        # select subscription
        Write-Host "Selecting subscription '$subscriptionId'";
        Select-AzureRmSubscription -SubscriptionID $subscriptionId;
    }
    Else{
        Write-Output "Unknown error stopping script execution"
    }
}

############ Enable when deploying on subscription level with sufficient permissions. In case of RBAC, configure these resource providers manually ############
# Register RPs
#$resourceProviders = @("microsoft.compute","microsoft.storage","microsoft.network");
#if($resourceProviders.length) {
#    Write-Host "Registering resource providers"
#    foreach($resourceProvider in $resourceProviders) {
#        RegisterRP($resourceProvider);
#    }
#}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist."
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
} else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
}