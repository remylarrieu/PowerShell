#requires -version 4.0
#requires –runasadministrator
<#
.SYNOPSYS
    This script create new virtual machine based on a sysprep virtual hard disk
.VERSION
    0.1: Initial version
.AUTHOR
    Remy Larrieu
    Blog: www.remylarrieu.com
    Twitter: @RemyLarrieu
.PARAMETERS
    Name: Specify the VM name
    VHDPath: Specify the path of the sysprep VHD
    Destination: Specify the VM destination folder
    Generation : Specify the VM generation
    SwitchName: Specify the VM connected switch
    Memory: Specify the amount of startup memory of the VM
.EXAMPLE
    New-SysprepVM -VMName "VMTest"
                -VHDPath "C:\VMTemplate\VHD\" `
                -Destination "C:\Hyper-V\" `
                -SwitchName "External" `
                -Generation 2 `
                -Memory 2048MB
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$Name,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$VHDPath,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]$Destination,
    
    [ValidateSet(1,2)]
    [Int]$Generation = 1,
    
    [ValidateNotNullorEmpty()]
    [String]$SwitchName,

    [Int64]$Memory = 1024MB
 )

$ErrorActionPreference = "Stop"

Write-Output "INFO : Creating Virtual Machine"
New-VM -Name $Name -NoVHD -Path $Destination -Generation $Generation > $null
Set-VMMemory -VMName $Name -StartupBytes $Memory

if($SwitchName)
{
    Write-Output "INFO : Adding Switch"
    Add-VMNetworkAdapter -VMName $VMName -SwitchName $SwitchName
}

Write-Output "INFO : Creating VHD folder"
$VM_VHDFolder = "Virtual Hard Disks"
New-Item -ItemType Directory -Path "$Destination$Name" -Name $VM_VHDFolder > $null

Write-Output "INFO : Copying Sysprep VHD"
$SysprepVHD = Get-Childitem $VHDPath -Recurse -Include "*.vhd","*.vhdx"
Copy-Item -Path $SysprepVHD.FullName -Destination "$Destination$Name\$VM_VHDFolder"
$VHD = Get-Childitem "$Destination$Name\$VM_VHDFolder" -Recurse -Include "*.vhd","*.vhdx"
Rename-Item -Path "$Destination$Name\$VM_VHDFolder" -NewName "$VMName.vhdx"

Write-Output "Adding VHD to the VM"
Add-VMHardDiskDrive -VMName $Name -Path "$Destination$Name\$VM_VHDFolder"

Write-Output "INFO : Changing VM startup order"
if($Generation -eq 1)
{
    Set-VMBios -VMName $Name -StartupOrder @("IDE","CD","LegacyNetworkAdapter","Floppy")
}
else
{
    $HardDisk = (Get-VMFirmware $Name).BootOrder | Where-Object -Property Device -Like "*HardDiskDrive*"
    Set-VMFirmware -VMName $Name -FirstBootDevice $HardDisk
}

Write-Output "INFO : The VM was created successfully"