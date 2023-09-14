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

Describe "Functional Tests for PSTableauREST" -Tag Functional {
    Context "Basic server operations" -ForEach $ConfigFiles {
        BeforeAll {
            $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "securePw" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
        }
        It "Invoke auth sign-in for <ConfigFile.server>" {
            $response = Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.securePw
            $response.tsResponse.credentials.user.id | Should -BeOfType String
        }
        It "Invoke switch site to <ConfigFile.switchSite> for <ConfigFile.server>" {
            $response = Invoke-TSSwitchSite -Site $ConfigFile.switchSite
            $response.tsResponse.credentials.user.id | Should -BeOfType String
        }
        It "Invoke sign-out for <ConfigFile.server>" {
            $response = Invoke-TSSignOut
            $response | Should -BeOfType "String"
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
        Context "Project handling" {
            BeforeAll {
                Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                $script:projectId = $null
            }
            AfterAll {
                if ($projectId) {
                    Remove-TSProject -ProjectId $projectId
                }
                Invoke-TSSignOut
            }
            It "Create a dummy project on <ConfigFile.server>" {
                $projectName = New-Guid
                $response = New-TSProject -Name $projectName
                $response.tsResponse.project.id | Should -BeOfType String
                $script:projectId = $response.tsResponse.project.id
            }
            It "Update a dummy project <projectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $response = Update-TSProject -ProjectId $projectId -Name $projectNewName
                $response.tsResponse.project.id | Should -Be $projectId
                $response.tsResponse.project.name | Should -Be $projectNewName
            }
            It "Retrieve project on <ConfigFile.server>" {
                $projects = Get-TSProject
                $projects.length | Should -BeGreaterThan 0
                $projects | Where-Object id -eq $projectId | Should -Not -BeNullOrEmpty
            }
            It "Delete a dummy project on <ConfigFile.server>" {
                $response = Remove-TSProject -ProjectId $projectId
                $response | Should -BeOfType String
                $script:projectId = $null
            }
        }
    }
}
