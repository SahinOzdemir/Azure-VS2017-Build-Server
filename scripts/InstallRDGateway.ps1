<#
.DESCRIPTION
        Uses the Remote Desktop Services PowerShell provider to create/install an RD-CAP and an RD-RAP. Also creates and exports a self-signed certificate for use on connecting clients
    
    .PARAMETER dnsName
        FQDN of the to-be-generated self-signed certificate
    
    .OUTPUTS
        Self-signed cert at $HOME/desktop/$dnsName.cert 

    .NOTES
        Remote Desktop Service role will be installed on the server where this script is executed.
        This script adds the local administrators group to RD-CAP and permits all accesses to back-end resources

    .SOURCE  
        Alex Neihaus 2017-07-25
        Author's blog: https://www.yobyot.com
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]$vmRegion,
    [Parameter(Mandatory=$true)]$dns
)

$installFileDir = "F:\RDGateWayCert"

#Create directory on F drive 
Try
{
    Write-Verbose "Start creation of software directory." -verbose
    New-Item -ItemType directory -Path $installFileDir -Force
    Write-Verbose "Finished creation of software directory." -verbose
}
Catch
{
    Write-Verbose "Error creation of software directory." -verbose
    Write-Error $_
}

# Install the RD-Gateway Role service
Add-WindowsFeature –Name RDS-Gateway –IncludeAllSubFeature

# Import RDS module to configure the RD-Gateway Role
Import-Module RemoteDesktopServices

# Create a self-signed certificate. This MUST be installed in the client's Trusted Root store for RDP clients to be able to use it
$dnsName = "$dns.$vmRegion.cloudapp.azure.com"
$x509Obj = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $dnsName

# Export the cert to the administrator's desktop for use on clients
$x509Obj | Export-Certificate -FilePath "$installFileDir\$dnsName.cer" -Force -Type CERT

# Create RD-CAP with a single user group; defaults permit all device redirection.
$capName = "RD-CAP-$(Get-Date -Format FileDateTimeUniversal)"
Set-Location RDS:\GatewayServer\SSLCertificate #Change to location where self-signed certificate is specified
Set-Item .\Thumbprint -Value $x509obj.Thumbprint # Update RDG with the thumprint of the self-signed cert.

# Create a new Connection Authorization Profile
New-Item -Path RDS:\GatewayServer\CAP -Name $capName -UserGroups @("administrators@BUILTIN") -AuthMethod 1

# Create a new Resouce Authorization Profile with "ComputerGroupType" set to 2 to permit connections to any device
$rapName = "RD-RAP-$(Get-Date -Format FileDateTimeUniversal)"
New-Item -Path RDS:\GatewayServer\RAP -Name $rapName -UserGroups @("administrators@BUILTIN") -ComputerGroupType 2
Restart-Service TSGateway