BeforeAll {
    Get-Module PSTableauREST | Remove-Module -Force
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
    Import-Module Microsoft.PowerShell.SecretManagement
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
    . ./Tests/Test.Functions.ps1
}

Describe "Functional Tests for PSTableauREST" -Tag Unit {
    Context "Basic server operations" -ForEach $ConfigFiles {
        BeforeAll {
            $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "securePw" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
        }
        It "Perform sign-in for <ConfigFile.server>" {
            $result = Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.securePw
            $result | Should -Contain "Signed In Successfully"
        }
        It "Perform sign-out for <ConfigFile.server>" {
            {Invoke-TSSignOut} | Should -Not -Throw
        }
        It "Invoke PAT sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.pat_name) {
                Set-ItResult -Skipped
            }
            $response = Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
            $response.tsResponse.credentials.user.id | Should -BeOfType String
            $response = Invoke-TSSignOut
            $response | Should -BeOfType "String"
        }
    }
}
