BeforeDiscovery {
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    Import-Module Microsoft.PowerShell.SecretManagement -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
    $script:DatasourceFiles = Get-ChildItem -Path "Tests/Assets/Datasources" -Recurse
    $script:WorkbookFiles = Get-ChildItem -Path "Tests/Assets/Workbooks" -Recurse
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
            It "Query projects with options on <ConfigFile.server>" {
                $projectName = Get-TSProject | Where-Object id -eq $script:testProjectId | Select-Object -First 1 -ExpandProperty name
                $projects = Get-TSProject -Filter "name:eq:$projectName" -Sort name:asc -Fields id,name,description
                ($projects | Measure-Object).Count | Should -Be 1
                ($projects | Get-Member -MemberType Property | Measure-Object).Count | Should -Be 3
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
            It "Query users with options on <ConfigFile.server>" {
                $userName = Get-TSUser | Where-Object id -eq $script:testUserId | Select-Object -First 1 -ExpandProperty name
                $users = Get-TSUser -Filter "name:eq:$userName" -Sort name:asc -Fields _all_
                ($users | Measure-Object).Count | Should -Be 1
                ($users | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterThan 5
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
            It "Query groups with options on <ConfigFile.server>" {
                $groupName = Get-TSGroup | Where-Object id -eq $script:testGroupId | Select-Object -First 1 -ExpandProperty name
                $groups = Get-TSGroup -Filter "name:eq:$groupName" -Sort name:asc -Fields id,name
                ($groups | Measure-Object).Count | Should -Be 1
                ($groups | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
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
            It "Get workbooks on <ConfigFile.server>" {
                $workbooks = Get-TSWorkbook
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbookId = $workbooks | Select-Object -First 1 -ExpandProperty id
                $workbookId | Should -BeOfType String
                $workbook = Get-TSWorkbook -WorkbookId $workbookId
                $workbook.id | Should -Be $workbookId
                $workbookConnections = Get-TSWorkbookConnection -WorkbookId $workbookId
                ($workbookConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Query workbooks with options on <ConfigFile.server>" {
                $workbookName = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty name
                $workbooks = Get-TSWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name
                ($workbooks | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($workbooks | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
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
            Context "Publish, download, revisions for sample workbook on <ConfigFile.server>" {
                BeforeAll {
                    $project = Add-TSProject -Name (New-Guid)
                    Update-TSProject -ProjectId $project.id -PublishSamples
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($script:samplesProjectId) {
                        Remove-TSProject -ProjectId $script:samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Download sample workbook from <ConfigFile.server>" {
                    $workbook = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName","name:eq:Superstore" | Select-Object -First 1
                    $script:sampleWorkbookId = $workbook.id
                    $script:sampleWorkbookName = $workbook.name
                    {Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/$sampleWorkbookName.twbx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.twbx" | Should -BeTrue
                    {Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/$sampleWorkbookName.twb" -ExcludeExtract} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.twb" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.twb"
                }
                It "Download sample workbook as PDF from <ConfigFile.server>" {
                    {Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "Tests/Output/$sampleWorkbookName.pdf"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pdf" | Should -BeTrue
                    {Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "Tests/Output/$sampleWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.pdf"
                }
                It "Download sample workbook as PowerPoint from <ConfigFile.server>" {
                    {Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "Tests/Output/$sampleWorkbookName.pptx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pptx" | Should -BeTrue
                    # {Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "Tests/Output/$sampleWorkbookName.pptx" -MaxAge 1} | Should -Not -Throw
                    # Test-Path -Path "Tests/Output/$sampleWorkbookName.pptx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.pptx"
                }
                It "Download sample workbook as PNG from <ConfigFile.server>" {
                    {Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format image -OutFile "Tests/Output/$sampleWorkbookName.png"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.png" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.png"
                }
                It "Publish sample workbook on <ConfigFile.server>" {
                    $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Tests/Output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (chunks) on <ConfigFile.server>" {
                    $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Tests/Output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (hidden views) on <ConfigFile.server>" {
                    $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Tests/Output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (with options) on <ConfigFile.server>" {
                    $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Tests/Output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -ShowTabs -ThumbnailsUserId (Get-TSCurrentUserId)
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Download & remove previous workbook revision on <ConfigFile.server>" {
                    $revisions = Get-TSWorkbook -WorkbookId $sampleWorkbookId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        {Export-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.twbx"
                        {Remove-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision} | Should -Not -Throw
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest workbook revision on <ConfigFile.server>" {
                    $revision = Get-TSWorkbook -WorkbookId $sampleWorkbookId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    {Export-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.twbx"
                }
                It "Publish workbook with invalid extension on <ConfigFile.server>" {
                    {Publish-TSWorkbook -Name "Workbook" -InFile "Tests/Assets/Misc/Workbook.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish workbook with invalid contents on <ConfigFile.server>" {
                    {Publish-TSWorkbook -Name "invalid" -InFile "Tests/Assets/Misc/invalid.twbx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish workbook with connections on <ConfigFile.server>" -Skip {
                    Publish-TSWorkbook -Name "Workbook" -InFile "Tests/Assets/Misc/Workbook.txt" -ProjectId $samplesProjectId
                }
                It "Publish workbook with credentials on <ConfigFile.server>" -Skip {
                    Publish-TSWorkbook -Name "Workbook" -InFile "Tests/Assets/Misc/Workbook.txt" -ProjectId $samplesProjectId
                }
                It "Publish workbook with skip connection check on <ConfigFile.server>" -Skip {
                    Publish-TSWorkbook -Name "Workbook" -InFile "Tests/Assets/Misc/Workbook.txt" -ProjectId $samplesProjectId
                }
                It "Publish workbook as background job on <ConfigFile.server>" -Skip {
                    Publish-TSWorkbook -Name "Workbook" -InFile "Tests/Assets/Misc/Workbook.txt" -ProjectId $samplesProjectId
                }
                Context "Publish / download sample workbooks on <ConfigFile.server>" -ForEach $WorkbookFiles -Skip {
                    BeforeAll {
                        $script:sampleWorkbookName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleWorkbookFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server>" {
                        $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress -SkipConnectionCheck
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server> (Chunked)" {
                        $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress -SkipConnectionCheck -Chunked
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Download workbook ""<sampleWorkbookName>"" from <ConfigFile.server>" {
                        {Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/download.twbx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download.twbx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download.twbx"
                    }
                }
            }
        }
        Context "Datasource operations" -Tag Datasource {
            It "Get datasources on <ConfigFile.server>" {
                $datasources = Get-TSDatasource
                ($datasources | Measure-Object).Count | Should -BeGreaterThan 0
                $datasourceId = $datasources | Select-Object -First 1 -ExpandProperty id
                $datasourceId | Should -BeOfType String
                $datasource = Get-TSDatasource -DatasourceId $datasourceId
                $datasource.id | Should -Be $datasourceId
                $datasourceConnections = Get-TSDatasourceConnection -DatasourceId $datasourceId
                ($datasourceConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Query datasources with options on <ConfigFile.server>" {
                $datasourceName = Get-TSDatasource | Select-Object -First 1 -ExpandProperty name
                $datasources = Get-TSDatasource -Filter "name:eq:$datasourceName" -Sort name:asc -Fields id,name
                ($datasources | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($datasources | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
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
            Context "Publish, download, revisions for sample datasource on <ConfigFile.server>" {
                BeforeAll {
                    $project = Add-TSProject -Name (New-Guid)
                    Update-TSProject -ProjectId $project.id -PublishSamples
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($script:samplesProjectId) {
                        Remove-TSProject -ProjectId $script:samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Download sample datasource from <ConfigFile.server>" {
                    $datasource = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    $script:sampleDatasourceId = $datasource.id
                    $script:sampleDatasourceName = $datasource.name
                    {Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Tests/Output/$sampleDatasourceName.tdsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleDatasourceName.tdsx" | Should -BeTrue
                    # Remove-Item -Path "Tests/Output/$sampleDatasourceName.tdsx"
                }
                It "Publish sample datasource on <ConfigFile.server>" {
                    $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile "Tests/Output/$sampleDatasourceName.tdsx" -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                }
                It "Publish/overwrite sample datasource on <ConfigFile.server> - rev. 2" {
                    $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile "Tests/Output/$sampleDatasourceName.tdsx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $datasource.id | Should -BeOfType String
                    $script:sampleDatasourceId = $datasource.id
                }
                It "Download & remove previous datasource revision on <ConfigFile.server>" {
                    $revisions = Get-TSDatasource -DatasourceId $sampleDatasourceId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        {Export-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download_revision.tdsx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.tdsx"
                        {Remove-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision} | Should -Not -Throw
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest datasource revision on <ConfigFile.server>" {
                    $revision = Get-TSDatasource -DatasourceId $sampleDatasourceId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    {Export-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/download_revision.tdsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.tdsx"
                }
                It "Publish datasource with invalid extension on <ConfigFile.server>" {
                    {Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/Datasource.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish datasource with invalid contents on <ConfigFile.server>" {
                    {Publish-TSDatasource -Name "invalid" -InFile "Tests/Assets/Misc/invalid.tdsx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish datasource with append option on <ConfigFile.server>" {
                    $datasource = Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/append.hyper" -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                    {Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/append.hyper" -ProjectId $samplesProjectId -Overwrite -Append} | Should -Throw
                    $datasource = Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/append.hyper" -ProjectId $samplesProjectId -Append
                    $datasource.id | Should -BeOfType String
                    $datasource = Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/append.hyper" -ProjectId $samplesProjectId -Append -Chunked
                    $datasource.id | Should -BeOfType String
                }
                It "Publish datasource with connections on <ConfigFile.server>" -Skip {
                    Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/Datasource.txt" -ProjectId $samplesProjectId
                }
                It "Publish datasource with credentials on <ConfigFile.server>" -Skip {
                    Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/Datasource.txt" -ProjectId $samplesProjectId
                }
                It "Publish datasource as background job on <ConfigFile.server>" -Skip {
                    Publish-TSDatasource -Name "Datasource" -InFile "Tests/Assets/Misc/Datasource.txt" -ProjectId $samplesProjectId
                }
                Context "Publish / download sample datasources on <ConfigFile.server>" -ForEach $DatasourceFiles {
                    BeforeAll {
                        $script:sampleDatasourceName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleDatasourceFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server>" {
                        $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server> (Chunked)" {
                        $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress -Chunked
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Download datasource ""<sampleDatasourceName>"" from <ConfigFile.server>" {
                        {Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Tests/Output/download.tdsx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download.tdsx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download.tdsx"
                    }
                }
            }
        }
        Context "View operations" -Tag View {
            It "Get views on <ConfigFile.server>" {
                $views = Get-TSView
                ($views | Measure-Object).Count | Should -BeGreaterThan 0
                $viewId = $views | Select-Object -First 1 -ExpandProperty id
                $viewId | Should -BeOfType String
                $view = Get-TSView -ViewId $viewId
                $view.id | Should -Be $viewId
            }
            It "Query views with options on <ConfigFile.server>" {
                $viewName = Get-TSView | Select-Object -First 1 -ExpandProperty name
                $views = Get-TSView -Filter "name:eq:$viewName" -Sort name:asc -Fields id,name
                ($views | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($views | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
            }
            It "Query views for a workbook on <ConfigFile.server>" {
                $workbookId = Get-TSWorkbook | Select-Object -First 1 -ExpandProperty id
                $views = Get-TSView -WorkbookId $workbookId -IncludeUsageStatistics
                ($views | Measure-Object).Count | Should -BeGreaterThan 0
                $views | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                $views | Select-Object -First 1 -ExpandProperty usage | Should -Not -BeNullOrEmpty
            }
            Context "Download views from a sample workbook on <ConfigFile.server>" {
                BeforeAll {
                    $project = Add-TSProject -Name (New-Guid)
                    Update-TSProject -ProjectId $project.id -PublishSamples
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($script:samplesProjectId) {
                        Remove-TSProject -ProjectId $script:samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample view id from <ConfigFile.server>" {
                    $script:sampleViewId = Get-TSView -Filter "workbookName:eq:World Indicators","projectName:eq:$samplesProjectName" | Select-Object -First 1 -ExpandProperty id
                    $sampleViewId | Should -BeOfType String
                    $script:sampleViewName = (Get-TSView -ViewId $sampleViewId).name
                    # write-error $sampleViewId
                }
                It "Download sample view as PDF from <ConfigFile.server>" {
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -PageType 'A5' -PageOrientation 'Landscape' -MaxAge 1} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -VizWidth 500 -VizHeight 300} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.pdf"
                }
                It "Download sample view as PNG from <ConfigFile.server>" {
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -Resolution high} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -Resolution standard} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.png"
                }
                It "Download sample workbook as CSV from <ConfigFile.server>" {
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "Tests/Output/$sampleViewName.csv"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.csv"
                }
                It "Download sample workbook as Excel from <ConfigFile.server>" {
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format excel -OutFile "Tests/Output/$sampleViewName.xlsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.xlsx"
                }
                It "Download sample view with data filters applied from <ConfigFile.server>" {
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -ViewFilters @{Region="Europe"}} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.pdf"
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -ViewFilters @{Region="Africa"}} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.png"
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "Tests/Output/$sampleViewName.csv" -ViewFilters @{"Ease of Business (clusters)"="Low"}} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.csv"
                    {Export-TSViewToFormat -ViewId $sampleViewId -Format excel -OutFile "Tests/Output/$sampleViewName.xlsx" -ViewFilters @{"Country/Region"="Kyrgyzstan"}} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.xlsx"
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
                $query = Get-Content "Tests/Assets/GraphQL/workbooks.graphql" | Out-String
                $results = Get-TSMetadataGraphQL -Query $query
                ($results | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Paginated GraphQL queries on <ConfigFile.server>" {
                $query = Get-Content "Tests/Assets/GraphQL/fields-paginated.graphql" | Out-String
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -ShowProgress
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -ShowProgress -PageSize 500
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -ShowProgress -PageSize 1000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -ShowProgress -PageSize 20000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
            }
        }
    }
}
