# Enable -Verbose option
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]$vsLicenseKey,
[Parameter(Mandatory=$true)]$storageAccountName,
[Parameter(Mandatory=$true)]$storageAccountKey,
[Parameter(Mandatory=$true)]$storageAccountContainerName
)

$outputFile = "F:\Temp\Installs.zip"
$installFileDir = "F:\Temp"
$FullPath = "F:\Temp\Installs"
$vsInstallerLocation = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
$vsInstallPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise"
$vsStorePid = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\StorePID.exe"
$vsixInstallerPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\VSIXInstaller.exe"

$FileName = "Installs.zip"

#Functions

Function CreateDirectory
{   Try
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
}

Function DownloadFromBlob
{
    try 
    {
        Write-Verbose "Start download of installs package." -verbose

        $start_time = Get-Date
        #Invoke-WebRequest -Uri $url -OutFile $outputFile
        $connectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccountKey;EndpointSuffix=core.windows.net"
        # Download via Azure PowerShell
        $StorageContext = New-AzureStorageContext -ConnectionString $connectionString 
        Get-AzureStorageBlobContent -Blob $FileName -Container $storageAccountContainerName -Destination $installFileDir -Context $StorageContext

        Write-Verbose "Start download of installs package. Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)" -verbose
    }
    catch 
    {
        Write-Verbose "Error download of installs package." -verbose
        Write-Error $_
    }
}

Function ExtractZipFile
{
    try
    {
        Write-Verbose "Start extract software archive." -verbose
        Expand-Archive $outputFile -DestinationPath $installFileDir
        Write-Verbose "Completed extract software archive." -verbose
    }
    catch
    {
        Write-Verbose "Error during extract software archive." -verbose
        Write-Error $_
    }
}

Function InstallSSDT
{
    Try 
    {
        Write-Verbose "Start installing SSDT" -verbose
        $installerCmd = Join-Path $FullPath "SSDT\SSDT-Setup-ENU.exe"

        $argList = "/install INSTALLALL /norestart /passive /quit"
        Start-Process -FilePath "$installerCmd" -ArgumentList "$argList" -Wait

        Write-Verbose "Finished installing SSDT" -verbose
    }
    Catch 
    {
        Write-Verbose "Error installing SSDT" -verbose
        Write-Error $_
    }
    
}

Function InstallAzureDataFactory
{
    Try 
    {
        # DOES NOT INSTALL FOR SOME REASON ON VS 2017 - NOT SUPPORTED?
        Write-Verbose "Start installing Azure Data Factory" -verbose
        $installerCmd = Join-Path $FullPath "AzureDataFactory\AzureDataFactoryVisualStudioTools.vsix"
        $argList = "/q $installerCmd"
        
        Start-Process -FilePath $vsixInstallerPath -ArgumentList "$argList" -Wait
        
        Write-Verbose "Finished installing Azure Data Factory" -verbose
    }
    Catch 
    {
        Write-Verbose "Error installing Azure Data Factory" -verbose
        Write-Error $_
    }
}

Function InstallClientLibraryAzureAnalysisServices
{
    Write-Verbose "Start installing Azure Analysis Services client libraries" -verbose
    $argList = "/quiet /norestart"
    
    Try 
    {
        Write-Verbose "...x64_15.0.600.141 .01_SQL_AS_ADOMD.msi" -verbose
        $installerAdoMD = Join-Path $FullPath "ClientLibraryAzureAnalysisServices\x64_15.0.600.141 .01_SQL_AS_ADOMD.msi"
        Start-Process -FilePath "$installerAdoMD" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error x64_15.0.600.141 .01_SQL_AS_ADOMD.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...x64_15.0.600.141 .01_SQL_AS_AMO.msi" -verbose
        $installerAmo = Join-Path $FullPath "ClientLibraryAzureAnalysisServices\x64_15.0.600.141 .01_SQL_AS_AMO.msi"
        Start-Process -FilePath "$installerAmo" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error x64_15.0.600.141 .01_SQL_AS_AMO.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...x64_15.0.600.141 .01_SQL_AS_OLEDB.msi" -verbose
        $installerOleDB = Join-Path $FullPath "ClientLibraryAzureAnalysisServices\x64_15.0.600.141 .01_SQL_AS_OLEDB.msi"
        Start-Process -FilePath "$installerOleDB" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error 64_15.0.600.141 .01_SQL_AS_OLEDB.msi" -verbose
        Write-Error $_
    }
    
    Write-Verbose "Finished installing Azure Analysis Services client libraries" -verbose
}

Function InstallSQLServer2017FeaturesPack
{
    Write-Verbose "Start installing SQl Server 2017 Features pack" -verbose
    $argList = "/quiet /norestart"

    Try 
    {
        Write-Verbose "...MasterDataServicesExcelAddin.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\MasterDataServicesExcelAddin.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error MasterDataServicesExcelAddin.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...AttunityOracleCdcService.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\AttunityOracleCdcService.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error AttunityOracleCdcService.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...AttunityOracleCdcDesigner.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\AttunityOracleCdcDesigner.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error AttunityOracleCdcDesigner.msi" -verbose
        Write-Error $_
    }
    
    Try 
    {
        Write-Verbose "...ReportBuilder3.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\ReportBuilder3.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error ReportBuilder3.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...SapBI.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\SapBI.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error SapBI.msi" -verbose
        Write-Error $_
    }

    $adjustedArgs = "/auto ""C:\Program Files\Microsoft JDBC DRIVER 6.2 for SQL Server"""
    Try 
    {
        Write-Verbose "...sqljdbc_6.2.2.1_enu.exe" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\sqljdbc_6.2.2.1_enu.exe"
        Start-Process -FilePath "$installer" -ArgumentList "$adjustedArgs" -Wait
    }
    Catch
    {
        Write-Verbose "Error sqljdbc_6.2.2.1_enu.msi" -verbose
        Write-Error $_
    }
    
    Try 
    {
        Write-Verbose "...msodbcsql.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\msodbcsql.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error msodbcsql.msi" -verbose
        Write-Error $_
    }
    
    Try 
    {
        Write-Verbose "...SemanticLanguageDatabase.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\SemanticLanguageDatabase.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error SemanticLanguageDatabase.msi" -verbose
        Write-Error $_
    }
    
    Try 
    {
        Write-Verbose "...DacFramework.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\DacFramework.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error DacFramework.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...SQLSysClrTypes.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\SQLSysClrTypes.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error SQLSysClrTypes.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...tsqllanguageservice.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\tsqllanguageservice.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error tsqllanguageservice.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...RBS.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\RBS.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error RBS.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...SSBEAS.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\SSBEAS.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error SSBEAS.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...SsisAzureFeaturePack_2017_x64.msi" -verbose
        $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\SsisAzureFeaturePack_2017_x64.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error SsisAzureFeaturePack_2017_x64.msi" -verbose
        Write-Error $_
    }

    Try 
    {
        Write-Verbose "...DB2OLEDBV6_x64.msi" -verbose
    $installer = Join-Path $FullPath "SQLServer2017FeaturesPack\DB2OLEDBV6_x64.msi"
    Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error DB2OLEDBV6_x64.msi" -verbose
        Write-Error $_
    }

    Write-Verbose "Finished installing SQl Server 2017 Features pack" -verbose
}

Function InstallAzureDataLakeAndStreamAnalyticsTools
{
    Try 
    {
        Write-Verbose "Start installing Microsoft Azure DataLake Tools VisualStudio Extension" -verbose
        $installerCmd = Join-Path $FullPath "AzureDataLakeAndStreamAnalyticsTools\Microsoft.Azure.DataLake.Tools.VisualStudio.Extension.vsix"
        $argList = "/q $installerCmd"
        
        Start-Process -FilePath $vsixInstallerPath -ArgumentList "$argList" -Wait
        
        Write-Verbose "Finished installing Microsoft Azure DataLake Tools VisualStudio Extension" -verbose
    }
    Catch 
    {
        Write-Verbose "Error installing Microsoft Azure DataLake Tools VisualStudio Extension" -verbose
        Write-Error $_
    }

    Write-Verbose "Start installing Microsoft Azure DataLake And StreamAnalytics Tools For VS2015" -verbose
    $argList = "/quiet /norestart"

    Try 
    {
        Write-Verbose "...Microsoft.Azure.DataLakeAndStreamAnalyticsToolsForVS2015.msi" -verbose
        $installer = Join-Path $FullPath "AzureDataLakeAndStreamAnalyticsTools\Microsoft.Azure.DataLakeAndStreamAnalyticsToolsForVS2015.msi"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait
    }
    Catch
    {
        Write-Verbose "Error Microsoft.Azure.DataLakeAndStreamAnalyticsToolsForVS2015.msi" -verbose
        Write-Error $_
    }
}

Function InstallAzureFunctionsAndWebJobTools
{
    Try 
    {
        Write-Verbose "Start installing Azure Functions And WebJob Tools" -verbose
        $installerCmd = Join-Path $FullPath "AzureFunctionsAndWebJobTools\Microsoft.VisualStudio.Web.AzureFunctions.vsix"
        $argList = "/q $installerCmd"
        
        Start-Process -FilePath $vsixInstallerPath -ArgumentList "$argList" -Wait
        
        Write-Verbose "Finished installing Azure Functions And WebJob Tools" -verbose
    }
    Catch 
    {
        Write-Verbose "Error installing Azure Functions And WebJob Tools" -verbose
        Write-Error $_
    }
}

Function InstallNetCore
{
    Write-Verbose "Start installing .NET Core 2.1" -verbose
    $argList = "/quiet /norestart"

    Try 
    {
        $installer = Join-Path $FullPath "NetCore\dotnet-sdk-2.1.300-win-x64.exe"
        Start-Process -FilePath "$installer" -ArgumentList "$argList" -Wait

        Write-Verbose "Finished installing .NET Core 2.1" -verbose

    }
    Catch
    {
        Write-Verbose "Error installing .NET Core 2.1" -verbose
        Write-Error $_
    }
}

Function UpdateVisualStudio
{
    Try 
    {
        Write-Verbose "Start updating Visual Studio" -verbose
        $argList = "--quiet --update --wait"
        Start-Process -FilePath $vsInstallerLocation -ArgumentList "$argList" -Wait

        $argList = "update --installPath $vsInstallPath --quiet --wait --norestart"
        Start-Process -FilePath $vsInstallerLocation -ArgumentList "$argList" -Wait

        Write-Verbose "Finished updating Visual Studio" -verbose
    }
    Catch
    {
        Write-Verbose "Error updating Visual Studio" -verbose
        Write-Error $_
    }
}

Function ConfigureVSLicense
{
    Try 
    {
        Write-Verbose "Adding Visual Studio License" -verbose
        Start-Process -FilePath $vsStorePid -ArgumentList "$vsLicenseKey 08860" -Wait
        Write-Verbose "Completed Visual Studio License" -verbose
    }
    Catch
    {
        Write-Verbose "Error Visual Studio License" -verbose
        Write-Error $_
    }
}

#First Update visual studio
ConfigureVSLicense
UpdateVisualStudio

#Download the zip file from Blob
CreateDirectory
DownloadFromBlob

#Extract the Zip file to drive
ExtractZipFile

#Install SSDT
InstallSSDT

#Install DataLake & stream anlytics
InstallAzureDataLakeAndStreamAnalyticsTools

#Install Azure functions and webjob tools
InstallAzureFunctionsAndWebJobTools

#Install AzureDataFactory
InstallAzureDataFactory

#Install ClientLibraryAzureAnalysisServices
InstallClientLibraryAzureAnalysisServices

#Install SQLServer2017FeaturesPack
InstallSQLServer2017FeaturesPack

#Install .NET Core 2.1
InstallNetCore



