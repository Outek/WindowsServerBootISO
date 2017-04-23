$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

#Fixed Vars
#Folders for the temp files
$Temp_Folder_WIM = "C:\Temp\WIM"
$Temp_Folder_Data = "C:\Temp\ISO"

#path to the image
$Image_Path = "\\diskstation\software\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"

#Path to the prepared autoattend.xml
$autounattend_File_Path = "C:\Temp\Answer_File\autounattend.xml"

#Servername
$Servername = "Testserver"

#Networking
$IP = "192.168.0.155"
$Gateway = "192.168.0.1"
$Subnet = "255.255.255.0"

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
    try 
    {
        Copy-Item -Path $driveLetter":\sources\install.wim" -Destination $Temp_Folder_WIM -Verbose
    }
    catch 
    {
        Write-Debug "Copy install.wim failed"
        Exit 1
    }
    
        if (!(Test-Path $Temp_Folder_Data)) 
        {
            New-Item -Path $Temp_Folder_Data -ItemType Directory
        }
    
    try 
    {
       Copy-Item -Path $driveLetter":\*" -Destination $Temp_Folder_Data -Recurse -Force -Verbose 
    }
    catch 
    {
        Write-Debug "Copy of data failed"
        Exit 1
    }    

    Remove-Item -Path $Temp_Folder_Data\NanoServer -Recurse -Force

    Dismount-DiskImage -ImagePath $Image_Path
    Write-Debug "ISO mounting and file copy finished"
}

Function Modify_autounattend_File 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [string]$IP,
        [string]$Gateway,
        [string]$Subnet,
        [string]$File_Path,
        [string]$Temp_Folder_Data
    )
    
    Copy-item -Path $autounattend_File_Path -Destination $Temp_Folder_Data

    $ValuesfromFile = Get-Content "$Temp_Folder_Data\autounattend.xml"

        try 
        {
            $ValuesfromFile.Replace("%COMPUTERNAME%", $Hostname) | Set-Content "$Temp_Folder_Data\autounattend.xml"
            Write-Debug "modify autounattend.xml succesfull"
        }
        catch 
        {
            Write-Debug "modify autounattend.xml failed"
            Exit 1
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
            Exit 1
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
    #.\oscdimg.exe -bC:\Temp\ISO\boot\etfsboot.com -u2 -h -m -lWIN_SERVER_2016 C:\Temp\ISO C:\Temp\$ISO_Name
    .\oscdimg.exe -bC:\Temp\ISO\efi\microsoft\boot\efisys_noprompt.bin -u2 -h -m -lWIN_SERVER_2016 C:\Temp\ISO C:\Temp\$ISO_Name
    
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
Modify_autounattend_File -Hostname $Servername -File_Path $autounattend_File_Path -Temp_Folder_Data $Temp_Folder_Data -IP $IP -Gateway $Gateway -Subnet $Subnet

#Copy install.wim to ISO directory
Copy-InstallWIM -Temp_Folder_WIM $Temp_Folder_WIM -Temp_Folder_Data $Temp_Folder_Data

#Create Boot ISO combined with unattendend.xml
CreateISO -ISO_Name "Windows_Server_2016_Datacenter_$Servername.iso"

#Delete temp folders and files
Cleanup -Temp_Folder_Data $Temp_Folder_Data

#Measure runtime
$Runtime = $StopWatch.Elapsed.TotalSeconds
Write-Debug "Total runtime in seconds: $Runtime"