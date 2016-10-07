<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>


Location:
/usr/local/microsoft/powershell
Module location:
/usr/local/microsoft/powershell/Modules
Profile location:
/Users/jasonh/.config/powershell/Microsoft.PowerShell_profile.ps1




# Simple old style

Function Foo ($a='powershell',$b='CPU'){
    Get-Process -name $a | Select-Object -Property Name, $b
}

<#
.SYNOPSIS
   Gets basic information about a process.
.DESCRIPTION
   Gets basic information about a process that you decide on -- which means
   You get to pick one or many.
.PARAMETER ProcessName
    Choose a process you need information about
.EXAMPLE
   PS> Get-MyProcess -ProcessName powershell
   Gets information about the powershell process
.EXAMPLE
   PS> Get-MyProcess -ProcessName powershell, mail
   Gets information for two or more processes
.EXAMPLE
   PS> 'mail','powershell' | Get-MyProcess
   Gets information for two or more processes in the pipeline
#>
Function Get-MYProcess {
    #Added keyword param
    [CmdletBinding()] 
    param
    (
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String[]]$ProcessName       
    )
    Begin{}
    Process{
            Foreach ($Process in $ProcessName){
                $Output=Get-Process -name $Process 

                $Properties=@{
                    'Process'=$Output.Name;
                    'CPU'=$Output.CPU -as [int];
                    'VMGB'=$Output.VirtualMemorySize64 / 1gb -as [int];
                    'WSMB'=$Output.WorkingSet64 / 1mb -as [int]
                }
                #Make an object
                $Obj=New-Object -TypeName PSObject -Property $Properties
                 Write-Output $Obj
            }
    }
    End{}
}

Get-Help Get-MyProcess
Get-Help Get-MyProcess -detailed