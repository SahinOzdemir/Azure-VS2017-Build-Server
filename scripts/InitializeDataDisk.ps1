# The disk is present, so mount it
Get-Disk | where-object partitionstyle -eq 'RAW' |
Initialize-Disk -PartitionStyle GPT -PassThru |
New-Partition -DriveLetter F -UseMaximumSize |
Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false

#Initialize-Disk -Number $disk.Number -PartitionStyle GPT -confirm:$false  
#New-Partition -DiskNumber $disk.Number -UseMaximumSize -IsActive | 
#Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data Disk" -confirm:$false  
#Set-Partition -DiskNumber $disk.Number -PartitionNumber 1 -NewDriveLetter F 
#Format-Volume -DriveLetter F 
Write-Host "Mounting of disk F completed."