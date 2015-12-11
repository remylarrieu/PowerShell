#requires -version 4.0
#requires –runasadministrator
<#
.SYNOPSYS
    This script push update on a sysprep virtual hard disk
.VERSION
    0.1: Initial version
.AUTHOR
    Remy Larrieu
    Blog: www.remylarrieu.com
    Twitter: @RemyLarrieu
.PARAMETERS
    VHDPath: Specify the path where the sysprep VHD is stored
    UpdatePath: Specify the updates folder
    TempPath : Specify the temp folder
.EXAMPLE
    Update-SysprepVHD -VHDPath "C:\VMTemplate\VHD\" `
                -UpdatePath "C:\Updates\" `
                -TempPath "C:\Temp\" `
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$VHDPath,
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$UpdatePath,
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$TempPath
 )

$ErrorActionPreference = "Stop"

$VHDs = Get-ChildItem -Path $VHDPath -Include *.vhd,*.vhdx -Recurse -Force | Select-Object -Property FullName
$Updates = Get-ChildItem -Path $UpdatePath -Include *.msu,*.cab -Recurse -Force | Select-Object -Property FullName
 
ForEach($VHD in $VHDs) 
{   
    Write-Output "INFO : Mounting VHD"
    $MountedVHD = [string](Mount-VHD -Path $VHD.FullName -Passthru | Get-Disk | Get-Partition | Get-Volume | Where-Object -Property FileSystemLabel -NE "System Reserved").DriveLetter + ":\"
    $MountedVHD = $MountedVHD.Substring($MountedVHD.Length-3,3)          
    
    If ( Test-Path $MountedVHD$OS )         
    {         
        ForEach($Update in $Updates)         
        {
            Write-Output "INFO: Applying Update: " $Update.FullName          
            Add-WindowsPackage -Path $MountedVHD -PackagePath $Update.FullName -ScratchDirectory $TempPath
        }
    }
    
    Write-Output "INFO : Dismounting VHD"      
    Dismount-VHD -Path $VHD.FullName
}

Write-Output "INFO : VHD successfully updated"