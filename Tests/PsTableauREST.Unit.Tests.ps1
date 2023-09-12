BeforeDiscovery {
    # Get-Module PSTableauREST | Remove-Module -Force
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    # Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
    Import-Module Microsoft.PowerShell.SecretManagement -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
}
BeforeAll {
    . ./Tests/Test.Functions.ps1
}

Describe "Unit Tests for PSTableauREST" -Tag Unit {
    Context "Basic server operations" -ForEach $ConfigFiles {
        BeforeAll {
            $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        }
        It "<_> should be valid config file" {
            $ConfigFile.server | Should -Not -BeNullOrEmpty
            # $ConfigFile.site | Should -Not -BeNullOrEmpty
            $ConfigFile.username | Should -Not -BeNullOrEmpty
        }
        It "Password for <ConfigFile.server> should be available" {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "securePw" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
            $ConfigFile.securePw | Should -Not -BeNullOrEmpty
        }
    }
}
