<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>


Configuration ExampleConfiguration{

    Import-DscResource -Module nx

    Node  "ubuntu"{
    nxFile ExampleFile {

        DestinationPath = "/tmp/example"
        Contents = "hello world `n"
        Ensure = "Present"
        Type = "File"
    }

    }
}
ExampleConfiguration -OutputPath:"C:\DSC"

Break

$opt = New-CimSessionOption -UseSSL:$true -SkipCACheck:$true -SkipCNCheck:$true -SkipRevocationCheck:$true
$session=New-CimSession -Credential root -Computername ubuntu -port:5986 -Authentication:basic -SessionOption:$opt #-OperationTimeoutsec:90
Start-DscConfiguration -Path C:\DSC -Cimsession $session -wait -verbose