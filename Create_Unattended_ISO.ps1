Function Mount-StandardISO
{
    # Parameter help description
    Param(
    [Parameter(Mandatory=$false)]
    [string]$Image_Path,
    [string]$Temp_Folder
    )

    $Mountdrive = Mount-DiskImage -ImagePath $Image_Path -PassThru
    $driveLetter = ($Mountdrive | Get-Volume).DriveLetter
    
    if(!(Test-Path $Temp_Folder)) {
        New-Item -Path $Temp_Folder -ItemType Directory
    }

    Copy-Item -Path $driveLetter":\sources\install.wim" -Destination $Temp_Folder
    Dismount-DiskImage -ImagePath $Image_Path
    Write-Output "ISO mounting and file copy finished"
}

Function Modify_unattanded_File
{
    # Parameter help description
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$false)]
    [string]$Hostname,
    [string]$IP,
    [string]$Gateway,
    [string]$Subnet
    )
    
    Write-Output "modify Unattended.xml finished"
}

Function CreateISO 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$false)]
    [string]$ISO_Name
    )
    
    $Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
    Push-Location -Path $Path_to_Oscdimg
    .\oscdimg.exe -n -bC:\Temp\ISO\boot\etfsboot.com c:\Temp c:\Temp\$ISO_Name -o -m
    Pop-Location

    Write-Output "ISO building succesfull"
}

Function Cleanup 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$false)]
    [string]$Temp_Folder
    )

    Remove-Item -Path $Temp_Folder -Recurse -Force
    Write-Output "Cleanp finished"

}

#Fixed Vars
$Temp_Folder = "C:\Temp"
$Image_Path = "\\diskstation\software\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"

#Executing starts here
#Mouting ISO, copy files to temp
Mount-StandardISO -Image_Path $Image_Path -Temp_Folder $Temp_Folder

#Modify unattended.xml
Modify_unattanded_File -Hostname "SigiServer_1"

#Create Boot ISO combined with unattendend.xml
CreateISO -ISO_Name "Windows_Server_2016_Datacenter"

#Delete temp folders and files
Cleanup -Temp_Folder $Temp_Folder