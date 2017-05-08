# Windows
Build a specialized Windows Server Boot ISO with a modified autounattended.xml on the fly in 80 seconds(may depend on your environment). 
In this example the chosen Version is "Windows Server 2016 SERVERDATACENTER"

# Windows Unattended Installation Windows Server 2016

# Pros
- No need for PXE
- No need for DHCP
- Fully "Zero Touch Installation" without SCCM or Altiris or something similar
- Same Workflow for ZTI for VMs and physical Server

# Cons
- DNS must be available
- IP must be available

# Requirements
- Fixed network settings
- Windows Server 2016 ISO File
- Prepared autounattended.xml file with a placeholder for the computername %COMPUTERNAME%, %IpAddress%, %Subnet%, %Gateway%, %Suffix%, %DNS%
- Installed Deployment and Imaging Tools Environment
- Windows ADK(Assessment and Deployment Kit)

# Optional
- Place Serial Key in autoattend.xml
- Change OS Version by changing SERVERDATACENTER to SERVERSTANDARD

# Step by step
- Mount original setup ISO
- Copy install.wim to Temp
- Copy Files from ISO to Temp, exclude folder "NanoServer"
- Place unattended file in source
- Modify unattended file
- Replace install.wim in source
- Generate *.iso with osdimg.exe from "Deplyoment and Imaging Tools Environment"
- Create VM with ISO as boot option
- enjoy ;)

# Next step
- Create project in git 
- Build release pipeline
- Create *.iso for every new server
