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

Describe "Functional Tests for PSTableauREST" -Tag Functional -ForEach $ConfigFiles {
    BeforeAll {
        $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        $ConfigFile | Add-Member -MemberType NoteProperty -Name "secure_password" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
        if ($ConfigFile.pat_name) {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "pat_secret" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.pat_name)
        }
    }
    Context "Auth operations" -Tag Auth {
        It "Invoke auth sign-in for <ConfigFile.server>" {
            $response = Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
            $response.tsResponse.credentials.user.id | Should -BeOfType String
        }
        It "Invoke switch site to <ConfigFile.switch_site> for <ConfigFile.server>" {
            $response = Invoke-TSSwitchSite -Site $ConfigFile.switch_site
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
    }
    Context "Content operations" -Tag Content {
        BeforeAll {
            if ($ConfigFile.pat_name) {
                Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
            } else {
                Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
            }
            $script:testProjectId = $null
        }
        AfterAll {
            if ($script:testProjectId) {
                Remove-TSProject -ProjectId $testProjectId
            }
            if ($script:testSiteId -and $script:testSite) {
                Invoke-TSSwitchSite -Site $testSite
                Remove-TSSite -SiteId $testSiteId
            }
            Invoke-TSSignOut
        }
        Context "Site operations" -Tag Site {
            It "Create a new site on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    $response = New-TSSite -Name $ConfigFile.test_site_name -ContentUrl $ConfigFile.test_site_contenturl -SiteParams @{
                        adminMode = "ContentOnly"
                        revisionLimit = 20
                    }
                    $response.tsResponse.site.id | Should -BeOfType String
                    $response.tsResponse.site.contentUrl | Should -BeOfType String
                    $script:testSiteId = $response.tsResponse.site.id
                    $script:testSite = $response.tsResponse.site.contentUrl
                }
            }
            It "Update the site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Invoke-TSSwitchSite -Site $testSite} | Should -Not -Throw
                    $siteNewName = New-Guid
                    $response = Update-TSSite -SiteId $testSiteId -SiteParams @{
                        name = $siteNewName
                        revisionLimit = 10
                    }
                    $response.tsResponse.site.id | Should -Be $testSiteId
                    $response.tsResponse.site.contentUrl | Should -Be $testSite
                    $response.tsResponse.site.name | Should -Be $siteNewName
                    {Update-TSSite -SiteId $testSiteId -SiteParams @{
                        name = $ConfigFile.test_site_name
                        adminMode = "ContentAndUsers"
                        userQuota = "1"
                    }} | Should -Not -Throw
                }
            }
            It "Query sites on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    $sites = Get-TSSite
                    $sites.length | Should -BeGreaterThan 0
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Get current site on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Invoke-TSSwitchSite -Site $testSite} | Should -Not -Throw
                    $sites = Get-TSSite -Current
                    $sites.length | Should -Be 1
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Delete the site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Invoke-TSSwitchSite -Site $testSite} | Should -Not -Throw
                    $response = Remove-TSSite -SiteId $testSiteId
                    $response | Should -BeOfType String
                    $script:testSiteId = $null
                    $script:testSite = $null
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                    } else {
                        Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
                    }
                }
            }
        }
        Context "Project operations" -Tag Project {
            It "Create new project on <ConfigFile.server>" {
                $projectName = New-Guid
                $response = New-TSProject -Name $projectName
                $response.tsResponse.project.id | Should -BeOfType String
                $script:testProjectId = $response.tsResponse.project.id
            }
            It "Update the project <testProjectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $response = Update-TSProject -ProjectId $script:testProjectId -Name $projectNewName
                $response.tsResponse.project.id | Should -Be $script:testProjectId
                $response.tsResponse.project.name | Should -Be $projectNewName
            }
            It "Query projects on <ConfigFile.server>" {
                $projects = Get-TSProject
                $projects.length | Should -BeGreaterThan 0
                $projects | Where-Object id -eq $script:testProjectId | Should -Not -BeNullOrEmpty
            }
            It "Delete the project <testProjectId> on <ConfigFile.server>" {
                $response = Remove-TSProject -ProjectId $script:testProjectId
                $response | Should -BeOfType String
                $script:testProjectId = $null
            }
            It "Create new project with samples on <ConfigFile.server>" -Skip {
                $projectName = New-Guid
                $response = New-TSProject -Name $projectName
                $response.tsResponse.project.id | Should -BeOfType String
                $script:testProjectId = $response.tsResponse.project.id
                $response = Update-TSProject -ProjectId $script:testProjectId -Name $projectName -PublishSamples $True
            }
        }
    }
}
