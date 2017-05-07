# -----------------------------------------
# Script: create_unattended_iso.ps1
# Author: Daniel Siegenthaler
# Date: 24.04.2017
# -----------------------------------------

[CmdletBinding()]
Param(
        [Parameter(Mandatory = $False)]
        [string]$Temp_Folder_WIM,

        [Parameter(Mandatory=$False)]
        [string]$Temp_Folder_Data,

        [Parameter(Mandatory=$False)]
        [string]$Image_Path,

        [Parameter(Mandatory=$False)]
        [string]$autounattend_File_Path,

        [Parameter(Mandatory=$true)]
        [string]$Servername,

        [Parameter(Mandatory=$true)]
        [string]$IP,

        [Parameter(Mandatory=$true)]
        [string]$Gateway,

        [Parameter(Mandatory=$true)]
        [string]$Subnet,

        [Parameter(Mandatory=$false)]
        [string]$Domain_Suffix,

        [Parameter(Mandatory=$true)]
        [string]$DNS,

        [Parameter(Mandatory=$false)]
        [string]$Path_to_Oscdimg,

        [Parameter(Mandatory=$False)]
        [ValidateSet('True','False')]
        [string]$DebugMode
    )

#Initialyze Stopwatch
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

#Fixed Vars
#Folders for the temp files
If($Temp_Folder_Data.Length -lt 1) 
{
    $Temp_Folder_Data = "C:\Temp\ISO"
}
If(!(Test-Path $Temp_Folder_Data))
{
    Write-Debug "Folder $Temp_Folder_Data not found"
}

If($Temp_Folder_WIM.Length -lt 1)
{
    $Temp_Folder_WIM = "C:\Temp\WIM"
}
If(!(Test-Path $Temp_Folder_WIM))
{
    Write-Debug "Folder $Temp_Folder_WIM not found"
    exit
}

#path to the image
If($Image_Path.Length -lt 1) 
{
    $Image_Path = "C:\Temp\Original_ISO\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"    
}
If(!(Test-Path $Image_Path))
{
    Write-Debug "Iso not found"
    Exit
}

#Path to the prepared autoattend.xml
If($autounattend_File_Path.Length -lt 1)
{
    $autounattend_File_Path = "..\Answer_File_staticIP_UEFI\autounattend.xml"
}
If(!(Test-Path $autounattend_File_Path))
{
    Write-Debug "Autounattend $autoattend_File_Path not found"
    Exit
}

#Servername
If($Servername.Length -lt 1)
{
    $Servername = "Testserver"
}

#Networking
If($IP.Length -lt 1) 
{
    $IP = "192.168.0.111"    
}

If($Gateway.Length -lt 1) 
{
    $Gateway = "192.168.0.1"
}

If($Subnet.Length -lt 1)
{
    $Subnet = "255.255.255.0"
}

If($Domain_Suffix.Length -lt 1)
{
    $Domain_Suffix = "domain.internal"
}
If($DNS.Length -lt 1) 
{
    $DNS = "192.168.0.1"
}
if($Path_to_Oscdimg.Length -lt 1)
{
    $Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
}
If(!(Test-Path $Path_to_Oscdimg))
{
    Write-Debug "Path to oscdimg not found"
    Exit
}

Write-Debug "Servername: $Servername"
Write-Debug "IP: $IP"
Write-Debug "DNS: $DNS"
Write-Debug "Subnet: $Subnet"
Write-Debug "Gateway: $Gateway"
Write-Debug "Domain_Suffix: $Domain_Suffix"

#Debug on/off"
If($DebugMode -eq $true)
{
    $DebugPreference = "Continue"
}
Else 
{
    $DebugPreference = "SilentlyContinue"
}

Function Mount-StandardISO 
{
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Image_Path,
        [string]$Temp_Folder_WIM,
        [string]$Temp_Folder_Data
    )
    If(!(Test-path $Image_Path))
    {
        Write-Debug "ISO not found"
        Exit
    }
    $Mountdrive = Mount-DiskImage -ImagePath $Image_Path -PassThru
    $driveLetter = ($Mountdrive | Get-Volume).DriveLetter
    Write-Debug "ISO mounted with driveletter $driveletter"
    
        If(!(Test-Path $Temp_Folder_WIM)) 
        {
            New-Item -Path $Temp_Folder_WIM -ItemType Directory
            write-debug "Folder temp wim created"
        }
    try 
    {
        Copy-Item -Path $driveLetter":\sources\install.wim" -Destination $Temp_Folder_WIM -Force -Verbose
        Write-Debug "Install.wim copy succesfull"
    }
    catch 
    {
        Write-Debug "Copy install.wim failed"
        Exit 1
    }
    
        if (!(Test-Path $Temp_Folder_Data)) 
        {
            New-Item -Path $Temp_Folder_Data -ItemType Directory
            Write-Debug "Folder temp data created"
        }
        
        #Copy Files to temp folder without nanoserver
        $source = $driveLetter+":\"
        $destination = $Temp_Folder_Data
        $copyoptions = "/MIR"
        $excludefolder = "/xd NanoServer"
        $command = "robocopy `"$($source)`" $($destination) $copyoptions $excludefolder"
        try 
        {
            $output = Invoke-Expression $command
            Write-Debug "File copy succesfull"
        }
        catch 
        {
            Write-Debug "Copy of data failed"
            Exit 1
        }    

    Dismount-DiskImage -ImagePath $Image_Path
    Write-Debug "ISO mounting and file copy finished"
}

Function Replace_Placeholders
{
    # Parameter help description
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $true)]
    [string]$OldValue,
    [Parameter(Mandatory = $true)]
    [string]$NewValue,
    [Parameter(Mandatory = $true)]
    [string]$Temp_Folder_Data
    )
    Write-Debug "Replace $OldValue with $NewValue"
    $ConfigFile = "$Temp_Folder_Data\autounattend.xml"
    (Get-Content $ConfigFile)  |
    ForEach-Object {$_ -replace $OldValue, $NewValue} | 
    Set-Content $ConfigFile
}

Function Modify_autounattend_File 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Servername,
        [Parameter(Mandatory = $true)]
        [string]$IP,
        [Parameter(Mandatory = $true)]
        [string]$Gateway,
        [Parameter(Mandatory = $true)]
        [string]$Subnet,
        [Parameter(Mandatory = $true)]
        [string]$File_Path,
        [Parameter(Mandatory = $true)]
        [string]$DNS,
        [Parameter(Mandatory = $true)]
        [string]$Domain_Suffix,
        [Parameter(Mandatory = $true)]
        [string]$Temp_Folder_Data
    )

        If($Subnet -eq "255.255.255.0") 
        {
            $SubnetSegment = "/24"    
        }
        else 
        {
            $SubnetSegment = "/23"    
        }
    $SubnetSegment = $IP+$SubnetSegment
    
    try 
    {
        Copy-item -Path $autounattend_File_Path -Destination $Temp_Folder_Data
        Write-Debug "copy autounattend from $autounattend_File_Path succesfull to $Temp_Folder_Data"
    }
    catch 
    {
        Write-Debug "copy autounattend failed"
        Exit 1
    }
    
    Replace_Placeholders -OldValue "%Subnet%" -NewValue $SubnetSegment -Temp_Folder_Data $Temp_Folder_Data
    Replace_Placeholders -OldValue "%IpAddress%" -NewValue $IP -Temp_Folder_Data $Temp_Folder_Data
    Replace_Placeholders -OldValue "%Gateway%" -NewValue $Gateway -Temp_Folder_Data $Temp_Folder_Data
    Replace_Placeholders -OldValue "%COMPUTERNAME%" -NewValue $Servername -Temp_Folder_Data $Temp_Folder_Data
    Replace_Placeholders -OldValue "%DNS1%" -NewValue $DNS -Temp_Folder_Data $Temp_Folder_Data
    Replace_Placeholders -OldValue "%Suffix%" -NewValue $Domain_Suffix -Temp_Folder_Data $Temp_Folder_Data
}

Function Copy-InstallWIM
{
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Temp_Folder_WIM,
        [Parameter(Mandatory = $true)]
        [string]$Temp_Folder_Data
    )  
        try 
        {
            Copy-Item -Path $Temp_Folder_WIM -Destination $Temp_Folder_Data -Force
            Write-Debug "Copy of install.wim succesfull"      
        }
        catch 
        {
            Write-Debug "Copy of install.wim failed"
            Exit 1
        }
}

Function CreateISO 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ISO_Name,
        [Parameter(Mandatory = $true)]
        [string]$Path_to_Oscdimg
    )
    
    #$Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
    Push-Location -Path $Path_to_Oscdimg
    try 
    {
        .\oscdimg.exe -bC:\Temp\ISO\efi\microsoft\boot\efisys_noprompt.bin -u2 -h -m -lWIN_SERVER_2016 C:\Temp\ISO C:\Temp\$ISO_Name
        If($LASTEXITCODE -eq 0)
        {
            Write-Debug "Iso succesfull created"
        }
        else 
        {
            Write-Debug "Iso creation failed"    
        }
    }
    catch 
    {
        Write-Debug "Iso creation failed"
        Exit 1
    }
    Pop-Location
}

Function Cleanup 
{
    # Parameter help description
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Temp_Folder_Data,
        [Parameter(Mandatory = $true)]
        [string]$Temp_Folder_WIM
    )

    Remove-Item -Path $Temp_Folder_Data -Recurse -Force
    Remove-Item -Path $Temp_Folder_WIM -Recurse -Force
    Write-Debug "Cleanp finished"
}

#Executing starts here
#Mouting ISO, copy files to temp
Mount-StandardISO -Image_Path $Image_Path -Temp_Folder_Data $Temp_Folder_Data -Temp_Folder_WIM $Temp_Folder_WIM

#Modify unattended.xml
Modify_autounattend_File -Servername $Servername -File_Path $autounattend_File_Path -Temp_Folder_Data $Temp_Folder_Data -IP $IP -Gateway $Gateway -Subnet $Subnet -DNS $DNS -Domain_Suffix $Domain_Suffix

#Copy install.wim to ISO directory
Copy-InstallWIM -Temp_Folder_WIM $Temp_Folder_WIM -Temp_Folder_Data $Temp_Folder_Data

#Create Boot ISO combined with unattendend.xml
CreateISO -ISO_Name "Windows_Server_2016_Datacenter_$Servername.iso" -Path_to_Oscdimg $Path_to_Oscdimg

#Delete temp folders and files
Cleanup -Temp_Folder_Data $Temp_Folder_Data -Temp_Folder_WIM $Temp_Folder_WIM

#Measure runtime
$Runtime = $StopWatch.Elapsed.TotalSeconds
Write-Debug "Total runtime in seconds: $Runtime"