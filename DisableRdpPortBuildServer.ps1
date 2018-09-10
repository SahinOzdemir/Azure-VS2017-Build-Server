$subscriptionId = "[SUBSCRIPTION ID]"
$resourceGroupName = "[RESOURCE GROUP NAME OF WHE RESOURCE GROUP FOR THE BUILD SERVER]"
$nsgName = "[BUILD SERVER NDG NAME - SEE BUILD SERVER PARAMS FILE]"
$ruleName = "default-allow-rdp"

#*************************************************.\dis *****************************
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


$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName
$nsg | Get-AzureRmNetworkSecurityRuleConfig -Name $ruleName 
Set-AzureRmNetworkSecurityRuleConfig -Name $ruleName -NetworkSecurityGroup $nsg -Access "Deny" -Protocol "Tcp" -Direction Inbound -SourcePortRange "*" -SourceAddressPrefix "*" -DestinationPortRange 3389 -DestinationAddressPrefix "*" -Priority 1000
$nsg | Set-AzureRmNetworkSecurityGroup