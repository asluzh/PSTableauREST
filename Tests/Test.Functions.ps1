if ($env:windir) { # running on Windows platform (PS 5.1)
    Import-Module Microsoft.PowerShell.SecretStore
    Import-Module Microsoft.PowerShell.SecretManagement
    $private:secure_password = Import-CliXml -Path 'Tests/Config/securestore_passwd.xml'
    Unlock-SecretStore -Password $private:secure_password -PasswordTimeout 3600
    Add-Type -AssemblyName System.Net.Http
} else { # running on MacOS/Unix platform (PS 7.x)
    Import-Module Microsoft.PowerShell.SecretManagement
}

function Test-GetSecurePassword {
    [OutputType([securestring])]
    Param
    (
        [Parameter(Mandatory)][string]$Namespace,
        [Parameter(Mandatory)][string]$Username
    )
    if ($env:windir) { # secure store on Windows platform
        $securePw = Get-Secret -Name "$Namespace|$Username" -Vault SecretStore -ErrorAction Ignore
        if (!$securePw) {
            $securePw = (Get-Credential -Message "Enter password for $Username at $Namespace" -Username $Username).Password
            Set-Secret -Name "$Namespace|$Username" -Vault SecretStore -SecureStringSecret $securePw
        }
        return $securePw
    } else { # secure store on MacOS/Unix platform
        $securePw = Get-Secret -Name "$Namespace|$Username" -Vault KeyChain -ErrorAction Ignore
        if (!$securePw) {
            $securePw = (Get-Credential -Message "Enter password for $Username at $Namespace" -Username $Username).Password
            Set-Secret -Name "$Namespace|$Username" -Vault KeyChain -SecureStringSecret $securePw
        }
        return $securePw
    }
}
