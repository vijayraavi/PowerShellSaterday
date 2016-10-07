<#
Disclaimer

This example code is provided without copyright and �AS IS�.  It is free for you to use and modify.
Note: These demos should not be run as a script. These are the commands that I use in the 
demonstrations and would need to be modified for your environment.

#>


<# Notes:

The bulk of this config is authored by Melissa (Missy) Januszko.
Currently on her public DSC hub located here:
https://github.com/majst32/DSC_public.git

Goal - Create a Domain Controller, Populute with OU's Groups and Users.
       Ensure DNS and DHCP for scope 192.168.3.0
       Ensure ADCS installed including Policy services.
       
Warning: This config is for a lab environment - use of Plain text passwords are approved ;)    

#>


$ConfigData = @{
                AllNodes = @(
                @{
                    NodeName = "*"
                    MachineName = $DomainController #Gets this from the Build script
                    IPAddress = '192.168.3.10'
                    InterfaceAlias = 'Ethernet'
                    DefaultGateway = '192.168.3.1'
                    SubnetMask = '24'
                    AddressFamily = 'IPv4'
                    DNSAddress = '192.168.3.10'
                    Domain = "Company.Pri"
                    DomainDN = "DC=Company,DC=Pri"
                    PSDSCAllowPlainTextPassword = $True
                    PSDSCAllowDomainUser = $True
                    DomainAdministratorCredential = $creds
                    SafemodeAdministratorPassword = $creds
                    DCDatabasePath = "C:\NTDS"
                    DCLogPath = "C:\NTDS"
                    SysvolPath = "C:\Sysvol"
                    CACN = 'Company.Pri'
                    CADNSuffix = "C=US,L=Phoenix,S=Arizona,O=Company"
                    CADatabasePath = "C:\windows\system32\CertLog"
                    CALogPath = "C:\CA_Logs"
                    
                },

                @{
                    NodeName = $DomainController
                }
                
            )
          
        }

Configuration DomainController {

    import-DSCresource -ModuleName PSDesiredStateConfiguration,
        @{ModuleName="xActiveDirectory";ModuleVersion="2.12.0.0"},
        @{ModuleName="xNetworking";ModuleVersion="2.10.0.0"},
        @{ModuleName="XADCSDeployment";ModuleVersion="1.0.0.0"},
        @{ModuleName="xComputerManagement";ModuleVersion="1.7.0.0"},
        @{ModuleName="xDhcpServer";ModuleVersion="1.4.0.0"}
    
    node $AllNodes.NodeName {

#region - LCM
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

#endregion
 
#region - Network settings

        xComputer ComputerName { 
          Name = $Node.MachineName 
        }

        xIPAddress SetIP {
            IPAddress = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            SubnetMask = $Node.SubnetMask
            AddressFamily = $Node.AddressFamily
            DependsOn ='[xComputer]ComputerName' 
        }

        xDefaultGatewayAddress SetDefGate {
            InterfaceAlias = $Node.InterfaceAlias
            Address = $Node.DefaultGateway
            AddressFamily = $Node.AddressFamily
            DependsOn ='[xComputer]ComputerName'
        }

        xDNSServerAddress SetDNS {
            Address = $Node.DNSAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily = $Node.AddressFamily
            DependsOn ='[xComputer]ComputerName'
        }




#endregion  
       
#region - firewall rules
     
        xFirewall vmpingFWRule {
            Name = 'vm-monitoring-icmpv4'
            Action = 'Allow'
            Direction = 'Inbound'
            Enabled = $True
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias       
        }
        
        xFirewall SMB {
            Name = 'FPS-SMB-In-TCP'
            Action = 'Allow'
            Direction = 'Inbound'
            Enabled = $True
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias         
        }

        xFirewall RemoteEvtLogFWRule1 {
            Name = "RemoteEventLogSvc-In-TCP"
            Action = "Allow"
            Direction = 'Inbound'
            Enabled = $True
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias          
        }

        xFirewall RemoteEvtLogFWRule2 {
            Name = "RemoteEventLogSvc-NP-In-TCP"
            Action = "Allow"
            Direction = 'Inbound'
            Enabled = $True
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias         
        }

        xFirewall RemoteEvtLogFWRule3 {
            Name = "RemoteEventLogSvc-RPCSS-In-TCP"
            Action = "Allow"
            Direction = 'Inbound'
            Enabled = $True
            Ensure = 'Present'
            InterfaceAlias = $Node.InterfaceAlias      
        }

 #endregion    
#
#region Enable DSC Analytic logs 

        Script DSCAnalyticLog {

            DependsOn = '[xFirewall]RemoteEvtLogFWRule3'
            TestScript = {
                            $status = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            if ($status -contains "enabled: true") {return $True} else {return $False}
                        }
            SetScript = {
                            wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true
                        }
            getScript = {
                            $Result = wevtutil get-log “Microsoft-Windows-Dsc/Analytic”
                            return @{Result = $Result}
                        }
        }

#endregion
#
#region - ADDS 
        
        WindowsFeature ADDS {
           Ensure = "Present"
           Name   = "AD-Domain-Services"
           DependsOn = '[xComputer]ComputerName'
        }
 
        
        xADDomain FirstDC {
            DomainName = $Node.Domain
            DomainAdministratorCredential = $Node.DomainAdministratorCredential
            SafemodeAdministratorPassword = $Node.SafemodeAdministratorPassword
            DatabasePath = $Node.DCDatabasePath
            LogPath = $Node.DCLogPath
            SysvolPath = $Node.SysvolPath 
            DependsOn = '[WindowsFeature]ADDS'
        }  
        
#endregion    
#
#region DHCP
        
        xWaitForADDomain DscForestWait {
            DomainName = $Node.Domain
            DomainUserCredential = $Creds
            RetryCount = '20'
            RetryIntervalSec = '60'
            DependsOn = "[xADDomain]FirstDC"
        }

        
        WindowsFeature DHCP {
            Name = 'DHCP'
            Ensure = 'Present'
            DependsOn = '[xWaitForADDomain]DscForestWait' 
        }

  
        xDhcpServerScope DhcpScope {
            Name = '192Scope'
            IPStartRange = '192.168.3.100'
            IPEndRange = '192.168.3.200'
            SubnetMask = '255.255.255.0'
            State = 'Active'
            DependsOn = '[WindowsFeature]DHCP'
        }

        xDhcpServerOption DhcpOption {
            ScopeID = '192.168.3.0'
            AddressFamily = 'IPv4'
            DnsServerIPAddress = '192.168.3.10'
            Router = '192.168.3.1'
            DependsOn = '[xDhcpServerScope]DhcpScope'
        }

        xDhcpServerAuthorization DhcpAuth {
            Ensure = 'Present'
            DependsOn = '[xDhcpServerScope]DhcpScope'
        }

#endregion

#region - ADCS
                            
        WindowsFeature ADCS {
            Ensure = 'Present'
            Name = 'ADCS-Cert-Authority'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        WindowsFeature ADCSEnrollWebPol {
            Ensure = 'Present'
            Name = 'ADCS-Enroll-web-Pol'
            DependsOn = '[WindowsFeature]ADCS'
        }

        WindowsFeature ADCSEnrollWebSvc {
            Ensure = 'Present'
            Name = 'ADCS-Enroll-Web-Svc'
            DependsOn = '[WindowsFeature]ADCS'
        }

        WindowsFeature ADCSWebEnroll {
            Ensure = 'Present'
            Name = 'ADCS-web-Enrollment'
            DependsOn = '[WindowsFeature]ADCS'
        }

        xAdcsCertificationAuthority ADCSConfig
        {
            CAType = 'EnterpriseRootCA'
            Credential = $Creds
            CryptoProviderName = 'RSA#Microsoft Software Key Storage Provider'
            HashAlgorithmName = 'SHA256'
            KeyLength = 2048
            CACommonName = $Node.CACN
            CADistinguishedNameSuffix = $Node.CADNSuffix
            DatabaseDirectory = $Node.CADatabasePath
            LogDirectory = $Node.CALogPath
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 2
            DependsOn = '[WindowsFeature]ADCS'    
        }


#endregion

#region - Add GPO for PKI AutoEnroll
        script CreatePKIAEGpo
        {
            Credential = $EACredential
            TestScript = {
                            if ((get-gpo -name "PKI AutoEnroll" -ErrorAction SilentlyContinue) -eq $Null) {
                                return $False
                            } 
                            else {
                                return $True}
                        }
            SetScript = {
                            new-gpo -name "PKI AutoEnroll"
                        }
            GetScript = {
                            $GPO= (get-gpo -name "PKI AutoEnroll")
                            return @{Result = $GPO}
                        }
            DependsOn = '[xADDomain]FirstDC'
        }
        
        script setAEGPRegSetting1
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -ErrorAction SilentlyContinue).Value -eq 7) {
                                return $True
                            }
                            else {
                                return $False
                            }
                        }
            SetScript = {
                            Set-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy" -Value 7 -Type DWord
                        }
            GetScript = {
                            $RegVal1 = (Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "AEPolicy")
                            return @{Result = $RegVal1}
                        }
            DependsOn = '[Script]CreatePKIAEGpo'
        }

        script setAEGPRegSetting2 
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -ErrorAction SilentlyContinue).Value -eq 10) {
                                return $True
                                }
                            else {
                                return $False
                                 }
                         }
            SetScript = {
                            Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent" -value 10 -Type DWord
                        }
            GetScript = {
                            $Regval2 = (Get-GPRegistryValue -name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationPercent")
                            return @{Result = $RegVal2}
                        }
            DependsOn = '[Script]setAEGPRegSetting1'

        }
                                  
        script setAEGPRegSetting3
        {
            Credential = $EACredential
            TestScript = {
                            if ((Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -ErrorAction SilentlyContinue).value -match "MY") {
                                return $True
                                }
                            else {
                                return $False
                                }
                        }
            SetScript = {
                            Set-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames" -value "MY" -Type String
                        }
            GetScript = {
                            $RegVal3 = (Get-GPRegistryValue -Name "PKI AutoEnroll" -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" -ValueName "OfflineExpirationStoreNames")
                            return @{Result = $RegVal3}
                        }
            DependsOn = '[Script]setAEGPRegSetting2'
        }
      
        Script SetAEGPLink
        {
            Credential = $EACredential
            TestScript = {
                            try {
                                    set-GPLink -name "PKI AutoEnroll" -target $Using:Node.DomainDN -LinkEnabled Yes -ErrorAction silentlyContinue
                                    return $True
                                }
                            catch
                                {
                                    return $False
                                }
                         }
            SetScript = {
                            New-GPLink -name "PKI AutoEnroll" -Target $Using:Node.DomainDN -LinkEnabled Yes 
                        }
            GetScript = {
                            $GPLink = set-GPLink -name "PKI AutoEnroll" -target $Using:Node.DomainDN
                            return @{Result = $GPLink}
                        }
            DependsOn = '[Script]setAEGPRegSetting3'
        }                           

#endregion 

#region - Add OU for groups

        xADOrganizationalUnit IT {
            Name = 'IT'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADOrganizationalUnit Dev {
            Name = 'Dev'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADOrganizationalUnit Marketing {
            Name = 'Marketing'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADOrganizationalUnit Sales {
            Name = 'Sales'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADOrganizationalUnit Accounting {
            Name = 'Accounting'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADOrganizationalUnit JEA_Operators {
            Name = 'JEA_Operators'
            Ensure = 'Present'
            Path = $Node.DomainDN
            ProtectedFromAccidentalDeletion = $False
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }


#endregion

#region Add ADUsers
        xADUser IT1 {
            DomainName = $node.Domain
            Path = "OU=IT,$($node.DomainDN)"
            UserName = 'DonJ'
            GivenName = 'Don'
            Surname = 'Jones'
            DisplayName = 'Don Jones'
            Description = 'The Main guy'
            Department = 'IT'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser IT2 {
            DomainName = $node.Domain
            Path = "OU=IT,$($node.DomainDN)"
            UserName = 'Jasonh'
            GivenName = 'Jason'
            Surname = 'Helmick'
            DisplayName = 'Jason Helmick'
            Description = 'The Fun guy'
            Department = 'IT'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser IT3 {
            DomainName = $node.Domain
            Path = "OU=IT,$($node.DomainDN)"
            UserName = 'GregS'
            GivenName = 'Greg'
            Surname = 'Shields'
            DisplayName = 'Greg Shields'
            Description = 'The Janitor'
            Department = 'IT'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Dev1 {
            DomainName = $node.Domain
            Path = "OU=Dev,$($node.DomainDN)"
            UserName = 'SimonA'
            GivenName = 'Simon'
            Surname = 'Allardice'
            DisplayName = 'Simon Allardice'
            Description = 'The Brilliant one'
            Department = 'Dev'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Acct1 {
            DomainName = $node.Domain
            Path = "OU=Accounting,$($node.DomainDN)"
            UserName = 'AaronS'
            GivenName = 'Aaron'
            Surname = 'Smith'
            DisplayName = 'Aaron Smith'
            Description = 'Accountant'
            Department = 'Accounting'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Acct2 {
            DomainName = $node.Domain
            Path = "OU=Accounting,$($node.DomainDN)"
            UserName = 'AndreaS'
            GivenName = 'Andrea'
            Surname = 'Smith'
            DisplayName = 'Andrea Smith'
            Description = 'Accountant'
            Department = 'Accounting'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Acct3 {
            DomainName = $node.Domain
            Path = "OU=Accounting,$($node.DomainDN)"
            UserName = 'AndyS'
            GivenName = 'Andy'
            Surname = 'Smith'
            DisplayName = 'Andy Smith'
            Description = 'Accountant'
            Department = 'Accounting'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Sales1 {
            DomainName = $node.Domain
            Path = "OU=Sales,$($node.DomainDN)"
            UserName = 'SamS'
            GivenName = 'Sam'
            Surname = 'Smith'
            DisplayName = 'Sam Smith'
            Description = 'Sales'
            Department = 'Sales'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Sales2 {
            DomainName = $node.Domain
            Path = "OU=Sales,$($node.DomainDN)"
            UserName = 'SonyaS'
            GivenName = 'Sonya'
            Surname = 'Smith'
            DisplayName = 'Sonya Smith'
            Description = 'Sales'
            Department = 'Sales'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Sales3 {
            DomainName = $node.Domain
            Path = "OU=Sales,$($node.DomainDN)"
            UserName = 'SamanthaS'
            GivenName = 'Samantha'
            Surname = 'Smith'
            DisplayName = 'Samantha Smith'
            Description = 'Sales'
            Department = 'Sales'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Market1 {
            DomainName = $node.Domain
            Path = "OU=Marketing,$($node.DomainDN)"
            UserName = 'MarkS'
            GivenName = 'Mark'
            Surname = 'Smith'
            DisplayName = 'Mark Smith'
            Description = 'Marketing'
            Department = 'Marketing'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Market2 {
            DomainName = $node.Domain
            Path = "OU=Marketing,$($node.DomainDN)"
            UserName = 'MonicaS'
            GivenName = 'Monica'
            Surname = 'Smith'
            DisplayName = 'Monica Smith'
            Description = 'Marketing'
            Department = 'Marketing'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser Market3 {
            DomainName = $node.Domain
            Path = "OU=Marketing,$($node.DomainDN)"
            UserName = 'MattS'
            GivenName = 'Matt'
            Surname = 'Smith'
            DisplayName = 'Matt Smith'
            Description = 'Marketing'
            Department = 'Marketing'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser JEA1 {
            DomainName = $node.Domain
            Path = "OU=JEA_Operators,$($node.DomainDN)"
            UserName = 'JimJ'
            GivenName = 'Jim'
            Surname = 'Jea'
            DisplayName = 'Jim Jea'
            Description = 'JEA'
            Department = 'IT'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADUser JEA2 {
            DomainName = $node.Domain
            Path = "OU=JEA_Operators,$($node.DomainDN)"
            UserName = 'JillJ'
            GivenName = 'Jill'
            Surname = 'Jea'
            DisplayName = 'Jill Jea'
            Description = 'JEA'
            Department = 'IT'
            Enabled = $true
            Password = $creds
            PasswordNeverExpires = $true
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }
 
#endregion

#region Add Groups

        xADGroup ITG1 {
            GroupName = 'IT'
            Path = "OU=IT,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            Members = 'DonJ', 'Jasonh', 'GregS'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADGroup SalesG1 {
            GroupName = 'Sales'
            Path = "OU=Sales,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            Members = 'SamS', 'SonyaS', 'SamanthaS'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADGroup MKG1 {
            GroupName = 'Marketing'
            Path = "OU=Marketing,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            Members = 'MarkS', 'MonicaS', 'MattS'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADGroup AccountG1 {
            GroupName = 'Accounting'
            Path = "OU=Accounting,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            Members = 'AaronS', 'AndreaS', 'AndyS'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        xADGroup JEAG1 {
            GroupName = 'JEA Operators'
            Path = "OU=JEA_Operators,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Universal'
            Members = 'JimJ', 'JillJ'
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

#endregion


    } #End Node

} #End Config


#



$SecPass = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential("Company\Administrator", $SecPass)

DomainController -configurationData $ConfigData -OutputPath .\DSCConfig 
