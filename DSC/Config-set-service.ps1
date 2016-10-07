<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>


Configuration ServiceBits{
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    Node $ComputerName {
        Service bits {
            Name='bits'
            State='running'
        }
    }
}

Break
ServiceBits -ComputerName dc -OutputPath c:\dsc