# Downloads the Visual Studio Team Services Build Agent and installs on the new machine
# and registers with the Visual Studio Team Services account and build agent pool

# Enable -Verbose option
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]$VSTSAccount,
[Parameter(Mandatory=$true)]$PersonalAccessToken,
[Parameter(Mandatory=$true)]$AgentName,
[Parameter(Mandatory=$true)]$NumberOfAgents,
[Parameter(Mandatory=$true)]$PoolName,
[Parameter(Mandatory=$true)]$runAsAutoLogon,
[Parameter(Mandatory=$true)]$username,
[Parameter(Mandatory=$true)]$password,
[Parameter(Mandatory=$true)]$visualStudioLicenseKey,
[Parameter(Mandatory=$true)]$storageAccountName,
[Parameter(Mandatory=$true)]$storageAccountKey,
[Parameter(Mandatory=$true)]$storageAccountContainerName,
[Parameter(Mandatory=$true)]$vmRegion,
[Parameter(Mandatory=$true)]$dnsName

)

# Init and format data drive
Write-Verbose "Start processing Data Disk components" -verbose
Invoke-Expression ./InitializeDataDisk.ps1
Write-Verbose "Completed processing Data Disk components" -Verbose

Write-Verbose "Start installing additional executables" -verbose
#Install all external installers that are needed for the Build Server and update visual studio to its latest version
$args = @()
$args += ("-vsLicenseKey", $visualStudioLicenseKey)
$args += ("-storageAccountName", $storageAccountName)
$args += ("-storageAccountKey", $storageAccountKey)
$args += ("-storageAccountContainerName", $storageAccountContainerName)

Invoke-Expression "./InstallAdditionalExecutables.ps1 $args"

# Install VSTS Agents
Write-Verbose "Start installing VSTS Agents" -verbose
$args = @()
$args += ("-VSTSAccount", $VSTSAccount)
$args += ("-PersonalAccessToken", $PersonalAccessToken)
$args += ("-AgentName", $AgentName)
$args += ("-NumberOfAgents", $NumberOfAgents)
$args += ("-PoolName", $PoolName)
$args += ("-runAsAutoLogon", $runAsAutoLogon)
$args += ("-username", $username)
$args += ("-password", $password)

Invoke-Expression "./InstallVstsAgents.ps1 $args"

Write-Verbose "Completed installing VSTS Agents" -verbose

# Install VSTS Agents
Write-Verbose "Start install RDGateway" -verbose
$args = @()
$args += ("-vmRegion", $vmRegion)
$args += ("-dns", $dnsName)

Invoke-Expression "./InstallRDGateway.ps1 $args"

#Write-Verbose "Completed install RDGateway" -verbose
