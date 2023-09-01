BeforeDiscovery {
    Get-Module PSTableauREST | Remove-Module -Force
    Import-Module ./PSTableauREST.psm1 -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
}

Describe "Unit Tests for PSTableauREST" -Tag Unit {
    Context "Checking config files" -ForEach $ConfigFiles {
        It "<_> should be valid config file" {
            $ConfigFile = Get-Content $_ | ConvertFrom-Json
            $ConfigFile.server | Should -Not -BeNullOrEmpty
            # $ConfigFile.site | Should -Not -BeNullOrEmpty
            $ConfigFile.username | Should -Not -BeNullOrEmpty
            $ConfigFile.password | Should -Not -BeNullOrEmpty
        }
    }
}
