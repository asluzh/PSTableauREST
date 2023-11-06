BeforeAll {
    Import-Module ./PSTableauREST -Force
    Import-Module Assert
    . ./Tests/Test.Functions.ps1
    InModuleScope 'PSTableauREST' { $script:VerbosePreference = 'Continue' } # display verbose output
    InModuleScope 'PSTableauREST' { $script:DebugPreference = 'Continue' } # display debug output
    InModuleScope 'PSTableauREST' { $script:ProgressPreference = 'SilentlyContinue' } # suppress progress for upload/download operations
    # see also: https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest
}
BeforeDiscovery {
    $script:ConfigFiles = Get-ChildItem -Path "./Tests/Config" -Filter "test_*.json" | Resolve-Path -Relative
    $script:DatasourceFiles = Get-ChildItem -Path "./Tests/Assets/Datasources" -Recurse | Resolve-Path -Relative
    $script:WorkbookFiles = Get-ChildItem -Path "./Tests/Assets/Workbooks" -Recurse | Resolve-Path -Relative
    $script:FlowFiles = Get-ChildItem -Path "./Tests/Assets/Flows" -Recurse | Resolve-Path -Relative
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
                $null = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
            } else {
                $null = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
            }
        }
        AfterAll {
            if ($script:testProjectId) {
                Remove-TSProject -ProjectId $script:testProjectId
                $script:testProjectId = $null
            }
            if ($script:testUserId) {
                Remove-TSUser -UserId $script:testUserId
                $script:testUserId = $null
            }
            if ($script:testGroupId) {
                Remove-TSGroup -GroupId $script:testGroupId
                $script:testGroupId = $null
            }
            if ($script:testSiteId -and $script:testSite) { # Note: this should be the last cleanup step (session is killed by removing the site)
                Switch-TSSite -Site $script:testSite
                Remove-TSSite -SiteId $script:testSiteId
                $script:testSite = $null
            }
            Close-TSSignOut
        }
        Context "Site operations" -Tag Site {
            It "Create new site on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    $site = Add-TSSite -Name $ConfigFile.test_site_name -ContentUrl $ConfigFile.test_site_contenturl -SiteParams @{
                        adminMode = "ContentOnly"
                        revisionLimit = 20
                    }
                    $site.id | Should -BeOfType String
                    $site.contentUrl | Should -BeOfType String
                    $script:testSiteId = $site.id
                    $script:testSite = $site.contentUrl
                } else {
                    Set-ItResult -Skipped
                }
            }
            It "Update site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    Switch-TSSite -Site $testSite
                    $siteNewName = New-Guid
                    $site = Update-TSSite -SiteId $testSiteId -SiteParams @{
                        name = $siteNewName
                        revisionLimit = 10
                    }
                    $site.id | Should -Be $testSiteId
                    $site.contentUrl | Should -Be $testSite
                    $site.name | Should -Be $siteNewName
                    Update-TSSite -SiteId $testSiteId -SiteParams @{name=$ConfigFile.test_site_name; adminMode="ContentAndUsers"; userQuota="1"}
                } else {
                    Set-ItResult -Skipped
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
                    Switch-TSSite -Site $testSite
                    $sites = Get-TSSite -Current
                    ($sites | Measure-Object).Count | Should -Be 1
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                    $sites = Get-TSSite -Current -IncludeUsageStatistics
                    ($sites | Measure-Object).Count | Should -Be 1
                }
            }
            It "Delete site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    Switch-TSSite -Site $testSite
                    $response = Remove-TSSite -SiteId $testSiteId
                    $response | Should -BeOfType String
                    $script:testSiteId = $null
                    $script:testSite = $null
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                    } else {
                        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
                    }
                    $credentials.user.id | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped
                }
            }
            It "Delete site on <ConfigFile.server> asynchronously" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    $tempSiteName = New-Guid # get UUID for site name and content URL
                    $site = Add-TSSite -Name $tempSiteName -ContentUrl $tempSiteName
                    $site.id | Should -BeOfType String
                    $tempSiteId = $site.id
                    Switch-TSSite -Site $tempSiteName
                    $response = Remove-TSSite -SiteId $tempSiteId -BackgroundTask
                    $response | Should -BeOfType String
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
                    } else {
                        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
                    }
                    $credentials.user.id | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped
                }
            }
        }
        Context "Project operations" -Tag Project {
            It "Create new project on <ConfigFile.server>" {
                $projectName = New-Guid
                $project = Add-TSProject -Name $projectName
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
                # adding another project with the same name - should throw an error
                {Add-TSProject -Name $projectName} | Should -Throw
            }
            It "Update project <testProjectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $project = Update-TSProject -ProjectId $testProjectId -Name $projectNewName
                $project.id | Should -Be $testProjectId
                $project.name | Should -Be $projectNewName
            }
            It "Query projects on <ConfigFile.server>" {
                $projects = Get-TSProject
                ($projects | Measure-Object).Count | Should -BeGreaterThan 0
                $projects | Where-Object id -eq $testProjectId | Should -Not -BeNullOrEmpty
            }
            It "Query projects with options on <ConfigFile.server>" {
                $projectName = Get-TSProject | Where-Object id -eq $testProjectId | Select-Object -First 1 -ExpandProperty name
                $projects = Get-TSProject -Filter "name:eq:$projectName" -Sort name:asc -Fields id,name,description
                ($projects | Measure-Object).Count | Should -Be 1
                ($projects | Get-Member -MemberType Property | Measure-Object).Count | Should -Be 3
            }
            It "Delete project <testProjectId> on <ConfigFile.server>" {
                $response = Remove-TSProject -ProjectId $testProjectId
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
            It "Initial project permissions & default permissions on <ConfigFile.server>" {
                $defaultProject = Get-TSDefaultProject
                $defaultProject.id | Should -BeOfType String
                $defaultProject.name | Should -Be "Default"
                $defProjectPermissionTable = Get-TSContentPermission -ProjectId $defaultProject.id | ConvertTo-TSPermissionTable
                $newProjectPermissionTable = Get-TSContentPermission -ProjectId $testProjectId | ConvertTo-TSPermissionTable
                Assert-Equivalent -Actual $defProjectPermissionTable -Expected $newProjectPermissionTable
                $defProjectPermissions = Get-TSDefaultPermission -ProjectId $defaultProject.id
                $newProjectPermissions = Get-TSDefaultPermission -ProjectId $testProjectId
                Assert-Equivalent -Actual $newProjectPermissions -Expected $defProjectPermissions
                # another approach to deep compare permissions tables: convert to json
                # however this doesn't work with differences in capabilities sort order
                # $defProjectPermissionsJson = $defProjectPermissions | ConvertTo-Json -Compress
                # $newProjectPermissionsJson = $newProjectPermissions | ConvertTo-Json -Compress
                # $newProjectPermissionsJson | Should -Be $defProjectPermissionsJson
            }
            It "Query/remove/add/set project permissions on <ConfigFile.server>" {
                $permissions = Get-TSContentPermission -ProjectId $testProjectId
                $permissions.project.id | Should -Be $testProjectId
                $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                # remove all permissions for all grantees
                Remove-TSContentPermission -ProjectId $testProjectId -All
                $permissions = Get-TSContentPermission -ProjectId $testProjectId
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                # attempt to set permissions with empty capabilities
                $permissions = Set-TSContentPermission -ProjectId $testProjectId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{}}
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                # add all possible permissions (random Allow/Deny) for the current user
                $possibleCap = 'ProjectLeader','Read','Write' #
                $allPermissionTable = @()
                $capabilitiesHashtable = @{}
                foreach ($cap in $possibleCap) {
                    if ($cap -eq 'ProjectLeader') {
                        $capabilitiesHashtable.Add($cap, "Allow") # Deny is not supported
                    } else {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                }
                $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                $permissions = Add-TSContentPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                # set all possible permissions to Allow for the current user
                $allPermissionTable = @()
                $capabilitiesHashtable = @{}
                foreach ($cap in $possibleCap) {
                    $capabilitiesHashtable.Add($cap, "Allow")
                }
                $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                $permissions = Set-TSContentPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                # remove all permissions for the current user
                Remove-TSContentPermission -ProjectId $testProjectId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                $permissions = Get-TSContentPermission -ProjectId $testProjectId
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                # add back initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Add-TSContentPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
                    ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                    # remove again each permission/capability one-by-one
                    if ($permissions.granteeCapabilities) {
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
                                Remove-TSContentPermission -ProjectId $testProjectId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode
                            }
                        }
                    }
                    $permissions = Get-TSContentPermission -ProjectId $testProjectId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                }
                # permissions by template for the current user
                foreach ($pt in 'Denied','None','View','Publish','None') {
                    $permissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$pt}
                    $permissions = Set-TSContentPermission -ProjectId $testProjectId -PermissionTable $permissionTable
                    $permissions.project.id | Should -Be $testProjectId
                    $actualPermissionTable = Get-TSContentPermission -ProjectId $testProjectId | ConvertTo-TSPermissionTable
                    switch ($pt) {
                        'View' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"}}
                        }
                        'Publish' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Write="Allow"}}
                        }
                        'Administer' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Write="Allow"}}
                        }
                        'Denied' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Deny"; Write="Deny"}}
                        }
                        default {
                            $expectedPermissionTable = $null
                        }
                    }
                    Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                }
            }
            It "Query/remove/set default project permissions on <ConfigFile.server>" {
                $savedPermissionTable = Get-TSDefaultPermission -ProjectId $testProjectId
                $wbPermissionTable = Get-TSDefaultPermission -ProjectId $testProjectId -ContentType workbooks
                $wbPermissionTable.Length | Should -BeLessOrEqual $savedPermissionTable.Length
                # remove all default permissions for all grantees
                Remove-TSDefaultPermission -ProjectId $testProjectId -All
                $permissions = Get-TSDefaultPermission -ProjectId $testProjectId
                $permissions.Length | Should -Be 0
                # add all possible permissions (random Allow/Deny) for the current user
                foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                    switch ($ct) {
                        'workbooks' {
                            $possibleCap = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics','ChangeHierarchy','Delete','ChangePermissions'
                        }
                        'datasources' {
                            $possibleCap = 'Read','Connect','ExportXml','Write','SaveAs','ChangeHierarchy','Delete','ChangePermissions'
                        }
                        'flows' {
                            $possibleCap = 'Read','ExportXml','Execute','WebAuthoringForFlows','Write','ChangeHierarchy','Delete','ChangePermissions'
                        }
                        {$_ -in 'dataroles','metrics','lenses'} {
                            $possibleCap = 'Read','Write','ChangeHierarchy','Delete','ChangePermissions'
                        }
                        {$_ -in 'databases','tables'} {
                            $possibleCap = 'Read','Write','ChangeHierarchy','ChangePermissions'
                        }
                    }
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{contentType=$ct; granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSDefaultPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                    $permissions.Length | Should -Be 1 # we add for only one content type, so the output is also only 1
                    ($permissions | Where-Object contentType -eq $ct).capabilities.Count | Should -Be $possibleCap.Length
                }
                # remove all default permissions for one grantee
                Remove-TSDefaultPermission -ProjectId $testProjectId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                $permissions = Get-TSDefaultPermission -ProjectId $testProjectId
                $permissions.Length | Should -Be 0
                # restore initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Set-TSDefaultPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
                    # remove all default permissions for one grantee for the first content type
                    Remove-TSDefaultPermission -ProjectId $testProjectId -GranteeType $permissions[0].granteeType -GranteeId $permissions[0].granteeId -ContentType $permissions[0].contentType
                    $permissions = Get-TSDefaultPermission -ProjectId $testProjectId
                    $permissions.Length | Should -BeLessThan $savedPermissionTable.Length
                }
                # restore initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Set-TSDefaultPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
                    # remove again each permission/capability one-by-one
                    foreach ($permission in $permissions) {
                        if ($permission.capabilities -and $permission.capabilities.Count -gt 0) {
                            $permission.capabilities.GetEnumerator() | ForEach-Object {
                                Remove-TSDefaultPermission -ProjectId $testProjectId -GranteeType $permission.granteeType -GranteeId $permission.granteeId -CapabilityName $_.Key -CapabilityMode $_.Value -ContentType $permission.contentType
                            }
                        }
                    }
                    $permissions = Get-TSDefaultPermission -ProjectId $testProjectId
                    $permissions.Length | Should -Be 0
                }
            }
            It "Set default project permissions with templates on <ConfigFile.server>" {
                Remove-TSDefaultPermission -ProjectId $testProjectId -All
                # apply all possible permission templates for the current user
                foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                    foreach ($tpl in 'View','Explore','Denied','Publish','Administer','None') {
                        $tplPermissionTable = @{contentType=$ct; granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$tpl}
                        $permissions = Set-TSDefaultPermission -ProjectId $testProjectId -PermissionTable $tplPermissionTable
                        if ($tpl -eq 'None') {
                            $permissions.Length | Should -Be 0
                        } else {
                            $permissions.Length | Should -Be 1 # because we set default permissions only for one user, one content type
                        }
                    }
                }
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
                    if ($samplesProjectId) {
                        Remove-TSProject -ProjectId $samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample workbook id from <ConfigFile.server>" {
                    $workbook = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName","name:eq:Superstore" | Select-Object -First 1
                    if (-not $workbook) { # fallback: wait and retry with generic query
                        Start-Sleep -s 3 # small delay is needed to finalize published samples
                        $workbook = Get-TSWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
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
                    Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/$sampleWorkbookName.twbx"
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.twbx" | Should -BeTrue
                    Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/$sampleWorkbookName.twb" -ExcludeExtract
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.twb" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.twb"
                }
                It "Download sample workbook as PDF from <ConfigFile.server>" {
                    Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "Tests/Output/$sampleWorkbookName.pdf"
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pdf" | Should -BeTrue
                    Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "Tests/Output/$sampleWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.pdf"
                }
                It "Download sample workbook as PowerPoint from <ConfigFile.server>" {
                    Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "Tests/Output/$sampleWorkbookName.pptx"
                    Test-Path -Path "Tests/Output/$sampleWorkbookName.pptx" | Should -BeTrue
                    # Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "Tests/Output/$sampleWorkbookName.pptx" -MaxAge 1
                    # Test-Path -Path "Tests/Output/$sampleWorkbookName.pptx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleWorkbookName.pptx"
                }
                It "Download sample workbook as PNG from <ConfigFile.server>" {
                    Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format image -OutFile "Tests/Output/$sampleWorkbookName.png"
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
                    $workbook.showTabs | Should -Be false
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (with options) on <ConfigFile.server>" {
                    if (Get-TSRestApiVersion -ge [version]3.21) {
                        $description = "Testing sample workbook - description 123"
                        $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Tests/Output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -ShowTabs -ThumbnailsUserId (Get-TSCurrentUserId) -Description $description
                        $workbook.id | Should -BeOfType String
                        $workbook.showTabs | Should -Be true
                        $workbook.description | Should -Be $description
                        $script:sampleWorkbookId = $workbook.id
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for this version"
                    }
                }
                It "Update sample workbook (showTabs) on <ConfigFile.server>" {
                    $workbook = Update-TSWorkbook -WorkbookId $sampleWorkbookId -ShowTabs:$false
                    $workbook.showTabs | Should -Be false
                    $workbook = Update-TSWorkbook -WorkbookId $sampleWorkbookId -ShowTabs
                    $workbook.showTabs | Should -Be true
                }
                It "Update sample workbook (description) on <ConfigFile.server>" {
                    if (Get-TSRestApiVersion -ge [version]3.21) {
                        $description = "Testing sample workbook - description 456" # - special symbols äöü©®!?
                        $workbook = Update-TSWorkbook -WorkbookId $sampleWorkbookId -Description $description
                        $workbook.description | Should -Be $description
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for this version"
                    }
                }
                It "Download & remove previous workbook revision on <ConfigFile.server>" {
                    $revisions = Get-TSWorkbook -WorkbookId $sampleWorkbookId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        Export-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"
                        Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.twbx"
                        Remove-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest workbook revision on <ConfigFile.server>" {
                    $revision = Get-TSWorkbook -WorkbookId $sampleWorkbookId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    Export-TSWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"
                    Test-Path -Path "Tests/Output/download_revision.twbx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.twbx"
                }
                It "Add/remove tags for sample workbook on <ConfigFile.server>" {
                    Add-TSTagsToContent -WorkbookId $sampleWorkbookId -Tags "active","test"
                    ((Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TSTagFromContent -WorkbookId $sampleWorkbookId -Tag "test"
                    ((Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TSTagFromContent -WorkbookId $sampleWorkbookId -Tag "active"
                    (Get-TSWorkbook -WorkbookId $sampleWorkbookId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set workbook permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                    # remove all permissions for all grantees
                    Remove-TSContentPermission -WorkbookId $sampleWorkbookId -All
                    $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TSContentPermission -WorkbookId $sampleWorkbookId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $allPermissionTable
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # set all possible permissions to Allow for the current user
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, "Allow")
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $allPermissionTable
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TSContentPermission -WorkbookId $sampleWorkbookId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                    $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TSContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $savedPermissionTable
                        ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                        # remove again each permission/capability one-by-one
                        if ($permissions.granteeCapabilities) {
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
                                    Remove-TSContentPermission -WorkbookId $sampleWorkbookId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode
                                }
                            }
                        }
                        $permissions = Get-TSContentPermission -WorkbookId $sampleWorkbookId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'View','Denied','Explore','Publish','None','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$pt}
                        $permissions = Set-TSContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $permissionTable
                        $permissions.workbook.id | Should -Be $sampleWorkbookId
                        $actualPermissionTable = Get-TSContentPermission -WorkbookId $sampleWorkbookId | ConvertTo-TSPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"; ExportXml="Allow"; Write="Allow"; CreateRefreshMetrics="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"; ExportXml="Allow"; Write="Allow"; CreateRefreshMetrics="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Deny"; Filter="Deny"; ViewComments="Deny"; AddComment="Deny"; ExportImage="Deny"; ExportData="Deny"; ShareView="Deny"; ViewUnderlyingData="Deny"; WebAuthoring="Deny"; RunExplainData="Deny"; ExportXml="Deny"; Write="Deny"; CreateRefreshMetrics="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
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
                Context "Publish / download sample workbooks on <ConfigFile.server>" -Tag WorkbookSamples -ForEach $WorkbookFiles {
                    BeforeAll {
                        $script:sampleWorkbookName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleWorkbookFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server>" {
                        $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -SkipConnectionCheck
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server> (Chunked)" {
                        $workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -SkipConnectionCheck -Chunked
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Download workbook ""<sampleWorkbookName>"" from <ConfigFile.server>" {
                        if ($sampleWorkbookId) {
                            Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Tests/Output/download.twbx"
                            Test-Path -Path "Tests/Output/download.twbx" | Should -BeTrue
                            Remove-Item -Path "Tests/Output/download.twbx"
                        } else {
                            Set-ItResult -Skipped -Because "previous test(s) failed"
                        }
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
                    if ($samplesProjectId) {
                        Remove-TSProject -ProjectId $samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample datasource id from <ConfigFile.server>" {
                    $datasource = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    if (-not $datasource) { # fallback: wait and retry with generic query
                        Start-Sleep -s 3 # small delay is needed to finalize published samples
                        $datasource = Get-TSDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
                    $script:sampleDatasourceId = $datasource.id
                    $script:sampleDatasourceName = $datasource.name
                    $sampleDatasourceId | Should -BeOfType String
                }
                It "Download sample datasource from <ConfigFile.server>" {
                    Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Tests/Output/$sampleDatasourceName.tdsx"
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
                        Export-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"
                        Test-Path -Path "Tests/Output/download_revision.tdsx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.tdsx"
                        Remove-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest datasource revision on <ConfigFile.server>" {
                    $revision = Get-TSDatasource -DatasourceId $sampleDatasourceId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    Export-TSDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"
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
                    Add-TSTagsToContent -DatasourceId $sampleDatasourceId -Tags "active","test"
                    ((Get-TSDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TSTagFromContent -DatasourceId $sampleDatasourceId -Tag "test"
                    ((Get-TSDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TSTagFromContent -DatasourceId $sampleDatasourceId -Tag "active"
                    (Get-TSDatasource -DatasourceId $sampleDatasourceId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set datasource permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                    # remove all permissions for all grantees
                    Remove-TSContentPermission -DatasourceId $sampleDatasourceId -All
                    $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TSContentPermission -DatasourceId $sampleDatasourceId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Connect','ExportXml','Write','SaveAs','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $allPermissionTable
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # set all possible permissions to Allow for the current user
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, "Allow")
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $allPermissionTable
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TSContentPermission -DatasourceId $sampleDatasourceId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                    $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TSContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $savedPermissionTable
                        ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                        # remove again each permission/capability one-by-one
                        if ($permissions.granteeCapabilities) {
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
                                    Remove-TSContentPermission -DatasourceId $sampleDatasourceId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode
                                }
                            }
                        }
                        $permissions = Get-TSContentPermission -DatasourceId $sampleDatasourceId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'None','View','Explore','Denied','Publish','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$pt}
                        $permissions = Set-TSContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $permissionTable
                        $permissions.datasource.id | Should -Be $sampleDatasourceId
                        $actualPermissionTable = Get-TSContentPermission -DatasourceId $sampleDatasourceId | ConvertTo-TSPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"; Write="Allow"; SaveAs="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"; Write="Allow"; SaveAs="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Deny"; Connect="Deny"; ExportXml="Deny"; Write="Deny"; SaveAs="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
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
                Context "Publish / download sample datasources on <ConfigFile.server>"  -Tag DatasourceSamples -ForEach $DatasourceFiles {
                    BeforeAll {
                        $script:sampleDatasourceName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleDatasourceFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server>" {
                        $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server> (Chunked)" {
                        $datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite -Chunked
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Download datasource ""<sampleDatasourceName>"" from <ConfigFile.server>" {
                        Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Tests/Output/download.tdsx"
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
                    if ($samplesProjectId) {
                        Remove-TSProject -ProjectId $samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample view id from <ConfigFile.server>" {
                    $view = Get-TSView -Filter "workbookName:eq:Superstore","projectName:eq:$samplesProjectName" | Select-Object -First 1
                    if (-not $view) { # fallback: wait and retry with generic query
                        Start-Sleep -s 3 # small delay is needed to finalize published samples
                        $workbook = Get-TSWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.name -eq "Superstore"} | Select-Object -First 1
                        $view = Get-TSView | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.workbook.id -eq $workbook.id} | Select-Object -First 1
                    }
                    $script:sampleViewId = $view.id
                    $sampleViewId | Should -BeOfType String
                    $script:sampleViewName = (Get-TSView -ViewId $sampleViewId).name
                }
                It "Download sample view as PDF from <ConfigFile.server>" {
                    Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf"
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -PageType 'A5' -PageOrientation 'Landscape' -MaxAge 1
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -VizWidth 500 -VizHeight 300
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.pdf"
                }
                It "Download sample view as PNG from <ConfigFile.server>" {
                    Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png"
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -Resolution high
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -Resolution standard
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.png"
                }
                It "Download sample workbook as CSV from <ConfigFile.server>" {
                    Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "Tests/Output/$sampleViewName.csv"
                    Test-Path -Path "Tests/Output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.csv"
                }
                It "Download sample workbook as Excel from <ConfigFile.server>" {
                    Export-TSViewToFormat -ViewId $sampleViewId -Format excel -OutFile "Tests/Output/$sampleViewName.xlsx"
                    Test-Path -Path "Tests/Output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.xlsx"
                }
                It "Download sample view with data filters applied from <ConfigFile.server>" {
                    Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "Tests/Output/$sampleViewName.pdf" -ViewFilters @{Region="Europe"}
                    Test-Path -Path "Tests/Output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.pdf"
                    Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "Tests/Output/$sampleViewName.png" -ViewFilters @{Region="Africa"}
                    Test-Path -Path "Tests/Output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.png"
                    Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "Tests/Output/$sampleViewName.csv" -ViewFilters @{"Ease of Business (clusters)"="Low"}
                    Test-Path -Path "Tests/Output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.csv"
                    Export-TSViewToFormat -ViewId $sampleViewId -Format excel -OutFile "Tests/Output/$sampleViewName.xlsx" -ViewFilters @{"Country/Region"="Kyrgyzstan"}
                    Test-Path -Path "Tests/Output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/$sampleViewName.xlsx"
                }
                It "Add/remove tags for sample view on <ConfigFile.server>" {
                    Add-TSTagsToContent -ViewId $sampleViewId -Tags "active","test"
                    ((Get-TSView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TSTagFromContent -ViewId $sampleViewId -Tag "test"
                    ((Get-TSView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TSTagFromContent -ViewId $sampleViewId -Tag "active"
                    (Get-TSView -ViewId $sampleViewId).tags | Should -BeNullOrEmpty
                }
                It "Update sample workbook (showTabs=false) on <ConfigFile.server>" {
                    $workbook = Get-TSWorkbook -Filter "name:eq:Superstore","projectName:eq:$samplesProjectName"
                    if (-not $workbook) { # fallback: wait and retry with generic query
                        $workbook = Get-TSWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.name -eq "Superstore"} | Select-Object -First 1
                    }
                    $workbook.id | Should -BeOfType String
                    $workbook = Update-TSWorkbook -WorkbookId $workbook.id -ShowTabs:$false
                    $workbook.showTabs | Should -Be "false"
                }
                It "Query/remove/add/set view permissions on <ConfigFile.server>" {
                    # note: setting permissions on views only supported on workbooks with ShowTabs=$false
                    $permissions = Get-TSContentPermission -ViewId $sampleViewId
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                    # remove all permissions for all grantees
                    Remove-TSContentPermission -ViewId $sampleViewId -All
                    $permissions = Get-TSContentPermission -ViewId $sampleViewId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TSContentPermission -ViewId $sampleViewId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','Delete','ChangePermissions' # 'ExportXml','Write','ChangeHierarchy','RunExplainData' capabilities are not supported (cf. Workbooks)
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TSContentPermission -ViewId $sampleViewId -PermissionTable $allPermissionTable
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # set all possible permissions to Allow for the current user
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, "Allow")
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSContentPermission -ViewId $sampleViewId -PermissionTable $allPermissionTable
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TSContentPermission -ViewId $sampleViewId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                    $permissions = Get-TSContentPermission -ViewId $sampleViewId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TSContentPermission -ViewId $sampleViewId -PermissionTable $savedPermissionTable
                        ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                        # remove again each permission/capability one-by-one
                        if ($permissions.granteeCapabilities) {
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
                                    Remove-TSContentPermission -ViewId $sampleViewId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode
                                }
                            }
                        }
                        $permissions = Get-TSContentPermission -ViewId $sampleViewId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'Denied','View','None','Explore','Publish','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$pt}
                        $permissions = Set-TSContentPermission -ViewId $sampleViewId -PermissionTable $permissionTable
                        $permissions.view.id | Should -Be $sampleViewId
                        $actualPermissionTable = Get-TSContentPermission -ViewId $sampleViewId | ConvertTo-TSPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Deny"; Filter="Deny"; ViewComments="Deny"; AddComment="Deny"; ExportImage="Deny"; ExportData="Deny"; ShareView="Deny"; ViewUnderlyingData="Deny"; WebAuthoring="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
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
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TSProject -ProjectId $samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Get sample flow id from <ConfigFile.server>" {
                    $flow = Get-TSFlow -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    if (-not $flow) { # fallback: wait and retry with generic query
                        Start-Sleep -s 3 # small delay is needed to finalize published samples
                        $flow = Get-TSFlow | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
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
                    Export-TSFlow -FlowId $sampleflowId -OutFile "Tests/Output/$sampleFlowName.tflx"
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
                        Export-TSFlow -FlowId $sampleFlowId -Revision $revision -OutFile "Tests/Output/download_revision.tflx"
                        Test-Path -Path "Tests/Output/download_revision.tflx" | Should -BeTrue
                        Remove-Item -Path "Tests/Output/download_revision.tflx"
                        Remove-TSFlow -FlowId $sampleFlowId -Revision $revision
                    } else {
                        Set-ItResult -Skipped
                    }
                }
                It "Download latest flow revision on <ConfigFile.server>" -Skip {
                    $revision = Get-TSFlow -FlowId $sampleFlowId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    Export-TSFlow -FlowId $sampleFlowId -Revision $revision -OutFile "Tests/Output/download_revision.tflx"
                    Test-Path -Path "Tests/Output/download_revision.tflx" | Should -BeTrue
                    Remove-Item -Path "Tests/Output/download_revision.tflx"
                }
                It "Add/remove tags for sample flow on <ConfigFile.server>" {
                    Add-TSTagsToContent -FlowId $sampleFlowId -Tags "active","test"
                    ((Get-TSFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TSTagFromContent -FlowId $sampleFlowId -Tag "test"
                    ((Get-TSFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TSTagFromContent -FlowId $sampleFlowId -Tag "active"
                    (Get-TSFlow -FlowId $sampleFlowId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set flow permissions on <ConfigFile.server>" {
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $savedPermissionTable = $permissions | ConvertTo-TSPermissionTable
                    # remove all permissions for all grantees
                    Remove-TSContentPermission -FlowId $sampleFlowId -All
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TSContentPermission -FlowId $sampleFlowId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','ExportXml','Execute','WebAuthoringForFlows','Write','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
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
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TSContentPermission -FlowId $sampleFlowId -PermissionTable $allPermissionTable
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TSContentPermission -FlowId $sampleFlowId -GranteeType User -GranteeId (Get-TSCurrentUserId)
                    $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TSContentPermission -FlowId $sampleFlowId -PermissionTable $savedPermissionTable
                        ($permissions.granteeCapabilities | Measure-Object).Count | Should -Be $savedPermissionTable.Length
                        # remove again each permission/capability one-by-one
                        if ($permissions.granteeCapabilities) {
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
                                    Remove-TSContentPermission -FlowId $sampleFlowId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode
                                }
                            }
                        }
                        $permissions = Get-TSContentPermission -FlowId $sampleFlowId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'View','Explore','None','Publish','Denied','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); template=$pt}
                        $permissions = Set-TSContentPermission -FlowId $sampleFlowId -PermissionTable $permissionTable
                        $permissions.flow.id | Should -Be $sampleFlowId
                        $actualPermissionTable = Get-TSContentPermission -FlowId $sampleFlowId | ConvertTo-TSPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"; Execute="Allow"; Write="Allow"; WebAuthoringForFlows="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"; Execute="Allow"; Write="Allow"; WebAuthoringForFlows="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Deny"; ExportXml="Deny"; Execute="Deny"; Write="Deny"; WebAuthoringForFlows="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
                }
                It "Remove sample flow on <ConfigFile.server>" -Skip {
                    Remove-TSFlow -FlowId $sampleFlowId
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
                Context "Publish / download sample flows on <ConfigFile.server>" -Tag FlowSamples -ForEach $FlowFiles {
                    BeforeAll {
                        $script:sampleFlowName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleFlowFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server>" {
                        $flow = Publish-TSFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server> (Chunked)" {
                        $flow = Publish-TSFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite -Chunked
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Download flow ""<sampleFlowName>"" from <ConfigFile.server>" {
                        Export-TSFlow -FlowId $sampleflowId -OutFile "Tests/Output/download.tflx"
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
                if ($samplesProjectId) {
                    Remove-TSProject -ProjectId $samplesProjectId
                    $script:samplesProjectId = $null
                }
            }
            It "Add sample contents to user favorites on <ConfigFile.server>" {
                Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -ProjectId $samplesProjectId
                $workbooks = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName"
                if (-not $workbooks) { # fallback: wait and retry with generic query
                    Start-Sleep -s 3 # small delay is needed to finalize published samples
                    $workbooks = Get-TSWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $workbooks | ForEach-Object {
                    Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $_.id
                }
                $datasources = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName"
                if (-not $datasources) { # fallback: wait and retry with generic query
                    $datasources = Get-TSDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $datasources | ForEach-Object {
                    Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -DatasourceId $_.id
                }
                $views = Get-TSView -Filter "projectName:eq:$samplesProjectName"
                if (-not $views) { # fallback: wait and retry with generic query
                    $views = Get-TSView | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $views | ForEach-Object {
                    Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -ViewId $_.id
                }
                $flows = Get-TSFlow -Filter "projectName:eq:$samplesProjectName"
                if (-not $flows) { # fallback: wait and retry with generic query
                    $flows = Get-TSFlow | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $flows | ForEach-Object {
                    Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -FlowId $_.id
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
                $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                if ($workbook_id) {
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeLessThan $pos_project
                    Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $workbook_id -FavoriteType Workbook -AfterFavoriteId $samplesProjectId -AfterFavoriteType Project
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeGreaterThan $pos_project
                }
                if ($datasource_id) {
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeLessThan $pos_project
                    Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $datasource_id -FavoriteType Datasource -AfterFavoriteId $samplesProjectId -AfterFavoriteType Project
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeGreaterThan $pos_project
                }
                if ($views -and $views.Length -ge 2) {
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 | Should -BeLessThan $pos_view0
                    Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $views[1].id -FavoriteType View -AfterFavoriteId $views[0].id -AfterFavoriteType View
                    $favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1| Should -BeGreaterThan $pos_view0
                }
            }
            It "Remove sample contents from user favorites on <ConfigFile.server>" {
                Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -ProjectId $samplesProjectId
                Get-TSDatasource -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -DatasourceId $_.id
                }
                Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $_.id
                }
                Get-TSView -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -ViewId $_.id
                }
                Get-TSFlow -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -FlowId $_.id
                }
            }
        }
        Context "Schedule operations" -Tag Schedule {
            It "Add new schedule on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $scheduleName = New-Guid
                    $schedule = Add-TSSchedule -Name $scheduleName -Type Extract -Frequency Daily -StartTime "11:30:00"
                    $schedule.id | Should -BeOfType String
                    $script:testScheduleId = $schedule.id
                } else {
                    Set-ItResult -Skipped
                }
            }
            It "Update schedule <testScheduleId> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $testScheduleId) {
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -State Suspended -Priority 10 -Frequency Daily -StartTime "13:45:00"
                    $schedule.state | Should -Be "Suspended"
                    $schedule.priority | Should -Be 10
                    $schedule.frequencyDetails.start | Should -Be "13:45:00"
                    $scheduleNewName = New-Guid
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Name $scheduleNewName -State Active -ExecutionOrder Serial
                    $schedule.state | Should -Be "Active"
                    $schedule.executionOrder | Should -Be "Serial"
                    $schedule.name | Should -Be $scheduleNewName
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "16:00:00" -IntervalHours 1
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.start | Should -Be "12:00:00"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "1"
                    $schedule.frequencyDetails.end | Should -Be "16:00:00"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "18:00:00" -IntervalHours 2
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "2"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 4
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "4"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 6
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "6"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 8
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "8"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "22:00:00" -IntervalHours 12
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "12"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "14:00:00" -EndTime "15:30:00" -IntervalMinutes 30
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.start | Should -Be "14:00:00"
                    $schedule.frequencyDetails.intervals.interval.minutes | Should -Be "30"
                    $schedule.frequencyDetails.end | Should -Be "15:30:00"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Daily -StartTime "14:30:00" -EndTime "15:00:00" -IntervalMinutes 15
                    $schedule.frequency | Should -Be "Daily"
                    $schedule.frequencyDetails.start | Should -Be "14:30:00"
                    $schedule.frequencyDetails.end | Should -BeNullOrEmpty
                    $schedule.frequencyDetails.intervals.interval.minutes | Should -BeNullOrEmpty
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Weekly -StartTime "10:00:00" -IntervalWeekdays Sunday
                    $schedule.frequency | Should -Be "Weekly"
                    $schedule.frequencyDetails.start | Should -Be "10:00:00"
                    $schedule.frequencyDetails.intervals.interval | Should -HaveCount 1
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Be "Sunday"
                    $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Weekly -StartTime "10:00:00" -IntervalWeekdays Monday,Wednesday
                    $schedule.frequency | Should -Be "Weekly"
                    $schedule.frequencyDetails.intervals.interval | Should -HaveCount 2
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Contain "Monday"
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Contain "Wednesday"
                    # note: updating monthly schedule via REST API doesn't seem to work
                    # $schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3
                    # $schedule.frequency | Should -Be "Monthly"
                    # $schedule.frequencyDetails.start | Should -Be "08:00:00"
                    # $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "3"
                } else {
                    Set-ItResult -Skipped
                }
            }
            It "Query schedules on <ConfigFile.server>" {
                $schedules = Get-TSSchedule
                ($schedules | Measure-Object).Count | Should -BeGreaterThan 0
                if ($testScheduleId) {
                    $schedules | Where-Object id -eq $testScheduleId | Should -Not -BeNullOrEmpty
                    $schedule = Get-TSSchedule -ScheduleId $testScheduleId
                    $schedule.id | Should -Be $testScheduleId
                } else {
                    $firstScheduleId = $schedules | Select-Object -First 1 -ExpandProperty id
                    $schedule = Get-TSSchedule -ScheduleId $firstScheduleId
                    $schedule.id | Should -Be $firstScheduleId
                }
            }
            It "Query extract refresh tasks on <ConfigFile.server>" {
                $extractScheduleId = Get-TSSchedule | Where-Object type -eq "Extract" | Select-Object -First 1 -ExpandProperty id
                (Get-TSExtractRefreshTasksInSchedule -ScheduleId $extractScheduleId | Measure-Object).Count | Should -BeGreaterOrEqual 0
            }
            It "Remove schedule <testScheduleId> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $testScheduleId) {
                    $response = Remove-TSSchedule -ScheduleId $testScheduleId
                    $response | Should -BeOfType String
                    $script:testScheduleId = $null
                } else {
                    Set-ItResult -Skipped
                }
            }
            It "Add/remove monthly schedule on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $schedule = Add-TSSchedule -Name (New-Guid) -Type Extract -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3
                    $schedule.frequency | Should -Be "Monthly"
                    $schedule.state | Should -Be "Active"
                    $schedule.type | Should -Be "Extract"
                    $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "3"
                    $response = Remove-TSSchedule -ScheduleId $schedule.id
                    $response | Should -BeOfType String
                    $schedule = Add-TSSchedule -Name (New-Guid) -Type Subscription -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 0
                    $schedule.frequency | Should -Be "Monthly"
                    $schedule.state | Should -Be "Active"
                    $schedule.type | Should -Be "Subscription"
                    $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "LastDay"
                    $response = Remove-TSSchedule -ScheduleId $schedule.id
                    $response | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped
                }
            }
            Context "Sample contents for schedule operations" {
                BeforeAll {
                    if (-Not $ConfigFile.tableau_cloud) {
                        $project = Add-TSProject -Name (New-Guid)
                        Update-TSProject -ProjectId $project.id -PublishSamples
                        $script:samplesProjectId = $project.id
                        $script:samplesProjectName = $project.name
                    }
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TSProject -ProjectId $samplesProjectId
                        $script:samplesProjectId = $null
                    }
                }
                It "Add extract refresh tasks into a schedule on <ConfigFile.server>" {
                    if (-Not $ConfigFile.tableau_cloud) {
                        $extractScheduleId = Get-TSSchedule | Where-Object type -eq "Extract" | Select-Object -First 1 -ExpandProperty id
                        $workbooks = Get-TSWorkbook -Filter "projectName:eq:$samplesProjectName"
                        if (-not $workbooks) { # fallback: wait and retry with generic query
                            $workbooks = Get-TSWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                        }
                        $workbooks | ForEach-Object {
                            Add-TSContentToSchedule -ScheduleId $extractScheduleId -WorkbookId $_.id
                        }
                        $datasources = Get-TSDatasource -Filter "projectName:eq:$samplesProjectName"
                        if (-not $datasources) { # fallback: wait and retry with generic query
                            $datasources = Get-TSDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                        }
                        $datasources | ForEach-Object {
                            Add-TSContentToSchedule -ScheduleId $extractScheduleId -DatasourceId $_.id
                        }
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for Tableau Cloud"
                    }
                    (Get-TSExtractRefreshTasksInSchedule -ScheduleId $extractScheduleId | Measure-Object).Count | Should -BeGreaterThan 0
                }
            }
            It "Add run flow tasks into a schedule on <ConfigFile.server>" {
                $runFlowScheduleId = Get-TSSchedule | Where-Object type -eq "Flow" | Select-Object -First 1 -ExpandProperty id
                Write-Warning $runFlowScheduleId
                $flows = Get-TSFlow -Filter "projectName:eq:$samplesProjectName"
                if (-not $flows) { # fallback: wait and retry with generic query
                    Start-Sleep -s 3 # small delay is needed to finalize published samples
                    $flows = Get-TSFlow | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $flows | ForEach-Object {
                    Add-TSContentToSchedule -ScheduleId $runFlowScheduleId -FlowId $_.id
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
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection"
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 500
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 1000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
                $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 20000
                ($results | Measure-Object).Count | Should -BeGreaterThan 100
            }
        }
    }
}
