$Server_Hashtable = @{
    Servername = "Testserver"
    IP = "192.168.0.144"
    DNS = "192.168.0.1"
    $Temp_Folder_WIM = "C:\Temp\WIM"
    $Temp_Folder_Data = "C:\Temp\ISO"
    $Image_Path = "C:\Temp\Original_ISO\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"  
    $autounattend_File_Path = "C:\Temp\Answer_File\autounattend.xml"
    $Gateway = "192.168.0.254"
    $Subnet = "255.255.255.0"
    $Domain_Suffix = "domain.internal"
    $DNS = "192.168.0.1"
    $Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
    $DebugMode = $true
}

$Server_Hashtable | ConvertTo-Json -Compress