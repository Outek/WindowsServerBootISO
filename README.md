# Windows
Build a specialized Windows Server Boot ISO with a modified autounattended.xml on the fly in 60 seconds. 

# Windows Unattended Installation Windows Server 2016

# Requirements
- Windows Server 2016 ISO File
- Prepared autounattended.xml file with a placeholder for the computername %COMPUTERNAME%
- Deployment and Imaging Tools Environment
- Windows ADK(Assessment and Deployment Kit)

# Mount ISO, copy install.wim
- Mount ISO
- Copy install.wim to Temp
- Copy Files from ISO to Temp
- Generate unattended file with install.wim
- Place unattended file in source
- Replace install.wim in source
- Generate iso with osdimg.exe from Deplyoment and Imaging Tools Environment