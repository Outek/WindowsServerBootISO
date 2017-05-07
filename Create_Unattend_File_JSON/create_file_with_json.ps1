$Values = Get-Content -Raw -Path ..\Example_JSON\server.json | ConvertFrom-Json

. ..\Windows_Server_with_static_IP_UEFI\Create_Unattended_ISO.ps1 -IP $Values.IP[0] -Gateway $Values.Gateway -Subnet $Values.Subnet -DNS $Values.DNS -Servername $Values.Servername -DebugMode $true -Domain_Suffix $Values.Domain_Suffix