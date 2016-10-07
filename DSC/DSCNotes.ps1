<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>


#DSC

sudo apt-get install python-ctypeslib
python3
>>> import ctypes

# OMI on Ubuntu
# Already copied files to OMI

#Install OMI
sudo dpkg -i ./omi-1.1.0.ssl_100.x64.deb
# Restarting
sudo systemctl restart omid

#Testing OMI
sudo /opt/omi/bin/omicli ei root/omi OMI_Identify

#Configuring OMI
sudo vim /etc/opt/omi/conf/omiserver.conf

#PSRP for OMI
# Requires this package
sudo apt-get install libpam0g-dev libssl-dev
sudo dpkg -i ./psrp-1.0.0-0.universal.x64.deb


# DSC setup
sudo dpkg -i ./dsc-1.1.1-281.ssl_100.x64.deb

#ON Client!
Find-Module nx
Install-module nx
Get-DscResource

Configuration ExampleConfiguration{

    Import-DscResource -Module nx

    Node  "linuxhost.contoso.com"{
    nxFile ExampleFile {

        DestinationPath = "/tmp/example"
        Contents = "hello world `n"
        Ensure = "Present"
        Type = "File"
    }

    }
}
ExampleConfiguration -OutputPath:"C:\temp"

#TEst form Windows
#on client in c:\DSC

$opt = New-CimSessionOption -UseSSL:$true -SkipCACheck:$true -SkipCNCheck:$true -SkipRevocationCheck:$true
$session=New-CimSession -Credential root -Computername ubuntu -port:5986 -Authentication:basic -SessionOption:$opt -OperationTimeoutsec:90



Start-DscConfiguration -Path C:\whatever -Cimsession $session -wait -verbose


