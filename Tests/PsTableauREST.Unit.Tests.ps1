BeforeAll {
    Import-Module ./PSTableauREST -Force
    . ./Tests/Test.Functions.ps1
}
BeforeDiscovery {
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
}

Describe "Unit Tests for PSTableauREST" -Tag Unit {
    Context "Basic server operations" -ForEach $ConfigFiles {
        BeforeAll {
            $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        }
        It "Validation check for config file <_>" {
            $ConfigFile.server | Should -Not -BeNullOrEmpty
            # $ConfigFile.site | Should -Not -BeNullOrEmpty
            $ConfigFile.username | Should -Not -BeNullOrEmpty
        }
        It "Password for <ConfigFile.server> should be available" {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "securePw" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
            $ConfigFile.securePw | Should -Not -BeNullOrEmpty
        }
        It "REST API version methods" {
            Set-TSRestApiVersion -ApiVersion 3.11
            Get-TSRestApiVersion | Should -BeOfType version
            Get-TSRestApiVersion | Should -Be "3.11"
            {Assert-TSRestApiVersion -AtLeast 3.12} | Should -Throw
            {Assert-TSRestApiVersion -AtLeast 3.11} | Should -Not -Throw
            {Assert-TSRestApiVersion -AtLeast 3.10} | Should -Not -Throw
            {Assert-TSRestApiVersion -AtLeast 3.9} | Should -Not -Throw
            {Assert-TSRestApiVersion -LessThan 3.8} | Should -Throw
            {Assert-TSRestApiVersion -LessThan 3.11} | Should -Throw
            {Assert-TSRestApiVersion -LessThan 3.20} | Should -Not -Throw
        }
    }
}
