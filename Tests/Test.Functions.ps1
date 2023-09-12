function Test-GetSecurePassword {
    [OutputType([SecureString])]
    Param
    (
        [Parameter(Mandatory = $true)][String]$Namespace,
        [Parameter(Mandatory = $true)][String]$Username
    )
    $securePw = Get-Secret -Name "$Namespace|$Username" -Vault KeyChain -ErrorAction Ignore
    if (!$securePw) {
        $securePw = (Get-Credential -Message "Enter password for $Username at $Namespace" -Username $Username).Password
        Set-Secret -Name "$Namespace|$Username" -Vault KeyChain -SecureStringSecret $securePw
    }
    return $securePw
}
