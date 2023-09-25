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
        It "Request auth sign-in for <ConfigFile.server>" {
            $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
            $credentials.user.id | Should -BeOfType String
        }
        It "Request switch site to <ConfigFile.switch_site> for <ConfigFile.server>" {
            $credentials = Switch-TSSite -Site $ConfigFile.switch_site
            $credentials.user.id | Should -BeOfType String
        }
        It "Request sign-out for <ConfigFile.server>" {
            $response = Close-TSSignOut
            $response | Should -BeOfType "String"
        }
        It "Request PAT sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.pat_name) {
                Set-ItResult -Skipped
            }
            $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
            $credentials.user.id | Should -BeOfType String
            $response = Close-TSSignOut
            $response | Should -BeOfType "String"
        }
        It "Impersonate user sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.impersonate_user_id) {
                Set-ItResult -Skipped
            }
            $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password -ImpersonateUserId $ConfigFile.impersonate_user_id
            $credentials.user.id | Should -Be $ConfigFile.impersonate_user_id
            $response = Close-TSSignOut
            $response | Should -BeOfType "String"
        }
    }
    Context "Content operations" -Tag Content {
        BeforeAll {
            if ($ConfigFile.pat_name) {
                Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
            } else {
                Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
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
                Switch-TSSite -Site $script:testSite
                Remove-TSSite -SiteId $script:testSiteId
            }
            Close-TSSignOut
        }
        Context "Site operations" -Tag Site {
            It "Create new site on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    $site = Add-TSSite -Name $ConfigFile.test_site_name -ContentUrl $ConfigFile.test_site_contenturl -SiteParams @{
                        adminMode = "ContentOnly"
                        revisionLimit = 20
                    }
                    $site.id | Should -BeOfType String
                    $site.contentUrl | Should -BeOfType String
                    $script:testSiteId = $site.id
                    $script:testSite = $site.contentUrl
                }
            }
            It "Update site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Switch-TSSite -Site $testSite} | Should -Not -Throw
                    $siteNewName = New-Guid
                    $site = Update-TSSite -SiteId $testSiteId -SiteParams @{
                        name = $siteNewName
                        revisionLimit = 10
                    }
                    $site.id | Should -Be $testSiteId
                    $site.contentUrl | Should -Be $testSite
                    $site.name | Should -Be $siteNewName
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
                    {Switch-TSSite -Site $testSite} | Should -Not -Throw
                    $sites = Get-TSSite -Current
                    ($sites | Measure-Object).Count | Should -Be 1
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Delete site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    {Switch-TSSite -Site $testSite} | Should -Not -Throw
                    $response = Remove-TSSite -SiteId $testSiteId
                    $response | Should -BeOfType String
                    $script:testSiteId = $null
                    $script:testSite = $null
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                    } else {
                        Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
                    }
                }
            }
            It "Delete site <testSite> on <ConfigFile.server> asynchronously" {
                if ($ConfigFile.test_site_name) {
                    $tempSiteName = New-Guid # get UUID for site name and content URL
                    $site = Add-TSSite -Name $tempSiteName -ContentUrl $tempSiteName
                    $site.id | Should -BeOfType String
                    $tempSiteId = $site.id
                    {Switch-TSSite -Site $tempSiteName} | Should -Not -Throw
                    $response = Remove-TSSite -SiteId $tempSiteId -BackgroundTask
                    $response | Should -BeOfType String
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                    } else {
                        Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
                    }
                }
            }
        }
        Context "Project operations" -Tag Project {
            It "Create new project on <ConfigFile.server>" {
                $projectName = New-Guid
                $project = Add-TSProject -Name $projectName
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
            }
            It "Update project <testProjectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $project = Update-TSProject -ProjectId $script:testProjectId -Name $projectNewName
                $project.id | Should -Be $script:testProjectId
                $project.name | Should -Be $projectNewName
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
                $project = Add-TSProject -Name $projectNameSamples
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
                $project = Update-TSProject -ProjectId $script:testProjectId -Name $projectNameSamples -PublishSamples
                $project.id | Should -BeOfType String
            }
        }
        Context "User operations" -Tag User {
            It "Add new user on <ConfigFile.server>" {
                if ($ConfigFile.test_username) {
                    $userName = $ConfigFile.test_username
                } else {
                    $userName = New-Guid
                }
                $user = Add-TSUser -Name $userName -SiteRole Unlicensed
                $user.id | Should -BeOfType String
                $script:testUserId = $user.id
            }
            It "Update user <testUserId> on <ConfigFile.server>" {
                $user = Update-TSUser -UserId $script:testUserId -SiteRole Viewer
                $user.siteRole | Should -Be "Viewer"
                if ($ConfigFile.test_password) {
                    $fullName = New-Guid
                    $user = Update-TSUser -UserId $script:testUserId -SiteRole Viewer -FullName $fullName -SecurePassword (ConvertTo-SecureString $ConfigFile.test_password -AsPlainText -Force)
                    $user.siteRole | Should -Be "Viewer"
                    $user.fullName | Should -Be $fullName
                }
            }
            It "Query users on <ConfigFile.server>" {
                $users = Get-TSUser
                ($users | Measure-Object).Count | Should -BeGreaterThan 0
                $users | Where-Object id -eq $script:testUserId | Should -Not -BeNullOrEmpty
                $user = Get-TSUser -UserId $script:testUserId
                $user.id | Should -Be $script:testUserId
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
                $group = Add-TSGroup -Name $groupName -MinimumSiteRole Viewer
                $group.id | Should -BeOfType String
                $script:testGroupId = $group.id
            }
            It "Update group <testGroupId> on <ConfigFile.server>" {
                $groupName = New-Guid
                $group = Update-TSGroup -GroupId $script:testGroupId -Name $groupName
                $group.id | Should -Be $script:testGroupId
                $group.name | Should -Be $groupName
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
                $user = Add-TSUser -Name $userName -SiteRole Unlicensed -AuthSetting "ServerDefault"
                $user.id | Should -BeOfType String
                $script:testUserId = $user.id
                $groupName = New-Guid
                $group = Add-TSGroup -Name $groupName -MinimumSiteRole Viewer -GrantLicenseMode onLogin
                $group.id | Should -BeOfType String
                $script:testGroupId = $group.id
            }
            It "Add user to group on <ConfigFile.server>" {
                $user = Add-TSUserToGroup -UserId $script:testUserId -GroupId $script:testGroupId
                $user.id | Should -Be $script:testUserId
                # $user.siteRole | Should -Be "Viewer" # doesn't work on Tableau Cloud
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
                $workbookConnections = Get-TSWorkbookConnection -WorkbookId $workbookId
                ($workbookConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Query workbooks for current user on <ConfigFile.server>" {
                $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbooks | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId) -IsOwner
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbooks | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
            }
            It "Get workbook connections on <ConfigFile.server>" {
                $workbookId = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty id
                $connections = Get-TSWorkbookConnection -WorkbookId $workbookId
                ($connections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Get workbook revisions on <ConfigFile.server>" {
                $workbookId = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty id
                $revisions = Get-TSWorkbook -WorkbookId $workbookId -Revisions
                ($revisions | Measure-Object).Count | Should -BeGreaterThan 0
                $revisions | Select-Object -First 1 -ExpandProperty revisionNumber | Should -BeGreaterThan 0
            }
            It "Download workbook on <ConfigFile.server>" {
                $workbookId = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty id
                {Export-TSWorkbook -WorkbookId $workbookId -OutFile "Tests/Output/download.twbx"} | Should -Not -Throw
                Test-Path -Path "Tests/Output/download.twbx" | Should -BeTrue
                Remove-Item -Path "Tests/Output/download.twbx"
            }
            It "Download previous workbook revision on <ConfigFile.server>" {
                $downloaded = $false
                Get-TSWorkbook | ForEach-Object { # find at least one workbook with multiple revisions, get the penultimate one
                    if (-Not $downloaded) {
                        $workbookId = $_.id
                        $revisions = Get-TSWorkbook -WorkbookId $workbookId -Revisions
                        if (($revisions | Measure-Object).Count -gt 1) {
                            $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                            # write-error "$workbookId $revision"
                            {Export-TSWorkbook -WorkbookId $workbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"} | Should -Not -Throw
                            Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                            Remove-Item -Path "Tests/Output/download_revision.twbx"
                            $downloaded = $true
                        }
                    }
                }
                if (-Not $downloaded) { # if none revisions downloaded
                    Set-ItResult -Skipped
                }
            }
            It "Download current workbook revision on <ConfigFile.server>" -Skip {
                $workbookId = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty id
                $revision = Get-TSWorkbook -WorkbookId $workbookId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                # write-error "$workbookId $revision"
                {Export-TSWorkbook -WorkbookId $workbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"} | Should -Not -Throw
                Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                Remove-Item -Path "Tests/Output/download_revision.twbx"
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
                $datasourceConnections = Get-TSDatasourceConnection -DatasourceId $datasourceId
                ($datasourceConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Get datasource connections on <ConfigFile.server>" {
                $datasourceId = Get-TSDatasource | Select-Object -First 1 -ExpandProperty id
                $connections = Get-TSDatasourceConnection -DatasourceId $datasourceId
                ($connections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Get datasource revisions on <ConfigFile.server>" {
                $datasourceId = Get-TSDatasource | Select-Object -First 1 -ExpandProperty id
                $revisions = Get-TSDatasource -DatasourceId $datasourceId -Revisions
                ($revisions | Measure-Object).Count | Should -BeGreaterThan 0
                $revisions | Select-Object -First 1 -ExpandProperty revisionNumber | Should -BeGreaterThan 0
            }
            Context "Publish, download, datasource revisions on <ConfigFile.server>" {
                BeforeAll {
                    $project = Add-TSProject -Name (New-Guid)
                    $script:publishProjectId = $project.id
                }
                AfterAll {
                    if ($script:publishProjectId) {
                        Remove-TSProject -ProjectId $script:publishProjectId
                        $script:publishProjectId = $null
                    }
                }
                It "Publish sample datasource on <ConfigFile.server>" {
                    $datasource = Publish-TSDatasource -Name "SampleDS" -InFile "Tests/Assets/Samples/SampleDS.tds" -ProjectId $publishProjectId
                    $datasource.id | Should -BeOfType String
                }
                It "Publish sample datasource on <ConfigFile.server> - rev. 2" {
                    $datasource = Publish-TSDatasource -Name "SampleDS" -InFile "Tests/Assets/Samples/SampleDS.tds" -ProjectId $publishProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                    $script:publishDatasourceId = $datasource.id
                }
                It "Download sample datasource on <ConfigFile.server>" {
                    {Export-TSDatasource -DatasourceId $script:publishDatasourceId -OutFile "Tests/Output/download.tdsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/download.tdsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download.tdsx"
                }
                It "Download & remove previous datasource revision on <ConfigFile.server>" {
                    $revisions = Get-TSDatasource -DatasourceId $script:publishDatasourceId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        {Export-TSDatasource -DatasourceId $script:publishDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download_revision.tdsx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.tdsx"
                        {Remove-TSDatasource -DatasourceId $script:publishDatasourceId -Revision $revision} | Should -Not -Throw
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest datasource revision on <ConfigFile.server>" {
                    $revision = Get-TSDatasource -DatasourceId $script:publishDatasourceId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    {Export-TSDatasource -DatasourceId $script:publishDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/download_revision.tdsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.tdsx"
                }
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
                $results = Get-TSMetadataGraphQL -Query $query
                ($results | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Paginated GraphQL query on <ConfigFile.server>" {
                $query = Get-Content "Tests/Assets/fields-paginated.graphql" | Out-String
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" #-PageSize 100
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 1000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 20000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
            }
        }
    }
}
