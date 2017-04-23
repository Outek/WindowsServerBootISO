#Mount ISO
$Mountdrive = Mount-DiskImage -ImagePath \\diskstation\software\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO -PassThru
$driveLetter = ($Mountdrive | Get-Volume).DriveLetter

#Copy-Item -Path <source> -Destination <destination>
Copy-Item -Path $driveLetter":\sources\install.wim" -Destination C:\Temp

Dismount-DiskImage -ImagePath \\diskstation\software\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO