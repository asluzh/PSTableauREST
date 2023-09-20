BeforeDiscovery {
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    Import-Module Microsoft.PowerShell.SecretManagement -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
}
BeforeAll {
    . ./Tests/Test.Functions.ps1
}

Describe "Functional Tests for PSTableauREST" -Tag Functional -ForEach $ConfigFiles {
    BeforeAll {
        $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        if ($ConfigFile.username) {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "secure_password" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
        }
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
        It "Impersonate user sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.impersonate_user_id) {
                Set-ItResult -Skipped
            }
            $response = Invoke-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password -ImpersonateUserId $ConfigFile.impersonate_user_id
            $response.tsResponse.credentials.user.id | Should -Be $ConfigFile.impersonate_user_id
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
                Remove-TSProject -ProjectId $script:testProjectId
            }
            if ($script:testUserId) {
                Remove-TSUser -UserId $script:testUserId
            }
            if ($script:testGroupId) {
                Remove-TSGroup -GroupId $script:testGroupId
            }
            if ($script:testSiteId -and $script:testSite) { # Note: this should be the last cleanup step (session is killed by removing the site)
                Invoke-TSSwitchSite -Site $script:testSite
                Remove-TSSite -SiteId $script:testSiteId
            }
            Invoke-TSSignOut
        }
        Context "Site operations" -Tag Site {
            It "Create new site on <ConfigFile.server>" {
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
            It "Update site <testSite> on <ConfigFile.server>" {
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
                    ($sites | Measure-Object).Count | Should -BeGreaterThan 0
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Get current site on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Invoke-TSSwitchSite -Site $testSite} | Should -Not -Throw
                    $sites = Get-TSSite -Current
                    ($sites | Measure-Object).Count | Should -Be 1
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Delete site <testSite> on <ConfigFile.server>" {
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
            It "Delete site <testSite> on <ConfigFile.server> asynchronously" {
                if ($ConfigFile.test_site_name) {
                    $tempSiteName = New-Guid # get UUID for site name and content URL
                    $response = New-TSSite -Name $tempSiteName -ContentUrl $tempSiteName
                    $response.tsResponse.site.id | Should -BeOfType String
                    $tempSiteId = $response.tsResponse.site.id
                    {Invoke-TSSwitchSite -Site $tempSiteName} | Should -Not -Throw
                    $response = Remove-TSSite -SiteId $tempSiteId -BackgroundTask
                    $response | Should -BeOfType String
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
            It "Update project <testProjectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $response = Update-TSProject -ProjectId $script:testProjectId -Name $projectNewName
                $response.tsResponse.project.id | Should -Be $script:testProjectId
                $response.tsResponse.project.name | Should -Be $projectNewName
            }
            It "Query projects on <ConfigFile.server>" {
                $projects = Get-TSProject
                ($projects | Measure-Object).Count | Should -BeGreaterThan 0
                $projects | Where-Object id -eq $script:testProjectId | Should -Not -BeNullOrEmpty
            }
            It "Delete project <testProjectId> on <ConfigFile.server>" {
                $response = Remove-TSProject -ProjectId $script:testProjectId
                $response | Should -BeOfType String
                $script:testProjectId = $null
            }
            It "Create/update new project with samples on <ConfigFile.server>" -Skip {
                $projectNameSamples = New-Guid
                $response = New-TSProject -Name $projectNameSamples
                $response.tsResponse.project.id | Should -BeOfType String
                $script:testProjectId = $response.tsResponse.project.id
                $response = Update-TSProject -ProjectId $script:testProjectId -Name $projectNameSamples -PublishSamples
                $response.tsResponse.project.id | Should -BeOfType String
            }
        }
        Context "User operations" -Tag User {
            It "Add new user on <ConfigFile.server>" {
                if ($ConfigFile.test_username) {
                    $userName = $ConfigFile.test_username
                } else {
                    $userName = New-Guid
                }
                $response = New-TSUser -Name $userName -SiteRole Unlicensed
                $response.tsResponse.user.id | Should -BeOfType String
                $script:testUserId = $response.tsResponse.user.id
            }
            It "Update user <testUserId> on <ConfigFile.server>" {
                $response = Update-TSUser -UserId $script:testUserId -SiteRole Viewer
                $response.tsResponse.user.siteRole | Should -Be "Viewer"
                if ($ConfigFile.test_password) {
                    $fullName = New-Guid
                    $response = Update-TSUser -UserId $script:testUserId -SiteRole Viewer -FullName $fullName -SecurePassword (ConvertTo-SecureString $ConfigFile.test_password -AsPlainText -Force)
                    $response.tsResponse.user.siteRole | Should -Be "Viewer"
                    $response.tsResponse.user.fullName | Should -Be $fullName
                }
            }
            It "Query users on <ConfigFile.server>" {
                $users = Get-TSUser
                ($users | Measure-Object).Count | Should -BeGreaterThan 0
                $users | Where-Object id -eq $script:testUserId | Should -Not -BeNullOrEmpty
                $response = Get-TSUser -UserId $script:testUserId
                $response.id | Should -Be $script:testUserId
            }
            It "Remove user <testUserId> on <ConfigFile.server>" {
                $response = Remove-TSUser -UserId $script:testUserId
                $response | Should -BeOfType String
                $script:testUserId = $null
            }
        }
        Context "Group operations" -Tag Group {
            It "Add new group on <ConfigFile.server>" {
                $groupName = New-Guid
                $response = New-TSGroup -Name $groupName -MinimumSiteRole Viewer
                $response.tsResponse.group.id | Should -BeOfType String
                $script:testGroupId = $response.tsResponse.group.id
            }
            It "Update group <testGroupId> on <ConfigFile.server>" {
                $groupName = New-Guid
                $response = Update-TSGroup -GroupId $script:testGroupId -Name $groupName
                $response.tsResponse.group.id | Should -Be $script:testGroupId
                $response.tsResponse.group.name | Should -Be $groupName
            }
            It "Query groups on <ConfigFile.server>" {
                $groups = Get-TSGroup
                ($groups | Measure-Object).Count | Should -BeGreaterThan 0
                $groups | Where-Object id -eq $script:testGroupId | Should -Not -BeNullOrEmpty
            }
            It "Remove group <testGroupId> on <ConfigFile.server>" {
                $response = Remove-TSGroup -GroupId $script:testGroupId
                $response | Should -BeOfType String
                $script:testGroupId = $null
            }
        }
        Context "User/Group operations" -Tag UserGroup {
            It "Add new user/group on <ConfigFile.server>" {
                if ($ConfigFile.test_username) {
                    $userName = $ConfigFile.test_username
                } else {
                    $userName = New-Guid
                }
                $response = New-TSUser -Name $userName -SiteRole Unlicensed -AuthSetting "ServerDefault"
                $response.tsResponse.user.id | Should -BeOfType String
                $script:testUserId = $response.tsResponse.user.id
                $groupName = New-Guid
                $response = New-TSGroup -Name $groupName -MinimumSiteRole Viewer -GrantLicenseMode onLogin
                $response.tsResponse.group.id | Should -BeOfType String
                $script:testGroupId = $response.tsResponse.group.id
            }
            It "Add user to group on <ConfigFile.server>" {
                $response = Add-TSUserToGroup -UserId $script:testUserId -GroupId $script:testGroupId
                $response.tsResponse.user.id | Should -Be $script:testUserId
                # $response.tsResponse.user.siteRole | Should -Be "Viewer" # doesn't work on Tableau Cloud
            }
            It "Query groups for user on <ConfigFile.server>" {
                $groups = Get-TSGroupsForUser -UserId $script:testUserId
                ($groups | Measure-Object).Count | Should -BeGreaterThan 0
                $groups | Where-Object id -eq $script:testGroupId | Should -Not -BeNullOrEmpty
            }
            It "Query users in group on <ConfigFile.server>" {
                $users = Get-TSUsersInGroup -GroupId $script:testGroupId
                ($users | Measure-Object).Count | Should -BeGreaterThan 0
                $users | Where-Object id -eq $script:testUserId | Should -Not -BeNullOrEmpty
            }
            It "Remove user from group on <ConfigFile.server>" {
                $response = Remove-TSUserFromGroup -UserId $script:testUserId -GroupId $script:testGroupId
                $response | Should -BeOfType String
                $users = Get-TSUsersInGroup -GroupId $script:testGroupId
                ($users | Measure-Object).Count | Should -Be 0
            }
        }
        Context "Workbook operations" -Tag Workbook {
            It "Query workbooks on <ConfigFile.server>" {
                $workbooks = Get-TSWorkbook
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbookId = $workbooks | Select-Object -First 1 -ExpandProperty id
                $workbookId | Should -BeOfType String
                $workbook = Get-TSWorkbook -WorkbookId $workbookId
                $workbook.id | Should -Be $workbookId
            }
            It "Query workbooks for current user on <ConfigFile.server>" {
                $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbooks | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
            }
        }
        Context "Datasource operations" -Tag Datasource {
            It "Query datasources on <ConfigFile.server>" {
                $datasources = Get-TSDatasource
                ($datasources | Measure-Object).Count | Should -BeGreaterThan 0
                $datasourceId = $datasources | Select-Object -First 1 -ExpandProperty id
                $datasourceId | Should -BeOfType String
                $datasource = Get-TSDatasource -DatasourceId $datasourceId
                $datasource.id | Should -Be $datasourceId
            }
         }
        Context "Metadata operations" -Tag Metadata {
            It "Query databases on <ConfigFile.server>" {
                $databases = Get-TSDatabase
                ($databases | Measure-Object).Count | Should -BeGreaterThan 0
                $databaseId = $databases | Select-Object -First 1 -ExpandProperty id
                $databaseId | Should -BeOfType String
                $database = Get-TSDatabase -DatabaseId $databaseId
                $database.id | Should -Be $databaseId
            }
            It "Query tables on <ConfigFile.server>" {
                $tables = Get-TSTable
                ($tables | Measure-Object).Count | Should -BeGreaterThan 0
                $script:tableId = $tables | Select-Object -First 1 -ExpandProperty id
                $script:tableId | Should -BeOfType String
                $table = Get-TSTable -TableId $script:tableId
                $table.id | Should -Be $script:tableId
            }
            It "Query columns in <tableId> on <ConfigFile.server>" {
                $columns = Get-TSTableColumn -TableId $script:tableId
                ($columns | Measure-Object).Count | Should -BeGreaterThan 0
                $columnId = $columns | Select-Object -First 1 -ExpandProperty id
                $columnId | Should -BeOfType String
                $column = Get-TSTableColumn -TableId $script:tableId -ColumnId $columnId
                $column.id | Should -Be $columnId
            }
            It "Simple GraphQL queries on <ConfigFile.server>" {
                $query = Get-Content "Tests/Assets/workbooks.graphql" | Out-String
                $data = Get-TSGraphQL -Query $query
                $data | Should -BeOfType PSCustomObject
                $entity = $data.PSObject.Properties | Select-Object -First 1 -ExpandProperty Name
                ($data.$entity | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Paginated GraphQL query on <ConfigFile.server>" {
                $query = Get-Content "Tests/Assets/fields-paginated.graphql" | Out-String
                $data = Get-TSGraphQL -Query $query -PaginatedEntity "fieldsConnection" #-PageSize 100
                ($data | Measure-Object).Count | Should -BeGreaterThan 100
                $data = Get-TSGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 1000
                ($data | Measure-Object).Count | Should -BeGreaterThan 100
                $data = Get-TSGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 20000
                ($data | Measure-Object).Count | Should -BeGreaterThan 100
            }
        }
    }
}
