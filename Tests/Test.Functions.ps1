function Test-GetSecurePassword {
    [OutputType([securestring])]
    Param
    (
        [Parameter(Mandatory)][string]$Namespace,
        [Parameter(Mandatory)][string]$Username
    )
    $securePw = Get-Secret -Name "$Namespace|$Username" -Vault KeyChain -ErrorAction Ignore
    if (!$securePw) {
        $securePw = (Get-Credential -Message "Enter password for $Username at $Namespace" -Username $Username).Password
        Set-Secret -Name "$Namespace|$Username" -Vault KeyChain -SecureStringSecret $securePw
    }
    return $securePw
}
