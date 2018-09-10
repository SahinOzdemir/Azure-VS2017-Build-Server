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
 $subscriptionId = '[NAME OF THE SUBSCRIPTION THAT WILL HOST THE STORAGE ACOUNT]',

 #[Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName = '[RESOURCE GROUP NAME FOR THE STORAGE ACCOUNT]',

 [string]
 $resourceGroupLocation = '[REGION OF THE STORAGE ACCOUNT]',

 #[Parameter(Mandatory=$True)]
 [string]
 $deploymentName = 'Blob Storage Build Server Install Scripts',

 [string]
 $templateFilePath = "CreatePrepareBlob-Build-Server-template.json",

 [string]
 $parametersFilePath = "CreatePrepareBlob-Build-Server-parameters.json",

 [string]
 $storageAccountName = "[STORAGE ACCOUNT NAME]",

 [string]
 $containerName = "[CONTAINER NAME]"
 
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

Write-Host "Deployment completed"

$storageAccount = Get-AzureRMStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
$ctx = $storageAccount.Context

#create the container
try 
{
    Write-Host "Creating container"
    New-AzureStorageContainer -Name $containerName -Context $ctx -Permission Off
    Write-Host "Finished creating container"
}
catch 
{
    Write-Host "Error creating container"
    Write-Error $_
}

#upload install files to blob
try 
{
    Write-Host "Upload build server installation files"
    $ProcessCustomActions = "ProcessCustomActions.ps1"
    $InitializeDataDisk = "InitializeDataDisk.ps1"
    $InstallAdditionalExecutables = "InstallAdditionalExecutables.ps1"
    $InstallVstsAgents = "InstallVstsAgents.ps1"
    $InstallRDGateway = "InstallRDGateway.ps1"
    $Installs = "Installs.zip"

    $scriptPath = Join-Path $PSScriptRoot "$containerName\"
    Set-AzureStorageBlobContent -File "$scriptPath$ProcessCustomActions" -Container $containerName -Blob $ProcessCustomActions -Context $ctx 
    Set-AzureStorageBlobContent -File "$scriptPath$InitializeDataDisk" -Container $containerName -Blob $InitializeDataDisk -Context $ctx 
    Set-AzureStorageBlobContent -File "$scriptPath$InstallAdditionalExecutables" -Container $containerName -Blob $InstallAdditionalExecutables -Context $ctx 
    Set-AzureStorageBlobContent -File "$scriptPath$InstallVstsAgents" -Container $containerName -Blob $InstallVstsAgents -Context $ctx 
    Set-AzureStorageBlobContent -File "$scriptPath$InstallRDGateway" -Container $containerName -Blob $InstallRDGateway -Context $ctx 
    Set-AzureStorageBlobContent -File "$scriptPath$Installs" -Container $containerName -Blob $Installs -Context $ctx 
    
    Write-Host "Completed upload build server installation files"
}
catch 
{
    Write-Host "Error uploading build server installation files"
    Write-Error $_
}

Write-Host "Finished deploying installation blob"

$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]

Write-Host "This is the Storage Account Key needed for the build server deploy: $StorageAccountKey"