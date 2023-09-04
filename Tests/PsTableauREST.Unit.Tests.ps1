BeforeDiscovery {
    Get-Module PSTableauREST | Remove-Module -Force
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
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
            $ConfigFile.password | Should -Not -BeNullOrEmpty
        }
        It "Perform sign-in for <ConfigFile.server>" -Skip {
            $result = Invoke-TSSignIn -server $ConfigFile.server -siteID $ConfigFile.site -username $ConfigFile.username -password $ConfigFile.password
            $result | Should -Contain "Signed In Successfully"
        }
        It "Perform sign-out for <ConfigFile.server>" -Skip {
            {Invoke-TSSignOut} | Should -Not -Throw
        }
    }
}
