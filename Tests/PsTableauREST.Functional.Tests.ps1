BeforeDiscovery {
    Import-Module ./PSTableauREST/PSTableauREST.psm1 -Force
    Import-Module Microsoft.PowerShell.SecretManagement -Force
    $script:ConfigFiles = Get-ChildItem -Path "Tests/Config" -Filter "test_*.json" -Recurse
    $script:DatasourceFiles = Get-ChildItem -Path "Tests/Assets/Datasources" -Recurse
    $script:WorkbookFiles = Get-ChildItem -Path "Tests/Assets/Workbooks" -Recurse
    $script:FlowFiles = Get-ChildItem -Path "Tests/Assets/Flows" -Recurse
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
                    $sites = Get-TSSite -Current -IncludeUsageStatistics
                    ($sites | Measure-Object).Count | Should -Be 1
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
            It "Create/update new project with samples on <ConfigFile.server>" {
                if ($ConfigFile.test_username) {
                    $userName = $ConfigFile.test_username
                } else {
                    $userName = New-Guid
                }
                $user = Add-TSUser -Name $userName -SiteRole Explorer
                $user.id | Should -BeOfType String
                $projectNameSamples = New-Guid
                $project = Add-TSProject -Name $projectNameSamples -OwnerId (Get-TSCurrentUserId) #$user.id
                # Note: testing with a different OwnerId doesn't work with Dev Sandbox on Tableau Cloud
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
                $project = Update-TSProject -ProjectId $testProjectId -Name $projectNameSamples -PublishSamples -OwnerId (Get-TSCurrentUserId)
                $project.id | Should -BeOfType String
                Remove-TSUser -UserId $user.id
            }
            It "Query/remove/add project permissions on <ConfigFile.server>" {
                $permissions = Get-TSContentPermission -ProjectId $testProjectId
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | ForEach-Object {
                    if ($_.group) {
                        $granteeType = 'Group'
                        $granteeId = $_.group.id
                    } else {
                        $granteeType = 'User'
                        $granteeId = $_.user.id
                    }
                    $_.capabilities.capability | ForEach-Object {
                        $capName = $_.name
                        $capMode = $_.mode
                        {Remove-TSContentPermission -ProjectId $testProjectId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode} | Should -Not -Throw
                    }
                }
                $permissions = Get-TSContentPermission -ProjectId $testProjectId
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                $permissionArray = @()
                $capabilitiesHashtable = @{}
                foreach ($cap in 'ProjectLeader','Read','Write') {
                    $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                }
                $permissionArray += @{type="User";id=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                $permissions = Add-TSContentPermission -ProjectId $testProjectId -Permissions $permissionArray
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
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
                It "Get sample workbook id from <ConfigFile.server>" {
                    $workbook = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName","name:eq:Superstore" | Select-Object -First 1
                    $script:sampleWorkbookId = $workbook.id
                    $script:sampleWorkbookName = $workbook.name
                    $script:sampleWorkbookContentUrl = $workbook.contentUrl
                    $sampleWorkbookId | Should -BeOfType String
                }
                It "Get sample workbook by content URL from <ConfigFile.server>" {
                    $workbook = Get-TSWorkbook -ContentUrl $sampleWorkbookContentUrl
                    $workbook.id | Should -Be $script:sampleWorkbookId
                    $workbook.name | Should -Be $script:sampleWorkbookName
                }
                It "Download sample workbook from <ConfigFile.server>" {
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
                It "Add/remove tags for sample workbook on <ConfigFile.server>" {
                    {Add-TSTagsToContent -WorkbookId $sampleWorkbookId -Tags "active","test"} | Should -Not -Throw
                    ((Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 2
                    {Remove-TSTagFromContent -WorkbookId $sampleWorkbookId -Tag "test"} | Should -Not -Throw
                    ((Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 1
                    {Remove-TSTagFromContent -WorkbookId $sampleWorkbookId -Tag "active"} | Should -Not -Throw
                    (Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add workbook permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $permissions.granteeCapabilities | ForEach-Object {
                        if ($_.group) {
                            $granteeType = 'Group'
                            $granteeId = $_.group.id
                        } else {
                            $granteeType = 'User'
                            $granteeId = $_.user.id
                        }
                        $_.capabilities.capability | ForEach-Object {
                            $capName = $_.name
                            $capMode = $_.mode
                            {Remove-TSContentPermission -WorkbookId $sampleWorkbookId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode} | Should -Not -Throw
                        }
                    }
                    $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    $permissionArray = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in 'AddComment','ChangeHierarchy','ChangePermissions','CreateRefreshMetrics','Delete','ExportData','ExportImage','ExportXml','Filter','Read','RunExplainData','ShareView','ViewComments','ViewUnderlyingData','WebAuthoring','Write') {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $permissionArray += @{type="User";id=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -WorkbookId $sampleWorkbookId -Permissions $permissionArray
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
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
                Context "Publish / download sample workbooks on <ConfigFile.server>" -ForEach $WorkbookFiles {
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
                It "Get sample datasource id from <ConfigFile.server>" {
                    $datasource = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    $script:sampleDatasourceId = $datasource.id
                    $script:sampleDatasourceName = $datasource.name
                    $sampleDatasourceId | Should -BeOfType String
                }
                It "Download sample datasource from <ConfigFile.server>" {
                    {Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Tests/Output/$sampleDatasourceName.tdsx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleDatasourceName.tdsx" | Should -BeTrue
                    # Remove-Item -Path "Tests/Output/$sampleDatasourceName.tdsx"
                }
                It "Publish sample datasource on <ConfigFile.server>" {
                    $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile "Tests/Output/$sampleDatasourceName.tdsx" -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                }
                It "Publish sample datasource (chunks) on <ConfigFile.server>" {
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
                It "Add/remove tags for sample datasource on <ConfigFile.server>" {
                    {Add-TSTagsToContent -DatasourceId $sampleDatasourceId -Tags "active","test"} | Should -Not -Throw
                    ((Get-TSDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 2
                    {Remove-TSTagFromContent -DatasourceId $sampleDatasourceId -Tag "test"} | Should -Not -Throw
                    ((Get-TSDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 1
                    {Remove-TSTagFromContent -DatasourceId $sampleDatasourceId -Tag "active"} | Should -Not -Throw
                    (Get-TSDatasource -DatasourceId $sampleDatasourceId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add datasource permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $permissions.granteeCapabilities | ForEach-Object {
                        if ($_.group) {
                            $granteeType = 'Group'
                            $granteeId = $_.group.id
                        } else {
                            $granteeType = 'User'
                            $granteeId = $_.user.id
                        }
                        $_.capabilities.capability | ForEach-Object {
                            $capName = $_.name
                            $capMode = $_.mode
                            {Remove-TSContentPermission -DatasourceId $sampleDatasourceId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode} | Should -Not -Throw
                        }
                    }
                    $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    $permissionArray = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in 'ChangePermissions','Connect','Delete','ExportXml','Filter','Read','Write','SaveAs') {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $permissionArray += @{type="User";id=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -DatasourceId $sampleDatasourceId -Permissions $permissionArray
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
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
                It "Add/remove tags for sample view on <ConfigFile.server>" {
                    {Add-TSTagsToContent -ViewId $sampleViewId -Tags "active","test"} | Should -Not -Throw
                    ((Get-TSView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 2
                    {Remove-TSTagFromContent -ViewId $sampleViewId -Tag "test"} | Should -Not -Throw
                    ((Get-TSView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 1
                    {Remove-TSTagFromContent -ViewId $sampleViewId -Tag "active"} | Should -Not -Throw
                    (Get-TSView -ViewId $sampleViewId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add view permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -ViewId $sampleViewId
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $permissions.granteeCapabilities | ForEach-Object {
                        if ($_.group) {
                            $granteeType = 'Group'
                            $granteeId = $_.group.id
                        } else {
                            $granteeType = 'User'
                            $granteeId = $_.user.id
                        }
                        $_.capabilities.capability | ForEach-Object {
                            $capName = $_.name
                            $capMode = $_.mode
                            {Remove-TSContentPermission -ViewId $sampleViewId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode} | Should -Not -Throw
                        }
                    }
                    $permissions = Get-TSContentPermission -ViewId $sampleViewId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    $permissionArray = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in 'AddComment','ChangePermissions','Delete','ExportData','ExportImage','ExportXml','Filter','Read','ShareView','ViewComments','ViewUnderlyingData','WebAuthoring','Write') {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $permissionArray += @{type="User";id=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -ViewId $sampleViewId -Permissions $permissionArray
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                }
                It "Get/hide/unhide view recommendations on <ConfigFile.server>" -Skip {
                }
            }
            It "Get custom views on <ConfigFile.server>" -Skip {
            }
            It "Update custom view on <ConfigFile.server>" -Skip {
            }
            It "Remove custom view on <ConfigFile.server>" -Skip {
            }
        }
        Context "Flow operations" -Tag Flow {
            Context "Get, publish, download sample flow on <ConfigFile.server>" {
                BeforeAll {
                    $project = Add-TSProject -Name (New-Guid)
                    Update-TSProject -ProjectId $project.id -PublishSamples
                    Start-Sleep -Seconds 2 # small delay is needed to finalize published samples
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($script:samplesProjectId) {
                        Remove-TSProject -ProjectId $script:samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample flow id from <ConfigFile.server>" {
                    $flow = Get-TSFlow -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    $script:sampleflowId = $flow.id
                    $script:sampleFlowName = $flow.name
                    $sampleflowId | Should -BeOfType String
                }
                It "Get flows on <ConfigFile.server>" {
                    $flows = Get-TSFlow
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flowId = $flows | Select-Object -First 1 -ExpandProperty id
                    $flowId | Should -BeOfType String
                    $flow = Get-TSFlow -FlowId $flowId
                    $flow.id | Should -Be $flowId
                    $connections = Get-TSFlowConnection -FlowId $flowId
                    ($connections | Measure-Object).Count | Should -BeGreaterThan 0
                }
                It "Query flows with options on <ConfigFile.server>" {
                    $flowName = Get-TSFlow | Select-Object -First 1 -ExpandProperty name
                    $flows = Get-TSFlow -Filter "name:eq:$flowName" -Sort name:asc -Fields id,name
                    ($flows | Measure-Object).Count | Should -BeGreaterOrEqual 1
                    ($flows | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
                }
                It "Query flows for current user on <ConfigFile.server>" {
                    $flows = Get-TSFlowsForUser -UserId (Get-TSCurrentUserId)
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flows | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                    $flows = Get-TSFlowsForUser -UserId (Get-TSCurrentUserId) -IsOwner
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flows | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                }
                It "Download sample flow from <ConfigFile.server>" {
                    {Export-TSFlow -FlowId $sampleflowId -OutFile "Tests/Output/$sampleFlowName.tflx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/$sampleFlowName.tflx" | Should -BeTrue
                }
                It "Publish sample flow on <ConfigFile.server>" {
                    $flow = Publish-TSFlow -Name $sampleFlowName -InFile "Tests/Output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite
                    $flow.id | Should -BeOfType String
                    $script:sampleFlowId = $flow.id
                }
                It "Publish sample flow (chunks) on <ConfigFile.server>" {
                    $flow = Publish-TSFlow -Name $sampleFlowName -InFile "Tests/Output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $flow.id | Should -BeOfType String
                    $script:sampleFlowId = $flow.id
                }
                It "Download & remove previous flow revision on <ConfigFile.server>" -Skip {
                    $revisions = Get-TSFlow -FlowId $sampleFlowId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        {Export-TSFlow -FlowId $sampleFlowId -Revision $revision -OutFile "Tests/Output/download_revision.tflx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download_revision.tflx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.tflx"
                        {Remove-TSFlow -FlowId $sampleFlowId -Revision $revision} | Should -Not -Throw
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest flow revision on <ConfigFile.server>" -Skip {
                    $revision = Get-TSFlow -FlowId $sampleFlowId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    {Export-TSFlow -FlowId $sampleFlowId -Revision $revision -OutFile "Tests/Output/download_revision.tflx"} | Should -Not -Throw
                    Test-Path -Path "Tests/Output/download_revision.tflx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.tflx"
                }
                It "Add/remove tags for sample flow on <ConfigFile.server>" {
                    {Add-TSTagsToContent -FlowId $sampleFlowId -Tags "active","test"} | Should -Not -Throw
                    ((Get-TSFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 2
                    {Remove-TSTagFromContent -FlowId $sampleFlowId -Tag "test"} | Should -Not -Throw
                    ((Get-TSFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 1
                    {Remove-TSTagFromContent -FlowId $sampleFlowId -Tag "active"} | Should -Not -Throw
                    (Get-TSFlow -FlowId $sampleFlowId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add flow permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                    # remove all permissions for all grantees
                    {Remove-TSContentPermission -FlowId $sampleFlowId -All} | Should -Not -Throw
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'ChangeHierarchy','ChangePermissions','Delete','Execute','ExportXml','Read','Write'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User";granteeId=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -FlowId $sampleFlowId -PermissionTable $allPermissionTable
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # set all possible permissions to Allow for the current user
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, "Allow")
                    }
                    $allPermissionTable += @{granteeType="User";granteeId=(Get-TSCurrentUserId);capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSContentPermission -FlowId $sampleFlowId -PermissionTable $allPermissionTable
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    {Remove-TSContentPermission -FlowId $sampleFlowId -GranteeType User -GranteeId (Get-TSCurrentUserId)} | Should -Not -Throw
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    $permissions = Add-TSContentPermission -FlowId $sampleFlowId -PermissionTable $savedPermissionTable
                    ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                    # remove again each permission/capability one-by-one
                    $permissions.granteeCapabilities | ForEach-Object {
                        if ($_.group) {
                            $granteeType = 'Group'
                            $granteeId = $_.group.id
                        } elseif ($_.user) {
                            $granteeType = 'User'
                            $granteeId = $_.user.id
                        }
                        $_.capabilities.capability | ForEach-Object {
                            $capName = $_.name
                            $capMode = $_.mode
                            {Remove-TSContentPermission -FlowId $sampleFlowId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode} | Should -Not -Throw
                        }
                    }
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                }
                It "Remove sample flow on <ConfigFile.server>" -Skip {
                    {Remove-TSFlow -FlowId $sampleFlowId} | Should -Not -Throw
                }
                It "Publish flow with invalid extension on <ConfigFile.server>" {
                    {Publish-TSFlow -Name "Flow" -InFile "Tests/Assets/Misc/Flow.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish flow with invalid contents on <ConfigFile.server>" {
                    {Publish-TSFlow -Name "invalid" -InFile "Tests/Assets/Misc/invalid.tflx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish and check flow with output steps on <ConfigFile.server>" -Skip {
                    $flow = Publish-TSFlow -Name $sampleFlowName -InFile "Tests/Output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite
                    $flow.id | Should -BeOfType String
                    $outputSteps = Get-TSFlow -FlowId $flow.id -OutputSteps
                    ($outputSteps | Measure-Object).Count | Should -BeGreaterThan 0
                    $outputSteps.id | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                }
                It "Publish flow with connections on <ConfigFile.server>" -Skip {
                    Publish-TSFlow -Name "Flow" -InFile "Tests/Assets/Misc/Flow.txt" -ProjectId $samplesProjectId
                }
                It "Publish flow with credentials on <ConfigFile.server>" -Skip {
                    Publish-TSFlow -Name "Flow" -InFile "Tests/Assets/Misc/Flow.txt" -ProjectId $samplesProjectId
                }
                Context "Publish / download sample flows on <ConfigFile.server>" -ForEach $FlowFiles {
                    BeforeAll {
                        $script:sampleFlowName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleFlowFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server>" {
                        $flow = Publish-TSFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server> (Chunked)" {
                        $flow = Publish-TSFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite -ShowProgress -Chunked
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Download flow ""<sampleFlowName>"" from <ConfigFile.server>" {
                        {Export-TSFlow -FlowId $sampleflowId -OutFile "Tests/Output/download.tflx"} | Should -Not -Throw
                        Test-Path -Path "Tests/Output/download.tflx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download.tflx"
                    }
                }
            }
        }
        Context "Favorite operations" -Tag Favorite {
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
            It "Add sample contents to user favorites on <ConfigFile.server>" {
                {Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -ProjectId $script:samplesProjectId} | Should -Not -Throw
                Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -DatasourceId $_.id} | Should -Not -Throw
                }
                Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $_.id} | Should -Not -Throw
                }
                Get-TSView -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -ViewId $_.id} | Should -Not -Throw
                }
                Get-TSFlow -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -FlowId $_.id} | Should -Not -Throw
                }
            }
            It "Get/reorder user favorites for sample contents on <ConfigFile.server>" {
                $workbooks = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName"
                $workbook_id = $workbooks | Select-Object -First 1 -ExpandProperty id
                $datasources = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName"
                $datasource_id = $datasources | Select-Object -First 1 -ExpandProperty id
                $views = Get-TSView -Filter "projectName:eq:$samplesProjectName"
                $totalCount = $datasources.Length + $workbooks.Length + $views.Length
                $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                ($favorites | Measure-Object).Count | Should -BeGreaterThan $totalCount
                # swap favorites order for first workbook/datasource and sample
                $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $script:samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                if ($workbook_id) {
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeLessThan $pos_project
                    {Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $workbook_id -FavoriteType Workbook -AfterFavoriteId $script:samplesProjectId -AfterFavoriteType Project} | Should -Not -Throw
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $script:samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeGreaterThan $pos_project
                }
                if ($datasource_id) {
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeLessThan $pos_project
                    {Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $datasource_id -FavoriteType Datasource -AfterFavoriteId $script:samplesProjectId -AfterFavoriteType Project} | Should -Not -Throw
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $script:samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeGreaterThan $pos_project
                }
                if ($views -and $views.Length -ge 2) {
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 | Should -BeLessThan $pos_view0
                    {Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $views[1].id -FavoriteType View -AfterFavoriteId $views[0].id -AfterFavoriteType View} | Should -Not -Throw
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1| Should -BeGreaterThan $pos_view0
                }
            }
            It "Remove sample contents from user favorites on <ConfigFile.server>" {
                {Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -ProjectId $script:samplesProjectId} | Should -Not -Throw
                Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -DatasourceId $_.id} | Should -Not -Throw
                }
                Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $_.id} | Should -Not -Throw
                }
                Get-TSView -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -ViewId $_.id} | Should -Not -Throw
                }
                Get-TSFlow -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    {Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -FlowId $_.id} | Should -Not -Throw
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
