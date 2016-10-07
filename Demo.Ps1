<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>



# The State of PowerShell
    # and Happy Birthday Nov 18th

# Why Powershell on Linux

# on Mac 
powershell
Get-Command
Get-Command | measaure
code $profile # notice ps scripts work just fine.

# Why Powershell on Linux
#- Why now? Cloud worls - Azure, AWS - need cross latform management
#- Supported for VMWare, SQL, and many more to come
#- Empowers single management stack
#- Open sourced - anyone can reaad the code and contribute
#- Windows api versus document oriented -- object challange
#- MIT License

# GitHub Repo
https://github.com/PowerShell/PowerShell
# Releases
https://github.com/PowerShell/PowerShell/releases


#Copy to linux
scp ./powershell-6.0.0_alpha.10-1.el7.centos.x86_64.rpm  root@centos:/PowerShell
scp ./powershell_6.0.0-alpha.10-1ubuntu1.16.04.1_amd64.deb  root@ubuntu:/PowerShell
# Mac is a PKG - run as normal

#Install on Linux
sudo yum install powershell-6.0.0_alpha.10-1.el7.centos.x86_64.rpm
sudo dpkg -i powershell_6.0.0-alpha.10-1ubuntu1.16.04.1_amd64.deb 

#######################################
#Discovery
 Get-Help
Get-Help Get-Command -Full
Update-Help -Force
Man Get-Command #fails
Get-Help ls #fails

## Alias in Linux and PowerShell -- ls
Get-ChildItem
ls
ls -l
Get-Process
ps
## Alias in Linux and PowerShell -- ls

## PSGalery
Find-Module
Find-Module -tag linux # not exactly yet
Find-Module -filter linux # This works well
# You can't install modules unless the support .NET.COre - like PSSQL

#Pipeline
Get-Process | Get-Member # note StadardInput and StadardOutput
Get-Process -Name bash
Get-Process | grep bash
ps | grep bash

# Functions and modules
# Just open and show


#### FOR MORE LINUX DEMOS - SEE Play-byPlay with Jeffrey Snover at Pluralsight

#######################################################
# Demos and instructions for features
https://github.com/PowerShell/PowerShell/tree/master/demos # or just the demos folder of github

########################################################################
# PowerShell remoting over SSH
https://github.com/PowerShell/PowerShell/tree/master/demos/SSHRemoting
# Will need Open-SSH for Windows - instructions here:
https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
# Then return to Remoting instructions
code 'c:\program files\openssh\sshd_config'

# for linux --
vim /etc/ssh/sshd_config
<#
VIM file
:e - edit
:i - insert
:w - save
:q - quit
:wq - save and quit
#>

# Then test from Windows
Invoke-command -HostName ubuntu -UserName jasonh {Get-Process}
Enter-Pssession -hostname centos -UserName jasonh

# Linux to Linux
# USe Mac to CentOS
powershell
Enter-PSSession -HostName centos -UserName jasonh


########################################
# DSC for linux
https://github.com/PowerShell/PowerShell/tree/master/demos/DSC

#ON Client!
Open regular old powershell

Find-Module nx
Install-module nx
Get-DscResource
# Go to DSC folder and open LinusDSC - execute

#### LEARN Linux
Jeffrey Snover
https://app.pluralsight.com/library/courses/play-by-play-microsoft-open-source-powershell-linux-mac/table-of-contents

Anthony Nocentino on Pluralsight
https://app.pluralsight.com/library/courses/essential-tools-red-hat-enterprise-linux/table-of-contents
https://app.pluralsight.com/library/courses/linux-networking-advanced-lfce/table-of-contents
