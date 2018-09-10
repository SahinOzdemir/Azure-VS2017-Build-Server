# Azure-VS2017-Build-Server

This ARM template enables you to quickly create and roll out a build server with VS 2017 and additional installs needed for the build server.

What the scripts do is:
1) Start off with creating a storage account and a blob container for files and scripts that are needed to create the build server with VM custom script extensions (CreatePrepareBlob-Build-Server.ps1)
- The script creates the storage account and then it will create the blob container
- The script uploads a zip file (installs.zip) with all installables (customizeable of course) to the blob container
- The script will also upload some powershell modules that will be fired during the custom script extensions stage of the VM creation.

In order for the script to work properly, the CreatePrepareBlob-Build-Server.ps1 file and the CreatePrepareBlob-Build-Server-parameters.json files need to be adjusted to reflect the values for the params. 

Also the "scripts" folder in the root should contain an "Installs.zip" file with all executables that need to be installed on the server. A working example is included that installs SSDT, ADF, AAS client libraries Azure DL tools, Azure functions and webjob tools, and .net Core 2.1.

The Powershell will return the storage account key, which is needed as a parameter in step 2 (creation of the Build Server VM) 


2) After files are uploaded the Build-Server-deploy.ps1 can be used to create the build server.
- Create the VM that contains Visual Studio 2017 and the VSTS build agents and configure all VM properties.
- Create and mount a 1 TB data disk (F drive). This drive will be used for the VSTS builds, releases, agent directories, etc.
- Download the Installs.zip file (containng all installers for build server) from the Blob to the local VM and extract its contents.       Currently the InstallAdditionalExecutables.ps1 will install:
	- SQL Server Data Tools
	- Install Azure Data factory
	- Azure Analysis Services client libraries
	- SQL Server 2017 Features pack
	- Microsoft Azure DataLake Tools VisualStudio Extension
	- Azure Functions And WebJob Tools
	- .NET Core 2.1.300
  You can add installers or remove any of the above list by editing the InstallAdditionalExecutables.ps1 and including/excluding them     from the zip file.
- The script will try to update Visual Studio 2017 and then apply the license key to VS 2017 to activate it.
- It will then continue to download the VSTS agent package and extract + install it to the F drive and bring the agents online based on the VSTS settings provided.
- It will install and configure RD Gateway and configure the Azure part for the Build Server VM. 
  The script will generate a certificate on the F drive of the server which need to be imported to the Trusted Root Certification         Authorities (certmgr.msc) and MSTSC must be configured for RD Gateway.

In order for the build server script to work properly, the Build-Server-deploy.ps1 file and the Build-Server-parameters.json files need to be adjusted to reflect the values for the params. 


##########
ADDITIONAL
##########

The Build server folder contains the following files and folders.
1.	Installs folder. This folder contains all additional .msi, .exe, etc. files that need to be installed on the server.
2.	Scripts. This folder contains PowerShell scripts and a zip file of the Installs folder. These are the files that will be uploaded to a storage account and consumed from the build server custom script extensions.
3.	The files in the root folder. The Build-Server-xxxxx.xxx files are the files that create the virtual machine. It has a PowerShell script that is used to do the deployment of both the ARM template and its parameters. The same applies for the Blob that is needed to download data from the custom script extension on the VM. CreatePrepareBlob-Build-Server-xxxxx.xxx are the same type of files, but for the blob.

############
PREPARATIONS
############

To execute the scripts that are included in this solution, some things need to be arranged.

First, make sure the Azure PowerShell tools have been installed on the machine that will run the scripts. For details on installing Azure PowerShell, please follow the instructions on the following link:
https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-6.2.0

##################
CREATE A PAT TOKEN
##################

Additional info on how to create a VSTS PAT token can be found here:
https://docs.microsoft.com/en-us/vsts/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts


####################
CONFIGURE RD GATEWAY
####################

GET SERVER CERTIFICATE AND INSTALL LOCALLY

After the installation and configuration of the Build Server, some steps are needed for RDGateway. RDGateway to make sure that only administrators can access the Build server physically without needing to allow access on port 3389.
To be able to access the server through RDP, we will need the certificate that has been created on the server and install it on our local machine.
1.	Login to the server via normal RDP connection. This can be done through the Azure portal, navigating to the VM and click the connect button at top of the overview page.
2.	When on the Build Server, go to the F:\RDGateWayCert folder. This will contain a certificate file. 
3.	Copy the file to your local machine.
4.	Right click on the file ‘*.cer’ and select ‘Install Certificate’
5.	In the Certificate Import Wizard, Select the following Store Location: ‘Current User’ - ‘Click on ‘Next’
6.	In the next window select ‘Place all certificates in the following store’ and click on ‘Browse’. In the window ‘Select 			Certificate Store’ please select the following ‘Trusted Root Certification Authorities’ and click on ‘OK’. 
	Click on ‘Next’.
7.	Click on ‘Finish’.
8.	The import was successful. Click on ‘OK’

DISABLE PORT 3389

When the certificate import on a local machine step is successfully done, the 3389 port of the virtual machine must be disabled.
This can be done with script “DisableRdpPortBuildServer.ps1” that resides in the Build Server Deploy folder.

1.	Start off with editing the script, by opening it in notepad or PowerShell ISE.
2.	Validate that the contents of the parameters at top of the file are correct.
- $subscriptionId is the ID of the azure subscription that contains the Build Server VM
- $resourceGroupName is the resource group of the VM. If the parameters in the deployment are used.
- $resourceGroupLocation. The location of the resource group and the build server.
- $nsgName is the network security group name of the build server. Can be found in the resource group for the build server.
- $ruleName is the name of the rule in the network security group that allows connections on the RDP/3389 port. The deployment             default it “default-allow-rdp”
3.	When the configuration has been done, the PowerShell script can be executed. It will prompt a login to Azure and then change the rule.

CONFIGURE THE LOCAL RDP CLIENT

1.	Open the RDP client (type MSTSC in windows search) And click on Show Options.
2.	Click on the tab Advanced and then click on the button Settings in the Connect from anywhere section.
3.	Set the checkbox to Use these RD Gateway server settings: and fill in the DNS name of the remote RDgateway server in the Server name textbox. Uncheck the box of Bypass RD Gateway server for local addresses
Check the box Use the RD Gateway credentials for the remote computer and click on OK.
4.	Go back to the general tab and fill in the Computer name of the computer you want to connect to. Type in the local administrator username. Click on Save as… to save this configuration as a RDP file. Click on connect to start the RDP session of the remote server.
