
#Path to Deploying and Imaging Tools Environment

#oscdimg.exe -bE:\ISO\boot\etfsboot.com -u2 -h -m -lWIN_SERVER_2012_R2-CORE E:\ISO <Destination for ISO>
#oscdimg.exe -bE:\ISO\boot\etfsboot.com -u2 -h -m -lWIN_SERVER_2012_R2-CORE E:\ISO E:\WinServer2012Core_unattend2.iso
$Path_to_Oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
Push-Location -Path $Path_to_Oscdimg
.\oscdimg.exe -n -bC:\Temp\ISO\boot\etfsboot.com c:\Temp c:\Temp\WindowsServer2016.iso -o -m
Pop-Location