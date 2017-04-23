$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

#Fixed Vars
#Folders for the temp files
$Temp_Folder_WIM = "C:\Temp\WIM"
$Temp_Folder_Data = "C:\Temp\ISO"

#path to the image
$Image_Path = "\\diskstation\software\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"

#Path to the prepared autoattend.xml
$autounattended_File_Path = "C:\Temp\Answer_File\autounattend.xml"

#Debug messages on with "Continue"
$DebugPreference = "Continue"

Function Mount-StandardISO 
{
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Image_Path,
        [string]$Temp_Folder_WIM,
        [string]$Temp_Folder_Data
    )

    $Mountdrive = Mount-DiskImage -ImagePath $Image_Path -PassThru
    $driveLetter = ($Mountdrive | Get-Volume).DriveLetter
    Write-Debug "ISO mounted with driveletter $driveletter"
    
    if (!(Test-Path $Temp_Folder_WIM)) 
    {
        New-Item -Path $Temp_Folder_WIM -ItemType Directory
    }

    Copy-Item -Path $driveLetter":\sources\install.wim" -Destination $Temp_Folder_WIM -Verbose

    if (!(Test-Path $Temp_Folder_Data)) 
    {
        New-Item -Path $Temp_Folder_Data -ItemType Directory
    }

    Copy-Item -Path $driveLetter":\*" -Destination $Temp_Folder_Data -Recurse -Force -Verbose
    Remove-Item -Path $Temp_Folder_Data\NanoServer -Recurse -Force

    Dismount-DiskImage -ImagePath $Image_Path
    Write-Debug "ISO mounting and file copy finished"
}

Function Modify_autounattended_File 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [string]$File_Path,
        [string]$Temp_Folder_Data
    )
    
    Copy-item -Path $autounattended_File_Path -Destination $Temp_Folder_Data

    $ValuesfromFile = Get-Content "$Temp_Folder_Data\autounattend.xml"
    try 
    {
        $ValuesfromFile.Replace("%COMPUTERNAME%", $Hostname) | Set-Content "$Temp_Folder_Data\autounattend.xml"
        Write-Debug "modify autounattend.xml succesfull"
    }
    catch 
    {
        Write-Debug "modify autounattend.xml failed"
    }
}

Function Copy-InstallWIM
{
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Temp_Folder_WIM,
        [string]$Temp_Folder_Data
    )  
    try 
    {
        Copy-Item -Path $Temp_Folder_WIM -Destination $Temp_Folder_Data -Force
        write-debug "Copy of install.wim succesfull"      
    }
    catch 
    {
        write-debug "Copy of install.wim failed"
    }
}

Function CreateISO 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$ISO_Name
    )
    
    $Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
    Push-Location -Path $Path_to_Oscdimg
    .\oscdimg.exe -bC:\Temp\ISO\boot\etfsboot.com -u2 -h -m -lWIN_SERVER_2016 C:\Temp\ISO C:\Temp\$ISO_Name
    Pop-Location
    Write-Debug "ISO building succesfull"
}

Function Cleanup 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Temp_Folder_Data
    )

    Remove-Item -Path $Temp_Folder_Data -Recurse -Force
    Write-Debug "Cleanp finished"
}

#Executing starts here
#Mouting ISO, copy files to temp
Mount-StandardISO -Image_Path $Image_Path -Temp_Folder_Data $Temp_Folder_Data -Temp_Folder_WIM $Temp_Folder_WIM

#Modify unattended.xml
Modify_autounattended_File -Hostname "Testserver_1" -File_Path $autounattended_File_Path -Temp_Folder_Data $Temp_Folder_Data

#Copy install.wim to ISO directory
Copy-InstallWIM -Temp_Folder_WIM $Temp_Folder_WIM -Temp_Folder_Data $Temp_Folder_Data

#Create Boot ISO combined with unattendend.xml
CreateISO -ISO_Name "Windows_Server_2016_Datacenter.iso"

#Delete temp folders and files
Cleanup -Temp_Folder_Data $Temp_Folder_Data

#Stopping Runtime
$Runtime = $StopWatch.Elapsed.TotalSeconds
Write-Debug "Total runtime in seconds: $Runtime"