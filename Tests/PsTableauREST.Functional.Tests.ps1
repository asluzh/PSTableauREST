BeforeDiscovery {
    Get-Module PSTableauREST | Remove-Module -Force
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
}

Describe "Functional Tests for PSTableauREST" -Tag Unit {
    Context "Basic server operations" -ForEach $ConfigFiles {
        BeforeAll {
            $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        }
        It "Perform sign-in for <ConfigFile.server>" {
            $result = Invoke-TSSignIn -server $ConfigFile.server -siteID $ConfigFile.site -username $ConfigFile.username -password $ConfigFile.password
            $result | Should -Contain "Signed In Successfully"
        }
        It "Perform sign-out for <ConfigFile.server>" {
            {Invoke-TSSignOut} | Should -Not -Throw
        }
    }
}
