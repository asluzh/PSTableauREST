BeforeAll {
    # Requires -Modules Assert
    # Import-Module Assert
    Import-Module ./PSTableauREST -Force
    . ./scripts/SecretStore.Functions.ps1
    # InModuleScope 'PSTableauREST' { $script:VerbosePreference = 'Continue' } # display verbose output of module functions
    $script:VerbosePreference = 'Continue' # display verbose output of the tests
    InModuleScope 'PSTableauREST' { $script:DebugPreference = 'Continue' } # display debug output of the module
    # InModuleScope 'PSTableauREST' { $script:ProgressPreference = 'SilentlyContinue' } # suppress progress for upload/download operations
    # see also: https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest
}
BeforeDiscovery {
    $script:ConfigFiles = Get-ChildItem -Path "./tests/config" -Filter "test_*.json" | Resolve-Path -Relative
    $script:DatasourceFiles = Get-ChildItem -Path "./tests/assets/Datasources" -Recurse | Resolve-Path -Relative
    $script:WorkbookFiles = Get-ChildItem -Path "./tests/assets/Workbooks" -Recurse | Resolve-Path -Relative
    $script:FlowFiles = Get-ChildItem -Path "./tests/assets/Flows" -Recurse | Resolve-Path -Relative
}

Describe "Integration Tests for PSTableauREST" -Tag Integration -ForEach $ConfigFiles {
    BeforeAll {
        $script:ConfigFile = Get-Content $_ | ConvertFrom-Json
        if ($ConfigFile.username) {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "credential" -Value (New-Object System.Management.Automation.PSCredential($ConfigFile.username, (Get-SecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)))
        }
        if ($ConfigFile.pat_name) {
            $ConfigFile | Add-Member -MemberType NoteProperty -Name "pat_credential" -Value (New-Object System.Management.Automation.PSCredential($ConfigFile.pat_name, (Get-SecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.pat_name)))
        }
    }
    Context "Auth operations" -Tag Auth {
        It "Request auth sign-in for <ConfigFile.server>" {
            $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.credential
            $response.user.id | Should -BeOfType String
        }
        It "Request switch site to <ConfigFile.switch_site> for <ConfigFile.server>" {
            $response = Switch-TableauSite -Site $ConfigFile.switch_site
            $response.user.id | Should -BeOfType String
        }
        It "Request sign-out for <ConfigFile.server>" {
            $response = Disconnect-TableauServer
            $response | Should -BeOfType "String"
        }
        It "Request PAT sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.pat_name) {
                Set-ItResult -Skipped -Because "PAT not provided"
            }
            $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.pat_credential -PersonalAccessToken
            $response.user.id | Should -BeOfType String
            $response = Disconnect-TableauServer
            $response | Should -BeOfType "String"
        }
        It "Impersonate user sign-in for <ConfigFile.server>" {
            if (-not $ConfigFile.impersonate_user_id) {
                Set-ItResult -Skipped -Because "impersonate user ID not provided"
            }
            $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.credential -ImpersonateUserId $ConfigFile.impersonate_user_id
            $response.user.id | Should -Be $ConfigFile.impersonate_user_id
            $response = Disconnect-TableauServer
            $response | Should -BeOfType "String"
        }
    }
    Context "Logged-in operations" -Tag LoggedIn {
        BeforeAll {
            if ($ConfigFile.pat_name) {
                Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.pat_credential -PersonalAccessToken | Out-Null
            } else {
                Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.credential | Out-Null
            }
        }
        AfterAll {
            if ($script:testProjectId) {
                Remove-TableauProject -ProjectId $script:testProjectId | Out-Null
                $script:testProjectId = $null
            }
            if ($script:testUserId) {
                Remove-TableauUser -UserId $script:testUserId | Out-Null
                $script:testUserId = $null
            }
            if ($script:testGroupId) {
                Remove-TableauGroup -GroupId $script:testGroupId | Out-Null
                $script:testGroupId = $null
            }
            if ($script:testSiteId -and $script:testSite) { # Note: this should be the last cleanup step (session is killed by removing the site)
                Switch-TableauSite -Site $script:testSite | Out-Null
                Remove-TableauSite -SiteId $script:testSiteId | Out-Null
                $script:testSite = $null
            }
            Disconnect-TableauServer | Out-Null
        }
        Context "Server operations" -Tag Server {
            It "Get server info on <ConfigFile.server>" {
                $serverInfo = Get-TableauServerInfo
                $serverInfo.productVersion | Should -Not -BeNullOrEmpty
                $serverInfo.restApiVersion | Should -Not -BeNullOrEmpty
            }
            It "Get current session on <ConfigFile.server>" {
                $session = Get-TableauSession
                $session | Should -Not -BeNullOrEmpty
                $session.site | Should -Not -BeNullOrEmpty
                $session.user | Should -Not -BeNullOrEmpty
            }
            It "List AD Domains on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $domains = Get-TableauActiveDirectoryDomain
                    $domains.id | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
        }
        Context "Tableau Dashboard extensions operations" -Tag Extension {
            It "Get Tableau extensions setting (server) on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $settings = Get-TableauServerSettingsExtension
                    $settings | Should -Not -BeNullOrEmpty
                    if ($settings.GetType().Name -eq 'XmlElement') {
                        $settings.extensionsGloballyEnabled | Should -BeOfType String
                        $script:ServerExtensionsGloballyEnabled = $settings.extensionsGloballyEnabled
                    } else {
                        Write-Warning ("Older Extension Settings API detected (API: {0})" -f (Get-TableauRestVersion))
                        $settings.extensions_enabled | Should -BeOfType Boolean
                        $script:ServerExtensionsSettings = $settings
                    }
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Update Tableau extensions setting (server) on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $script:ServerExtensionsGloballyEnabled) {
                    $settings = Set-TableauServerSettingsExtension -Enabled true -BlockList 'https://test123.com'
                    $settings | Should -Not -BeNullOrEmpty
                    $settings.extensionsGloballyEnabled | Should -Be true
                    $settings = Set-TableauServerSettingsExtension -Enabled $script:ServerExtensionsGloballyEnabled
                    $script:ServerExtensionsGloballyEnabled = $null
                } elseif ($ConfigFile.server_admin -and $script:ServerExtensionsSettings) {
                    Write-Warning ("Older Extension Settings API detected (API: {0})" -f (Get-TableauRestVersion))
                    $settings = Set-TableauServerSettingsExtension -Enabled true #-BlockListLegacyAPI 'https://test123.com'
                    $settings | Should -Not -BeNullOrEmpty
                    $settings.extensions_enabled | Should -BeTrue
                    $settings = Set-TableauServerSettingsExtension -Enabled $script:ServerExtensionsSettings.extensions_enabled -BlockListLegacyAPI $script:ServerExtensionsSettings.block_list_items
                    $script:ServerExtensionsSettings = $null
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Get Tableau extensions setting (site) on <ConfigFile.server>" {
                $settings = Get-TableauSiteSettingsExtension
                $settings | Should -Not -BeNullOrEmpty
                if ($settings.GetType().Name -eq 'XmlElement') {
                    $settings.extensionsEnabled | Should -BeOfType String
                    $settings.useDefaultSetting | Should -BeOfType String
                    $script:SiteExtensionsEnabled = $settings.extensionsEnabled
                    $script:SiteAllowSandboxed = $settings.useDefaultSetting
                    $script:SiteSafeList = @()
                    foreach ($safeext in $settings.safeList) {
                        $ht = @{}
                        $safeext.ChildNodes | ForEach-Object { $ht[$_.Name] = $_.InnerText }
                        $script:SiteSafeList += $ht
                    }
                } else {
                    Write-Warning ("Older Extension Settings API detected (API: {0})" -f (Get-TableauRestVersion))
                    $settings.extensions_enabled | Should -BeOfType Boolean
                    $settings.allow_sandboxed | Should -BeOfType Boolean
                    $script:SiteExtensionsSettings = $settings
                }
            }
            It "Update Tableau extensions setting (site) on <ConfigFile.server>" {
                if ($script:SiteExtensionsEnabled) {
                    $settings = Set-TableauSiteSettingsExtension -Enabled true -AllowSandboxed false -SafeList @{url='https://tableau.com';fullDataAllowed='false';promptNeeded='true'}
                    # note: AllowSandboxed=true seems to be ignored by the API 3.22
                    $settings | Should -Not -BeNullOrEmpty
                    $settings.extensionsEnabled | Should -Be true
                    $settings.useDefaultSetting | Should -Be false
                    $settings = Set-TableauSiteSettingsExtension -Enabled $script:SiteExtensionsEnabled -AllowSandboxed $script:SiteAllowSandboxed -SafeList $script:SiteSafeList
                    $script:SiteExtensionsEnabled = $null
                } elseif ($script:SiteExtensionsSettings) {
                    Write-Warning ("Older Extension Settings API detected (API: {0})" -f (Get-TableauRestVersion))
                    $settings = Set-TableauSiteSettingsExtension -Enabled true -AllowSandboxed false #-SafeListLegacyAPI @{url='https://tableau.com';fullDataAllowed='false';promptNeeded='true'}
                    $settings | Should -Not -BeNullOrEmpty
                    $settings.extensions_enabled | Should -BeTrue
                    $settings.allow_sandboxed | Should -BeFalse
                    $settings = Set-TableauSiteSettingsExtension -Enabled $script:SiteExtensionsEnabled -AllowSandboxed $script:SiteAllowSandboxed -SafeListLegacyAPI $script:SiteExtensionsSettings.safe_list_items
                    $script:SiteExtensionsSettings = $null
                } else {
                    Set-ItResult -Skipped -Because "Site extension settings were not saved in the previous test"
                }
            }
        }
        Context "Tableau analytics extensions operations" -Tag Analytics {
            It "Get Tableau analytics extensions state (server) on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $enabled = Get-TableauAnalyticsExtensionState -Scope Server
                    $enabled | Should -BeOfType String
                    $script:ServerAnalyticsExtensionsState = $enabled
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Get Tableau analytics extensions state (site) on <ConfigFile.server>" {
                $enabled = Get-TableauAnalyticsExtensionState -Scope Site
                $enabled | Should -BeOfType String
                $script:SiteAnalyticsExtensionsState = $enabled
            }
            It "Enable Tableau extensions setting (server) on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $script:ServerAnalyticsExtensionsState) {
                    $enabled = Set-TableauAnalyticsExtensionState -Scope Server -Enabled true
                    $enabled | Should -Be true
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Enable Tableau extensions setting (site) on <ConfigFile.server>" {
                if ($script:SiteAnalyticsExtensionsState) {
                    $enabled = Set-TableauAnalyticsExtensionState -Scope Site -Enabled true
                    $enabled | Should -Be true
                } else {
                    Set-ItResult -Skipped -Because "Site analytics extension settings were not saved in the previous test"
                }
            }
            It "Add dummy Tableau analytics extension on <ConfigFile.server>" {
                $response = New-TableauAnalyticsExtension -Name "Analytics Extension Test" -Type GENERIC_API -Hostname "google.com" -Port 443 -AuthRequired -SslEnabled -Username test -SecurePassword (ConvertTo-SecureString "test" -AsPlainText -Force)
                $response | Should -Not -BeNullOrEmpty
                $response.connection_luid | Should -Not -BeNullOrEmpty
                $script:SiteAnalyticsExtensionDummy = $response.connection_luid
            }
            It "List/Get Tableau extensions setting (site) on <ConfigFile.server>" {
                $settings = Get-TableauAnalyticsExtension
                $settings | Should -Not -BeNullOrEmpty
                $conn = $settings | Select-Object -First 1
                $conn.connection_luid | Should -Not -BeNullOrEmpty
                $details = Get-TableauAnalyticsExtension -ConnectionId $conn.connection_luid
                $details | Should -Not -BeNullOrEmpty
            }
            It "Update dummy Tableau analytics extension on <ConfigFile.server>" {
                if ($script:SiteAnalyticsExtensionDummy) {
                    $response = Set-TableauAnalyticsExtension -ConnectionId $script:SiteAnalyticsExtensionDummy -Name "Test 2" -Type TABPY -Hostname "python.org" -Port 443 -AuthRequired -SslEnabled -Username test2 -SecurePassword (ConvertTo-SecureString "test2" -AsPlainText -Force)
                    $response | Should -Not -BeNullOrEmpty
                    $response.connection_luid | Should -Not -BeNullOrEmpty
                } else {
                    Set-ItResult -Skipped -Because "Site analytics extension dummy was not added in the previous test"
                }
            }
            It "Remove dummy Tableau analytics extensions on <ConfigFile.server>" {
                if ($script:SiteAnalyticsExtensionDummy) {
                    $details = Get-TableauAnalyticsExtension -ConnectionId $script:SiteAnalyticsExtensionDummy
                    $details | Should -Not -BeNullOrEmpty
                    {Remove-TableauAnalyticsExtension -ConnectionId $script:SiteAnalyticsExtensionDummy} | Should -Not -Throw
                } else {
                    Set-ItResult -Skipped -Because "Site analytics extension dummy was not added in the previous test"
                }
                $script:SiteAnalyticsExtensionConn = $null
            }
            It "Restore Tableau extensions setting (server) on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $script:ServerAnalyticsExtensionsState) {
                    Set-TableauAnalyticsExtensionState -Scope Server -Enabled $script:ServerAnalyticsExtensionsState | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Restore Tableau extensions setting (site) on <ConfigFile.server>" {
                if ($script:SiteAnalyticsExtensionsState) {
                    Set-TableauAnalyticsExtensionState -Scope Site -Enabled $script:SiteAnalyticsExtensionsState | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Site analytics extension settings were not saved in the previous test"
                }
            }
        }
        Context "Tableau connected apps operations" -Tag ConnectedApp {
            It "Add dummy Tableau connected app on <ConfigFile.server>" {
                $app = New-TableauConnectedApp -Name "Connected App Test"
                $app | Should -Not -BeNullOrEmpty
                $app.clientId | Should -Not -BeNullOrEmpty
                $script:ConnectedAppDummy = $app.clientId
            }
            It "List/get Tableau connected apps on <ConfigFile.server>" {
                $apps = Get-TableauConnectedApp
                $apps | Should -Not -BeNullOrEmpty
                $app = $apps | Select-Object -First 1
                $app.clientId | Should -Not -BeNullOrEmpty
                $app = Get-TableauConnectedApp -ClientId $app.clientId
                $app | Should -Not -BeNullOrEmpty
                $app.clientId | Should -Not -BeNullOrEmpty
            }
            It "Update dummy Tableau connected app on <ConfigFile.server>" {
                if ($script:ConnectedAppDummy) {
                    $app = Set-TableauConnectedApp -ClientId $script:ConnectedAppDummy -Name "Test 2" -Enabled true
                    $app | Should -Not -BeNullOrEmpty
                    $app.clientId | Should -Not -BeNullOrEmpty
                } else {
                    Set-ItResult -Skipped -Because "Connected app dummy was not added in the previous test"
                }
            }
            It "Generate/get/remove Tableau connected app secret on <ConfigFile.server>" {
                if ($script:ConnectedAppDummy) {
                    $app = Get-TableauConnectedApp -ClientId $script:ConnectedAppDummy
                    $app | Should -Not -BeNullOrEmpty
                    $app.clientId | Should -Not -BeNullOrEmpty
                    $secret = New-TableauConnectedAppSecret -ClientId $app.clientId
                    $secret | Should -Not -BeNullOrEmpty
                    $secret = Get-TableauConnectedAppSecret -ClientId $app.clientId -SecretId $secret.id
                    $secret | Should -Not -BeNullOrEmpty
                    {Remove-TableauConnectedAppSecret -ClientId $app.clientId -SecretId $secret.id} | Should -Not -Throw
                } else {
                    Set-ItResult -Skipped -Because "Connected app dummy was not added in the previous test"
                }
            }
            It "Remove dummy Tableau connected app on <ConfigFile.server>" {
                if ($script:ConnectedAppDummy) {
                    {Remove-TableauConnectedApp -ClientId $script:ConnectedAppDummy} | Should -Not -Throw
                } else {
                    Set-ItResult -Skipped -Because "Connected app dummy was not added in the previous test"
                }
                $script:ConnectedAppDummy = $null
            }
            It "Generate/get/update/remove Tableau connected app EAS on <ConfigFile.server>" {
                if ($ConfigFile.tableau_cloud) {
                    $eas = New-TableauConnectedAppEAS -IssuerUrl "https://google.com/auth/add_oauth_token"
                    $eas | Should -Not -BeNullOrEmpty
                    $list = Get-TableauConnectedAppEAS
                    $list | Should -Not -BeNullOrEmpty
                    Get-TableauConnectedAppEAS -EasId $eas.id | Should -Not -BeNullOrEmpty
                    Set-TableauConnectedAppEAS -EasId $eas.id -Name "EAS" | Should -Not -BeNullOrEmpty
                    {Remove-TableauConnectedAppEAS -EasId $eas.id} | Should -Not -Throw
                } else {
                    Set-ItResult -Skipped -Because "EAS methods not supported on Tableau Server"
                }
            }
        }
        Context "Site operations" -Tag Site {
            It "Create new site on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    $site = New-TableauSite -Name $ConfigFile.test_site_name -ContentUrl $ConfigFile.test_site_contenturl -SiteParams @{
                        adminMode = "ContentOnly"
                        revisionLimit = 20
                    }
                    $site.id | Should -BeOfType String
                    $site.contentUrl | Should -BeOfType String
                    $script:testSiteId = $site.id
                    $script:testSite = $site.contentUrl
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Update site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    Switch-TableauSite -Site $testSite
                    $siteNewName = New-Guid
                    $site = Set-TableauSite -SiteId $testSiteId -Name $siteNewName -SiteParams @{revisionLimit = 10}
                    $site.id | Should -Be $testSiteId
                    $site.contentUrl | Should -Be $testSite
                    $site.name | Should -Be $siteNewName
                    Set-TableauSite -SiteId $testSiteId -Name $ConfigFile.test_site_name -SiteParams @{adminMode="ContentAndUsers"; userQuota="1"}
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Query sites on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    $sites = Get-TableauSite
                    ($sites | Measure-Object).Count | Should -BeGreaterThan 0
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                }
            }
            It "Get current site on <ConfigFile.server>" {
                if ($ConfigFile.test_site_name) {
                    Switch-TableauSite -Site $testSite
                    $sites = Get-TableauSite -Current
                    ($sites | Measure-Object).Count | Should -Be 1
                    $sites | Where-Object id -eq $script:testSiteId | Should -Not -BeNullOrEmpty
                    $sites | Where-Object contentUrl -eq $script:testSite | Should -Not -BeNullOrEmpty
                    $sites = Get-TableauSite -Current -IncludeUsageStatistics
                    ($sites | Measure-Object).Count | Should -Be 1
                }
            }
            It "Delete site <testSite> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    Switch-TableauSite -Site $testSite
                    $response = Remove-TableauSite -SiteId $testSiteId
                    $response | Should -BeOfType String
                    $script:testSiteId = $null
                    $script:testSite = $null
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.pat_credential -PersonalAccessToken
                    } else {
                        $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.credential
                    }
                    $response.user.id | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Delete site on <ConfigFile.server> asynchronously" {
                if ($ConfigFile.server_admin -and $ConfigFile.test_site_name) {
                    $tempSiteName = New-Guid # get UUID for site name and content URL
                    $site = New-TableauSite -Name $tempSiteName -ContentUrl $tempSiteName
                    $site.id | Should -BeOfType String
                    $tempSiteId = $site.id
                    Switch-TableauSite -Site $tempSiteName
                    $response = Remove-TableauSite -SiteId $tempSiteId -BackgroundTask
                    $response | Should -BeOfType String
                    # because we've just deleted the current site, we need to sign-in again
                    if ($ConfigFile.pat_name) {
                        $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.pat_credential -PersonalAccessToken
                    } else {
                        $response = Connect-TableauServer -Server $ConfigFile.server -Site $ConfigFile.site -Credential $ConfigFile.credential
                    }
                    $response.user.id | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
        }
        Context "Project operations" -Tag Project {
            It "Create new project on <ConfigFile.server>" {
                $projectName = New-Guid
                $project = New-TableauProject -Name $projectName
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
                # adding another project with the same name - should throw an error
                {New-TableauProject -Name $projectName} | Should -Throw
            }
            It "Update project <testProjectId> on <ConfigFile.server>" {
                $projectNewName = New-Guid
                $project = Set-TableauProject -ProjectId $testProjectId -Name $projectNewName
                $project.id | Should -Be $testProjectId
                $project.name | Should -Be $projectNewName
            }
            It "Query projects on <ConfigFile.server>" {
                $projects = Get-TableauProject
                ($projects | Measure-Object).Count | Should -BeGreaterThan 0
                $projects | Where-Object id -eq $testProjectId | Should -Not -BeNullOrEmpty
            }
            It "Query projects with options on <ConfigFile.server>" {
                $projectName = Get-TableauProject | Where-Object id -eq $testProjectId | Select-Object -First 1 -ExpandProperty name
                $projectName | Should -Not -BeNullOrEmpty
                $projects = Get-TableauProject -Filter "name:eq:$projectName" -Sort name:asc -Fields id,name,description
                ($projects | Measure-Object).Count | Should -Be 1
                ($projects | Get-Member -MemberType Property | Measure-Object).Count | Should -Be 3
            }
            It "Delete project <testProjectId> on <ConfigFile.server>" {
                $response = Remove-TableauProject -ProjectId $testProjectId
                $response | Should -BeOfType String
                $script:testProjectId = $null
            }
            It "Create/update new project with samples on <ConfigFile.server>" {
                $projectNameSamples = New-Guid
                $project = New-TableauProject -Name $projectNameSamples
                $project.id | Should -BeOfType String
                $script:testProjectId = $project.id
                $project = Set-TableauProject -ProjectId $testProjectId -Name $projectNameSamples -PublishSamples
                $project.id | Should -BeOfType String
            }
            It "Create/update project with different owner on <ConfigFile.server>" {
                if ((Get-TableauRestVersion) -ge [version]3.21) {
                    try {
                        if (-Not $script:testUserId) {
                            if ($ConfigFile.test_username) {
                                $userName = $ConfigFile.test_username
                                $user = Get-TableauUser -Filter "name:eq:$userName"
                                if (-Not $user.id) {
                                    $user = New-TableauUser -Name $userName -SiteRole ExplorerCanPublish -AuthSetting "ServerDefault"
                                    $user.id | Should -BeOfType String
                                }
                                $script:testUserId = $user.id
                            } else {
                                $userName = New-Guid
                                $user = New-TableauUser -Name $userName -SiteRole ExplorerCanPublish -AuthSetting "ServerDefault"
                                $user.id | Should -BeOfType String
                                $script:testUserId = $user.id
                            }
                        } else {
                            $user = Set-TableauUser -Id $script:testUserId -SiteRole ExplorerCanPublish
                            $user.id | Should -BeOfType String
                        }
                        $projectNameSamples = New-Guid
                        $project = New-TableauProject -Name $projectNameSamples -OwnerId ($user.id)
                        $project.owner.id | Should -Be $user.id
                        $project = Set-TableauProject -ProjectId $project.id -OwnerId (Get-TableauCurrentUserId)
                        $project.owner.id | Should -Be (Get-TableauCurrentUserId)
                    } finally {
                        if ($script:testUserId) {
                            Remove-TableauUser -UserId $script:testUserId | Out-Null
                            $script:testUserId = $null
                        }
                        if ($project) {
                            Remove-TableauProject -ProjectId $project.id | Out-Null
                        }
                    }
                } else {
                    Set-ItResult -Skipped -Because "feature not available for this version"
                }
            }
            It "Initial project permissions & default permissions on <ConfigFile.server>" {
                $defaultProject = Get-TableauDefaultProject
                $defaultProject.id | Should -BeOfType String
                $defaultProject.name | Should -Be "Default"
                $defProjectPermissionTable = Get-TableauContentPermission -ProjectId $defaultProject.id | ConvertTo-TableauPermissionTable
                $newProjectPermissionTable = Get-TableauContentPermission -ProjectId $testProjectId | ConvertTo-TableauPermissionTable
                Assert-Equivalent -Actual $defProjectPermissionTable -Expected $newProjectPermissionTable
                $defProjectPermissions = Get-TableauDefaultPermission -ProjectId $defaultProject.id
                $newProjectPermissions = Get-TableauDefaultPermission -ProjectId $testProjectId
                Assert-Equivalent -Actual $newProjectPermissions -Expected $defProjectPermissions
                # another approach to deep compare permissions tables: convert to json
                # however this doesn't work with differences in capabilities sort order
                # $defProjectPermissionsJson = $defProjectPermissions | ConvertTo-Json -Compress
                # $newProjectPermissionsJson = $newProjectPermissions | ConvertTo-Json -Compress
                # $newProjectPermissionsJson | Should -Be $defProjectPermissionsJson
            }
            It "Query/remove/add/set project permissions on <ConfigFile.server>" {
                $permissions = Get-TableauContentPermission -ProjectId $testProjectId
                $permissions.project.id | Should -Be $testProjectId
                $savedPermissionTable = $permissions | ConvertTo-TableauPermissionTable
                # remove all permissions for all grantees
                Remove-TableauContentPermission -ProjectId $testProjectId -All | Out-Null
                $permissions = Get-TableauContentPermission -ProjectId $testProjectId
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                # attempt to set permissions with empty capabilities
                $permissions = Set-TableauContentPermission -ProjectId $testProjectId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{}}
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
                $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                $permissions = Add-TableauContentPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                # set all possible permissions to Allow for the current user
                $allPermissionTable = @()
                $capabilitiesHashtable = @{}
                foreach ($cap in $possibleCap) {
                    $capabilitiesHashtable.Add($cap, "Allow")
                }
                $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                $permissions = Set-TableauContentPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                $permissions.project.id | Should -Be $testProjectId
                $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                # remove all permissions for the current user
                Remove-TableauContentPermission -ProjectId $testProjectId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                $permissions = Get-TableauContentPermission -ProjectId $testProjectId
                $permissions.granteeCapabilities | Should -BeNullOrEmpty
                # add back initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Add-TableauContentPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
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
                                Remove-TableauContentPermission -ProjectId $testProjectId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode | Out-Null
                            }
                        }
                    }
                    $permissions = Get-TableauContentPermission -ProjectId $testProjectId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                }
                # permissions by template for the current user
                foreach ($pt in 'Denied','None','View','Publish','None') {
                    $permissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$pt}
                    $permissions = Set-TableauContentPermission -ProjectId $testProjectId -PermissionTable $permissionTable
                    $permissions.project.id | Should -Be $testProjectId
                    $actualPermissionTable = Get-TableauContentPermission -ProjectId $testProjectId | ConvertTo-TableauPermissionTable
                    switch ($pt) {
                        'View' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"}}
                        }
                        'Publish' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Write="Allow"}}
                        }
                        'Administer' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Write="Allow"}}
                        }
                        'Denied' {
                            $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Deny"; Write="Deny"}}
                        }
                        default {
                            $expectedPermissionTable = $null
                        }
                    }
                    Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                }
            }
            It "Query/remove/set default project permissions on <ConfigFile.server>" {
                $savedPermissionTable = Get-TableauDefaultPermission -ProjectId $testProjectId
                $wbPermissionTable = Get-TableauDefaultPermission -ProjectId $testProjectId -ContentType workbooks
                $wbPermissionTable.Length | Should -BeLessOrEqual $savedPermissionTable.Length
                # remove all default permissions for all grantees
                Remove-TableauDefaultPermission -ProjectId $testProjectId -All | Out-Null
                $permissions = Get-TableauDefaultPermission -ProjectId $testProjectId
                $permissions.Length | Should -Be 0
                # add all possible permissions (random Allow/Deny) for the current user
                foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                    if ($ct -eq 'dataroles' -and ((Get-TableauRestVersion) -lt [version]3.13 -or (Get-TableauRestVersion) -ge [version]3.22)) {
                        continue
                    } elseif ($ct -eq 'lenses' -and ((Get-TableauRestVersion) -lt [version]3.13 -or (Get-TableauRestVersion) -ge [version]3.22)) {
                        continue
                    } elseif ($ct -in 'databases','tables' -and (Get-TableauRestVersion) -lt [version]3.6) {
                        continue
                    }
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
                    $allPermissionTable += @{contentType=$ct; granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TableauDefaultPermission -ProjectId $testProjectId -PermissionTable $allPermissionTable
                    $permissions.Length | Should -Be 1 # we add for only one content type, so the output is also only 1
                    ($permissions | Where-Object contentType -eq $ct).capabilities.Count | Should -Be $possibleCap.Length
                }
                # remove all default permissions for one grantee
                Remove-TableauDefaultPermission -ProjectId $testProjectId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                $permissions = Get-TableauDefaultPermission -ProjectId $testProjectId
                $permissions.Length | Should -Be 0
                # restore initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Set-TableauDefaultPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
                    # remove all default permissions for one grantee for the first content type
                    Remove-TableauDefaultPermission -ProjectId $testProjectId -GranteeType $permissions[0].granteeType -GranteeId $permissions[0].granteeId -ContentType $permissions[0].contentType | Out-Null
                    $permissions = Get-TableauDefaultPermission -ProjectId $testProjectId
                    $permissions.Length | Should -BeLessThan $savedPermissionTable.Length
                }
                # restore initial permissions configuration
                if ($savedPermissionTable.Length -gt 0) {
                    $permissions = Set-TableauDefaultPermission -ProjectId $testProjectId -PermissionTable $savedPermissionTable
                    # remove again each permission/capability one-by-one
                    foreach ($permission in $permissions) {
                        if ($permission.capabilities -and $permission.capabilities.Count -gt 0) {
                            $permission.capabilities.GetEnumerator() | ForEach-Object {
                                Remove-TableauDefaultPermission -ProjectId $testProjectId -GranteeType $permission.granteeType -GranteeId $permission.granteeId -CapabilityName $_.Key -CapabilityMode $_.Value -ContentType $permission.contentType | Out-Null
                            }
                        }
                    }
                    $permissions = Get-TableauDefaultPermission -ProjectId $testProjectId
                    $permissions.Length | Should -Be 0
                }
            }
            It "Set default project permissions with templates on <ConfigFile.server>" {
                Remove-TableauDefaultPermission -ProjectId $testProjectId -All | Out-Null
                # apply all possible permission templates for the current user
                foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                    if ($ct -eq 'dataroles' -and ((Get-TableauRestVersion) -lt [version]3.13 -or (Get-TableauRestVersion) -ge [version]3.22)) {
                        continue
                    } elseif ($ct -eq 'lenses' -and ((Get-TableauRestVersion) -lt [version]3.13 -or (Get-TableauRestVersion) -ge [version]3.22)) {
                        continue
                    } elseif ($ct -in 'databases','tables' -and (Get-TableauRestVersion) -lt [version]3.6) {
                        continue
                    }
                    foreach ($tpl in 'View','Explore','Denied','Publish','Administer','None') {
                        $tplPermissionTable = @{contentType=$ct; granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$tpl}
                        $permissions = Set-TableauDefaultPermission -ProjectId $testProjectId -PermissionTable $tplPermissionTable
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
                if (-Not $script:testUserId) {
                    if ($ConfigFile.test_username) {
                        $userName = $ConfigFile.test_username
                    } else {
                        $userName = New-Guid
                    }
                    $user = New-TableauUser -Name $userName -SiteRole Unlicensed
                    $user.id | Should -BeOfType String
                    $script:testUserId = $user.id
                }
            }
            It "Update user <testUserId> on <ConfigFile.server>" {
                $user = Set-TableauUser -UserId $script:testUserId -SiteRole Viewer
                $user.siteRole | Should -Be "Viewer"
                if ($ConfigFile.test_password) {
                    $fullName = New-Guid
                    $user = Set-TableauUser -UserId $script:testUserId -SiteRole Viewer -FullName $fullName -SecurePassword (ConvertTo-SecureString $ConfigFile.test_password -AsPlainText -Force)
                    $user.siteRole | Should -Be "Viewer"
                    $user.fullName | Should -Be $fullName
                }
            }
            It "Query users on <ConfigFile.server>" {
                $users = Get-TableauUser
                ($users | Measure-Object).Count | Should -BeGreaterThan 0
                $users | Where-Object id -eq $script:testUserId | Should -Not -BeNullOrEmpty
                $user = Get-TableauUser -UserId $script:testUserId
                $user.id | Should -Be $script:testUserId
            }
            It "Query users with options on <ConfigFile.server>" {
                $userName = Get-TableauUser | Where-Object id -eq $script:testUserId | Select-Object -First 1 -ExpandProperty name
                $users = Get-TableauUser -Filter "name:eq:$userName" -Sort name:asc -Fields _all_
                ($users | Measure-Object).Count | Should -Be 1
                ($users | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterThan 5
            }
            It "Remove user <testUserId> on <ConfigFile.server>" {
                $response = Remove-TableauUser -UserId $script:testUserId
                $response | Should -BeOfType String
                $script:testUserId = $null
            }
            It "Import users via CSV file on <ConfigFile.server>" {
                if ($ConfigFile.tableau_cloud) {
                    $job = Import-TableauUsersCsv -CsvFile './tests/assets/Misc/users_to_add_cloud.csv' -AuthSetting ServerDefault
                } else {
                    $job = Import-TableauUsersCsv -CsvFile './tests/assets/Misc/users_to_add.csv'
                }
                $job | Should -Not -BeNullOrEmpty
                $job.type | Should -Be "UserImport"
                $job.mode | Should -Be "Asynchronous"
                $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                if ($jobFinished.extractRefreshJob.notes) {
                    Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                }
                if ($jobFinished.statusNotes) {
                    $jobFinished.statusNotes.statusNote | ForEach-Object {
                        Write-Verbose ("Job status notes: {0}" -f $_.text)
                    }
                }
                $jobFinished.finishCode | Should -Be 0
            }
            It "Remove users via CSV file on <ConfigFile.server>" {
                if ($ConfigFile.tableau_cloud) {
                    # $job = Remove-TableauUsersCsv -CsvFile './tests/assets/Misc/users_to_remove_cloud.csv'
                    $user = Get-TableauUser -Filter "name:eq:user1@domain.com"
                    $response = Remove-TableauUser -UserId $user.id
                    $response | Should -BeOfType String
                    $user = Get-TableauUser -Filter "name:eq:user2@domain.com"
                    $response = Remove-TableauUser -UserId $user.id
                    $response | Should -BeOfType String
                } else {
                    # TODO test this method on Tableau Server, on Tableau Cloud this doesn't work for some reason
                    $job = Remove-TableauUsersCsv -CsvFile './tests/assets/Misc/users_to_remove.csv'
                    $job | Should -Not -BeNullOrEmpty
                }
                if ($job) {
                    $job.type | Should -Be "UserDelete"
                    $job.mode | Should -Be "Asynchronous"
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    if ($jobFinished.extractRefreshJob.notes) {
                        Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                    }
                    if ($jobFinished.statusNotes) {
                        $jobFinished.statusNotes.statusNote | ForEach-Object {
                            Write-Verbose ("Job status notes: {0}" -f $_.text)
                        }
                    }
                    $jobFinished.finishCode | Should -Be 0
                }
            }
        }
        Context "Group operations" -Tag Group {
            It "Add new group on <ConfigFile.server>" {
                $groupName = New-Guid
                $group = New-TableauGroup -Name $groupName -MinimumSiteRole Viewer
                $group.id | Should -BeOfType String
                $script:testGroupId = $group.id
            }
            It "Update group <testGroupId> on <ConfigFile.server>" {
                $groupName = New-Guid
                $group = Set-TableauGroup -GroupId $script:testGroupId -Name $groupName
                $group.id | Should -Be $script:testGroupId
                $group.name | Should -Be $groupName
            }
            It "Query groups on <ConfigFile.server>" {
                $groups = Get-TableauGroup
                ($groups | Measure-Object).Count | Should -BeGreaterThan 0
                $groups | Where-Object id -eq $script:testGroupId | Should -Not -BeNullOrEmpty
            }
            It "Query groups with options on <ConfigFile.server>" {
                $groupName = Get-TableauGroup | Where-Object id -eq $script:testGroupId | Select-Object -First 1 -ExpandProperty name
                $groups = Get-TableauGroup -Filter "name:eq:$groupName" -Sort name:asc -Fields id,name
                ($groups | Measure-Object).Count | Should -Be 1
                ($groups | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
            }
            It "Remove group <testGroupId> on <ConfigFile.server>" {
                $response = Remove-TableauGroup -GroupId $script:testGroupId
                $response | Should -BeOfType String
                $script:testGroupId = $null
            }
        }
        Context "User/Group operations" -Tag UserGroup {
            It "Add new user/group on <ConfigFile.server>" {
                if (-Not $script:testUserId) {
                    if ($ConfigFile.test_username) {
                        $userName = $ConfigFile.test_username
                    } else {
                        $userName = New-Guid
                    }
                    $user = New-TableauUser -Name $userName -SiteRole Unlicensed -AuthSetting "ServerDefault"
                    $user.id | Should -BeOfType String
                    $script:testUserId = $user.id
                }
                $groupName = New-Guid
                $group = New-TableauGroup -Name $groupName -MinimumSiteRole Viewer -GrantLicenseMode onLogin
                $group.id | Should -BeOfType String
                $script:testGroupId = $group.id
            }
            It "Add user to group on <ConfigFile.server>" {
                $user = Add-TableauUserToGroup -UserId $script:testUserId -GroupId $script:testGroupId
                $user.id | Should -Be $script:testUserId
                # $user.siteRole | Should -Be "Viewer" # doesn't work on Tableau Cloud
            }
            It "Query groups for user on <ConfigFile.server>" {
                $groups = Get-TableauGroupsForUser -UserId $script:testUserId
                ($groups | Measure-Object).Count | Should -BeGreaterThan 0
                $groups | Where-Object id -eq $script:testGroupId | Should -Not -BeNullOrEmpty
            }
            It "Query users in group on <ConfigFile.server>" {
                $users = Get-TableauUsersInGroup -GroupId $script:testGroupId
                ($users | Measure-Object).Count | Should -BeGreaterThan 0
                $users | Where-Object id -eq $script:testUserId | Should -Not -BeNullOrEmpty
            }
            It "Remove user from group on <ConfigFile.server>" {
                $response = Remove-TableauUserFromGroup -UserId $script:testUserId -GroupId $script:testGroupId
                $response | Should -BeOfType String
                $users = Get-TableauUsersInGroup -GroupId $script:testGroupId
                ($users | Measure-Object).Count | Should -Be 0
            }
        }
        Context "Workbook operations" -Tag Workbook {
            It "Get workbooks on <ConfigFile.server>" {
                $workbooks = Get-TableauWorkbook
                ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                $workbookId = $workbooks | Select-Object -First 1 -ExpandProperty id
                $workbookId | Should -BeOfType String
                $workbook = Get-TableauWorkbook -WorkbookId $workbookId
                $workbook.id | Should -Be $workbookId
                $workbookConnections = Get-TableauWorkbookConnection -WorkbookId $workbookId
                ($workbookConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Query workbooks with options on <ConfigFile.server>" {
                $workbookName = Get-TableauWorkbook | Select-Object -First 1 -ExpandProperty name
                $workbooks = Get-TableauWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name
                ($workbooks | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($workbooks | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
            }
            It "Get workbook connections on <ConfigFile.server>" {
                $workbookId = Get-TableauWorkbook | Select-Object -First 1 -ExpandProperty id
                $connections = Get-TableauWorkbookConnection -WorkbookId $workbookId
                ($connections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Get workbook revisions on <ConfigFile.server>" {
                $workbookId = Get-TableauWorkbook | Select-Object -First 1 -ExpandProperty id
                $revisions = Get-TableauWorkbook -WorkbookId $workbookId -Revisions
                ($revisions | Measure-Object).Count | Should -BeGreaterThan 0
                $revisions | Select-Object -First 1 -ExpandProperty revisionNumber | Should -BeGreaterThan 0
            }
            Context "Publish, download, revisions for sample workbook on <ConfigFile.server>" {
                BeforeAll {
                    $project = New-TableauProject -Name (New-Guid)
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                        $script:samplesProjectId = $null
                    }
                }
                It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                    $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                    $project.id | Should -Be $samplesProjectId
                    # Start-Sleep -s 3
                }
                It "Query workbooks for current user on <ConfigFile.server>" {
                    $workbooks = Get-TableauWorkbooksForUser -UserId (Get-TableauCurrentUserId)
                    ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                    $workbooks | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                    $workbooks = Get-TableauWorkbooksForUser -UserId (Get-TableauCurrentUserId) -IsOwner
                    ($workbooks | Measure-Object).Count | Should -BeGreaterThan 0
                    $workbooks | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                }
                It "Get sample workbook id from <ConfigFile.server>" {
                    $workbook = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName","name:eq:Superstore" | Select-Object -First 1
                    # if (-not $workbook) { # fallback: perform filter in PS
                    #     $workbook = Get-TableauWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    # }
                    $script:sampleWorkbookId = $workbook.id
                    $script:sampleWorkbookName = $workbook.name
                    $script:sampleWorkbookContentUrl = $workbook.contentUrl
                    $sampleWorkbookId | Should -BeOfType String
                }
                It "Get sample workbook by content URL from <ConfigFile.server>" {
                    if ((Get-TableauRestVersion) -ge [version]3.17) {
                        $workbook = Get-TableauWorkbook -ContentUrl $sampleWorkbookContentUrl
                        $workbook.id | Should -Be $script:sampleWorkbookId
                        $workbook.name | Should -Be $script:sampleWorkbookName
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for this version"
                    }
                }
                It "Download sample workbook from <ConfigFile.server>" {
                    Export-TableauWorkbook -WorkbookId $sampleWorkbookId -OutFile "tests/output/$sampleWorkbookName.twbx"
                    Test-Path -Path "tests/output/$sampleWorkbookName.twbx" | Should -BeTrue
                    Export-TableauWorkbook -WorkbookId $sampleWorkbookId -OutFile "tests/output/$sampleWorkbookName.twb" -ExcludeExtract
                    Test-Path -Path "tests/output/$sampleWorkbookName.twb" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleWorkbookName.twb" | Out-Null
                }
                It "Download sample workbook as PDF from <ConfigFile.server>" {
                    Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "tests/output/$sampleWorkbookName.pdf"
                    Test-Path -Path "tests/output/$sampleWorkbookName.pdf" | Should -BeTrue
                    Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -OutFile "tests/output/$sampleWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1
                    Test-Path -Path "tests/output/$sampleWorkbookName.pdf" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleWorkbookName.pdf" | Out-Null
                }
                It "Download sample workbook as PowerPoint from <ConfigFile.server>" {
                    Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "tests/output/$sampleWorkbookName.pptx"
                    Test-Path -Path "tests/output/$sampleWorkbookName.pptx" | Should -BeTrue
                    # Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "tests/output/$sampleWorkbookName.pptx" -MaxAge 1
                    # Test-Path -Path "tests/output/$sampleWorkbookName.pptx" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleWorkbookName.pptx" | Out-Null
                }
                It "Download sample workbook as PNG from <ConfigFile.server>" {
                    Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format image -OutFile "tests/output/$sampleWorkbookName.png"
                    Test-Path -Path "tests/output/$sampleWorkbookName.png" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleWorkbookName.png" | Out-Null
                }
                It "Publish sample workbook on <ConfigFile.server>" {
                    $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "tests/output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (chunks) on <ConfigFile.server>" {
                    $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "tests/output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $workbook.id | Should -BeOfType String
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (hidden views) on <ConfigFile.server>" {
                    $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "tests/output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}
                    $workbook.id | Should -BeOfType String
                    $workbook.showTabs | Should -Be false
                    $script:sampleWorkbookId = $workbook.id
                }
                It "Publish sample workbook (with options) on <ConfigFile.server>" {
                    if ((Get-TableauRestVersion) -ge [version]3.21) {
                        $description = "Testing sample workbook - description 123"
                        $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "tests/output/$sampleWorkbookName.twbx" -ProjectId $samplesProjectId -Overwrite -ShowTabs -ThumbnailsUserId (Get-TableauCurrentUserId) -Description $description
                        $workbook.id | Should -BeOfType String
                        $workbook.showTabs | Should -Be true
                        $workbook.description | Should -Be $description
                        $script:sampleWorkbookId = $workbook.id
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for this version"
                    }
                }
                It "Update sample workbook (showTabs) on <ConfigFile.server>" {
                    $workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -ShowTabs:$false
                    $workbook.showTabs | Should -Be false
                    $workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -Description "Test description"
                    $workbook.showTabs | Should -Be false
                    $workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -ShowTabs
                    $workbook.showTabs | Should -Be true
                    $workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -Description "Test description"
                    $workbook.showTabs | Should -Be true
                }
                It "Update sample workbook (description) on <ConfigFile.server>" {
                    if ((Get-TableauRestVersion) -ge [version]3.21) {
                        $description = "Testing sample workbook - description 456" # - special symbols äöü©®!?
                        $workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -Description $description
                        $workbook.description | Should -Be $description
                    } else {
                        Set-ItResult -Skipped -Because "feature not available for this version"
                    }
                }
                It "Download & remove previous workbook revision on <ConfigFile.server>" {
                    $revisions = Get-TableauWorkbook -WorkbookId $sampleWorkbookId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        Export-TableauWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "tests/output/download_revision.twbx"
                        Test-Path -Path "tests/output/download_revision.twbx" | Should -BeTrue
                        Remove-Item -Path "tests/output/download_revision.twbx" | Out-Null
                        Remove-TableauWorkbook -WorkbookId $sampleWorkbookId -Revision $revision | Out-Null
                    } else {
                        Set-ItResult -Skipped -Because "only one revision was found"
                    }
                }
                It "Download latest workbook revision on <ConfigFile.server>" {
                    $revision = Get-TableauWorkbook -WorkbookId $sampleWorkbookId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    Export-TableauWorkbook -WorkbookId $sampleWorkbookId -Revision $revision -OutFile "tests/output/download_revision.twbx"
                    Test-Path -Path "tests/output/download_revision.twbx" | Should -BeTrue
                    Remove-Item -Path "tests/output/download_revision.twbx" | Out-Null
                }
                It "Add/remove tags for sample workbook on <ConfigFile.server>" {
                    Add-TableauContentTag -WorkbookId $sampleWorkbookId -Tags "active","test" | Out-Null
                    ((Get-TableauWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TableauContentTag -WorkbookId $sampleWorkbookId -Tag "test" | Out-Null
                    ((Get-TableauWorkbook -WorkbookId $sampleWorkbookId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TableauContentTag -WorkbookId $sampleWorkbookId -Tag "active" | Out-Null
                    (Get-TableauWorkbook -WorkbookId $sampleWorkbookId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set workbook permissions on <ConfigFile.server>" {
                    $permissions = Get-TableauContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $savedPermissionTable = $permissions | ConvertTo-TableauPermissionTable
                    # remove all permissions for all grantees
                    Remove-TableauContentPermission -WorkbookId $sampleWorkbookId -All | Out-Null
                    $permissions = Get-TableauContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TableauContentPermission -WorkbookId $sampleWorkbookId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TableauContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $allPermissionTable
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
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TableauContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $allPermissionTable
                    $permissions.workbook.id | Should -Be $sampleWorkbookId
                    $permissions.workbook.name | Should -Be $sampleWorkbookName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TableauContentPermission -WorkbookId $sampleWorkbookId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                    $permissions = Get-TableauContentPermission -WorkbookId $sampleWorkbookId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TableauContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $savedPermissionTable
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
                                    Remove-TableauContentPermission -WorkbookId $sampleWorkbookId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode | Out-Null
                                }
                            }
                        }
                        $permissions = Get-TableauContentPermission -WorkbookId $sampleWorkbookId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'View','Denied','Explore','Publish','None','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$pt}
                        $permissions = Set-TableauContentPermission -WorkbookId $sampleWorkbookId -PermissionTable $permissionTable
                        $permissions.workbook.id | Should -Be $sampleWorkbookId
                        $actualPermissionTable = Get-TableauContentPermission -WorkbookId $sampleWorkbookId | ConvertTo-TableauPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"; ExportXml="Allow"; Write="Allow"; CreateRefreshMetrics="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; RunExplainData="Allow"; ExportXml="Allow"; Write="Allow"; CreateRefreshMetrics="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Deny"; Filter="Deny"; ViewComments="Deny"; AddComment="Deny"; ExportImage="Deny"; ExportData="Deny"; ShareView="Deny"; ViewUnderlyingData="Deny"; WebAuthoring="Deny"; RunExplainData="Deny"; ExportXml="Deny"; Write="Deny"; CreateRefreshMetrics="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
                }
                It "Publish workbook with invalid extension on <ConfigFile.server>" {
                    {Publish-TableauWorkbook -Name "Workbook" -InFile "tests/assets/Misc/Workbook.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish workbook with invalid contents on <ConfigFile.server>" {
                    {Publish-TableauWorkbook -Name "invalid" -InFile "tests/assets/Misc/invalid.twbx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish TWB workbook with embed credentials on <ConfigFile.server>" -Tag WorkbookP {
                    # this request/test is done first to unsuspend the database (free SQL tier, suspended after 1h of inactivity)
                    $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                    $credentials = @{username="sqladmin"; password=$securePw; embed="true" }
                    try {
                        $workbook = Publish-TableauWorkbook -Name "AW Customer Address" -InFile "tests/assets/Misc/AW_Customer_Address.twb" -ProjectId $samplesProjectId -Credentials $credentials
                        $workbook | Should -Not -BeNullOrEmpty
                        $view = Get-TableauView -Filter "workbookName:eq:AW Customer Address","projectName:eq:$samplesProjectName" | Select-Object -First 1
                        $view | Should -Not -BeNullOrEmpty
                        Export-TableauViewToFormat -ViewId $view.id -Format image -OutFile "tests/output/Sheet1.png"
                    } catch [Microsoft.PowerShell.Commands.WriteErrorException] {
                        # Write-Verbose $_.Exception.Message
                        Write-Verbose "The workbook couldn't be published, but the SQL database is now starting for other tests."
                    }
                }
                It "Publish workbook without embed credentials on <ConfigFile.server>" -Tag WorkbookP {
                    $workbook = Publish-TableauWorkbook -Name "AW Customer Address 1" -InFile "tests/assets/Misc/AW_Customer_Address.twbx" -ProjectId $samplesProjectId
                    $workbook | Should -Not -BeNullOrEmpty
                    # Remove-TableauWorkbook -WorkbookId $workbook.id | Out-Null
                }
                It "Publish workbook with embed credentials on <ConfigFile.server>" -Tag WorkbookP {
                    $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                    $credentials = @{username="sqladmin"; password=$securePw; embed="true" }
                    $workbook = Publish-TableauWorkbook -Name "AW Customer Address 2" -InFile "tests/assets/Misc/AW_Customer_Address.twbx" -ProjectId $samplesProjectId -Credentials $credentials
                    $workbook | Should -Not -BeNullOrEmpty
                    Write-Verbose "Queueing extract refresh job"
                    $job = Update-TableauWorkbookNow -WorkbookId $workbook.id
                    $job | Should -Not -BeNullOrEmpty
                    $job.type | Should -Be "RefreshExtract"
                    $job.mode | Should -Be "Asynchronous"
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    if ($jobFinished.extractRefreshJob.notes) {
                        Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                    }
                    if ($jobFinished.statusNotes) {
                        $jobFinished.statusNotes.statusNote | ForEach-Object {
                            Write-Verbose ("Job status notes: {0}" -f $_.text)
                        }
                    }
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauWorkbook -WorkbookId $workbook.id | Out-Null
                }
                It "Publish workbook with connections on <ConfigFile.server>" -Tag WorkbookP {
                    $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                    $connections = @( @{serverAddress="asl-tableau-testsql.database.windows.net"; serverPort="3389"; credentials=@{username="sqladmin"; password=$securePw; embed="true" }} )
                    $workbook = Publish-TableauWorkbook -Name "AW Customer Address 3" -InFile "tests/assets/Misc/AW_Customer_Address.twbx" -ProjectId $samplesProjectId -Connections $connections
                    $workbook | Should -Not -BeNullOrEmpty
                    Write-Verbose "Queueing extract refresh job"
                    $job = Update-TableauWorkbookNow -WorkbookId $workbook.id
                    $job | Should -Not -BeNullOrEmpty
                    $job.type | Should -Be "RefreshExtract"
                    $job.mode | Should -Be "Asynchronous"
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    if ($jobFinished.extractRefreshJob.notes) {
                        Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                    }
                    if ($jobFinished.statusNotes) {
                        $jobFinished.statusNotes.statusNote | ForEach-Object {
                            Write-Verbose ("Job status notes: {0}" -f $_.text)
                        }
                    }
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauWorkbook -WorkbookId $workbook.id | Out-Null
                }
                It "Publish workbook as background job on <ConfigFile.server>" -Tag WorkbookP {
                    $job = Publish-TableauWorkbook -Name "AW Customer Address 4" -InFile "tests/assets/Misc/AW_Customer_Address.twbx" -ProjectId $samplesProjectId -BackgroundTask
                    $job | Should -Not -BeNullOrEmpty
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 60
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauWorkbook -WorkbookId $workbook.id | Out-Null
                }
                Context "Publish / download workbooks from test assets on <ConfigFile.server>" -Tag WorkbookSamples -ForEach $WorkbookFiles {
                    BeforeAll {
                        $script:sampleWorkbookName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleWorkbookFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server>" {
                        $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -SkipConnectionCheck
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Publish file ""<sampleWorkbookFileName>"" into workbook ""<sampleWorkbookName>"" on <ConfigFile.server> (Chunked)" {
                        $workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile $_ -ProjectId $samplesProjectId -Overwrite -SkipConnectionCheck -Chunked
                        $workbook.id | Should -BeOfType String
                        $script:sampleWorkbookId = $workbook.id
                    }
                    It "Download workbook ""<sampleWorkbookName>"" from <ConfigFile.server>" {
                        if ($sampleWorkbookId) {
                            Export-TableauWorkbook -WorkbookId $sampleWorkbookId -OutFile "tests/output/download.twbx"
                            Test-Path -Path "tests/output/download.twbx" | Should -BeTrue
                            Remove-Item -Path "tests/output/download.twbx" | Out-Null
                        } else {
                            Set-ItResult -Skipped -Because "previous test(s) failed"
                        }
                    }
                }
            }
        }
        Context "Datasource operations" -Tag Datasource {
            It "Get datasources on <ConfigFile.server>" {
                $datasources = Get-TableauDatasource
                ($datasources | Measure-Object).Count | Should -BeGreaterThan 0
                $datasourceId = $datasources | Select-Object -First 1 -ExpandProperty id
                $datasourceId | Should -BeOfType String
                $datasource = Get-TableauDatasource -DatasourceId $datasourceId
                $datasource.id | Should -Be $datasourceId
                $datasourceConnections = Get-TableauDatasourceConnection -DatasourceId $datasourceId
                ($datasourceConnections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Query datasources with options on <ConfigFile.server>" {
                $datasourceName = Get-TableauDatasource | Select-Object -First 1 -ExpandProperty name
                $datasources = Get-TableauDatasource -Filter "name:eq:$datasourceName" -Sort name:asc -Fields id,name
                ($datasources | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($datasources | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
            }
            It "Get datasource connections on <ConfigFile.server>" {
                $datasourceId = Get-TableauDatasource | Select-Object -First 1 -ExpandProperty id
                $connections = Get-TableauDatasourceConnection -DatasourceId $datasourceId
                ($connections | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Get datasource revisions on <ConfigFile.server>" {
                $datasourceId = Get-TableauDatasource | Select-Object -First 1 -ExpandProperty id
                $revisions = Get-TableauDatasource -DatasourceId $datasourceId -Revisions
                ($revisions | Measure-Object).Count | Should -BeGreaterThan 0
                $revisions | Select-Object -First 1 -ExpandProperty revisionNumber | Should -BeGreaterThan 0
            }
            Context "Publish, download, revisions for sample datasource on <ConfigFile.server>" {
                BeforeAll {
                    $project = New-TableauProject -Name (New-Guid)
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                        $script:samplesProjectId = $null
                    }
                }
                It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                    $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                    $project.id | Should -Be $samplesProjectId
                    # Start-Sleep -s 3
                }
                It "Get sample datasource id from <ConfigFile.server>" {
                    $datasource = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    if (-not $datasource) { # fallback: perform filter in PS
                        $datasource = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
                    $script:sampleDatasourceId = $datasource.id
                    $script:sampleDatasourceName = $datasource.name
                    $sampleDatasourceId | Should -BeOfType String
                }
                It "Download sample datasource from <ConfigFile.server>" {
                    Export-TableauDatasource -DatasourceId $sampleDatasourceId -OutFile "tests/output/$sampleDatasourceName.tdsx"
                    Test-Path -Path "tests/output/$sampleDatasourceName.tdsx" | Should -BeTrue
                    # Remove-Item -Path "tests/output/$sampleDatasourceName.tdsx" | Out-Null
                }
                It "Publish sample datasource on <ConfigFile.server>" {
                    $datasource = Publish-TableauDatasource -Name $sampleDatasourceName -InFile "tests/output/$sampleDatasourceName.tdsx" -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                }
                It "Publish sample datasource (chunks) on <ConfigFile.server>" {
                    $datasource = Publish-TableauDatasource -Name $sampleDatasourceName -InFile "tests/output/$sampleDatasourceName.tdsx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $datasource.id | Should -BeOfType String
                    $script:sampleDatasourceId = $datasource.id
                }
                It "Download & remove previous datasource revision on <ConfigFile.server>" {
                    $revisions = Get-TableauDatasource -DatasourceId $sampleDatasourceId -Revisions
                    if (($revisions | Measure-Object).Count -gt 1) {
                        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                        Export-TableauDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "tests/output/download_revision.tdsx"
                        Test-Path -Path "tests/output/download_revision.tdsx" | Should -BeTrue
                        Remove-Item -Path "tests/output/download_revision.tdsx" | Out-Null
                        Remove-TableauDatasource -DatasourceId $sampleDatasourceId -Revision $revision | Out-Null
                    } else {
                        Set-ItResult -Skipped -Because "only one revision was found"
                    }
                }
                It "Download latest datasource revision on <ConfigFile.server>" {
                    $revision = Get-TableauDatasource -DatasourceId $sampleDatasourceId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                    Export-TableauDatasource -DatasourceId $sampleDatasourceId -Revision $revision -OutFile "tests/output/download_revision.tdsx"
                    Test-Path -Path "tests/output/download_revision.tdsx" | Should -BeTrue
                    Remove-Item -Path "tests/output/download_revision.tdsx" | Out-Null
                }
                It "Publish datasource with invalid extension on <ConfigFile.server>" {
                    {Publish-TableauDatasource -Name "Datasource" -InFile "tests/assets/Misc/Datasource.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish datasource with invalid contents on <ConfigFile.server>" {
                    {Publish-TableauDatasource -Name "invalid" -InFile "tests/assets/Misc/invalid.tdsx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish datasource with append option on <ConfigFile.server>" {
                    $datasource = Publish-TableauDatasource -Name "Datasource" -InFile "tests/assets/Misc/append.hyper" -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                    {Publish-TableauDatasource -Name "Datasource" -InFile "tests/assets/Misc/append.hyper" -ProjectId $samplesProjectId -Overwrite -Append} | Should -Throw
                    $datasource = Publish-TableauDatasource -Name "Datasource" -InFile "tests/assets/Misc/append.hyper" -ProjectId $samplesProjectId -Append
                    $datasource.id | Should -BeOfType String
                    $datasource = Publish-TableauDatasource -Name "Datasource" -InFile "tests/assets/Misc/append.hyper" -ProjectId $samplesProjectId -Append -Chunked
                    $datasource.id | Should -BeOfType String
                }
                It "Publish a Parquet file on <ConfigFile.server>" {
                    $datasource = Publish-TableauDatasource -Name "Titanic" -InFile './tests/assets/Misc/Titanic.parquet' -ProjectId $samplesProjectId -Overwrite
                    $datasource.id | Should -BeOfType String
                }
                It "Add/remove tags for sample datasource on <ConfigFile.server>" {
                    Add-TableauContentTag -DatasourceId $sampleDatasourceId -Tags "active","test" | Out-Null
                    ((Get-TableauDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TableauContentTag -DatasourceId $sampleDatasourceId -Tag "test" | Out-Null
                    ((Get-TableauDatasource -DatasourceId $sampleDatasourceId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TableauContentTag -DatasourceId $sampleDatasourceId -Tag "active" | Out-Null
                    (Get-TableauDatasource -DatasourceId $sampleDatasourceId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set datasource permissions on <ConfigFile.server>" {
                    $permissions = Get-TableauContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $savedPermissionTable = $permissions | ConvertTo-TableauPermissionTable
                    # remove all permissions for all grantees
                    Remove-TableauContentPermission -DatasourceId $sampleDatasourceId -All | Out-Null
                    $permissions = Get-TableauContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TableauContentPermission -DatasourceId $sampleDatasourceId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Connect','ExportXml','Write','SaveAs','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TableauContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $allPermissionTable
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
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TableauContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $allPermissionTable
                    $permissions.datasource.id | Should -Be $sampleDatasourceId
                    $permissions.datasource.name | Should -Be $sampleDatasourceName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TableauContentPermission -DatasourceId $sampleDatasourceId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                    $permissions = Get-TableauContentPermission -DatasourceId $sampleDatasourceId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TableauContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $savedPermissionTable
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
                                    Remove-TableauContentPermission -DatasourceId $sampleDatasourceId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode | Out-Null
                                }
                            }
                        }
                        $permissions = Get-TableauContentPermission -DatasourceId $sampleDatasourceId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'None','View','Explore','Denied','Publish','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$pt}
                        $permissions = Set-TableauContentPermission -DatasourceId $sampleDatasourceId -PermissionTable $permissionTable
                        $permissions.datasource.id | Should -Be $sampleDatasourceId
                        $actualPermissionTable = Get-TableauContentPermission -DatasourceId $sampleDatasourceId | ConvertTo-TableauPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"; Write="Allow"; SaveAs="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Connect="Allow"; ExportXml="Allow"; Write="Allow"; SaveAs="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Deny"; Connect="Deny"; ExportXml="Deny"; Write="Deny"; SaveAs="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
                }
                It "Publish datasource without embed credentials on <ConfigFile.server>" -Tag DatasourceP {
                    $datasource = Publish-TableauDatasource -Name "AW SalesOrders 0" -InFile "tests/assets/Misc/AW_SalesOrders.tdsx" -ProjectId $samplesProjectId
                    $datasource | Should -Not -BeNullOrEmpty
                }
                It "Publish datasource with embed credentials on <ConfigFile.server>" -Tag DatasourceP {
                    $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                    $credentials = @{username="sqladmin"; password=$securePw; embed="true" }
                    $datasource = Publish-TableauDatasource -Name "AW SalesOrders 1" -InFile "tests/assets/Misc/AW_SalesOrders.tdsx" -ProjectId $samplesProjectId -Credentials $credentials
                    $datasource | Should -Not -BeNullOrEmpty
                    Write-Verbose "Queueing extract refresh job"
                    $job = Update-TableauDatasourceNow -DatasourceId $datasource.id
                    $job | Should -Not -BeNullOrEmpty
                    $job.type | Should -Be "RefreshExtract"
                    $job.mode | Should -Be "Asynchronous"
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    if ($jobFinished.extractRefreshJob.notes) {
                        Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                    }
                    if ($jobFinished.statusNotes) {
                        $jobFinished.statusNotes.statusNote | ForEach-Object {
                            Write-Verbose ("Job status notes: {0}" -f $_.text)
                        }
                    }
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauDatasource -DatasourceId $datasource.id | Out-Null
                }
                It "Publish datasource with connections on <ConfigFile.server>" -Tag DatasourceP {
                    # note: this option is still not supported by the API as of v2023.3
                    # although it's coded the same way in the tsc python module
                    $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                    $connections = @( @{serverAddress="asl-tableau-testsql.database.windows.net"; serverPort="3389"; credentials=@{username="sqladmin"; password=$securePw; embed="true" }} )
                    $datasource = Publish-TableauDatasource -Name "AW SalesOrders 2" -InFile "tests/assets/Misc/AW_SalesOrders.tdsx" -ProjectId $samplesProjectId -Connections $connections
                    $datasource | Should -Not -BeNullOrEmpty
                    Write-Verbose "Queueing extract refresh job"
                    $job = Update-TableauDatasourceNow -DatasourceId $datasource.id
                    $job | Should -Not -BeNullOrEmpty
                    $job.type | Should -Be "RefreshExtract"
                    $job.mode | Should -Be "Asynchronous"
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    if ($jobFinished.extractRefreshJob.notes) {
                        Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                    }
                    if ($jobFinished.statusNotes) {
                        $jobFinished.statusNotes.statusNote | ForEach-Object {
                            Write-Verbose ("Job status notes: {0}" -f $_.text)
                        }
                    }
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauDatasource -DatasourceId $datasource.id | Out-Null
                }
                It "Publish datasource as background job on <ConfigFile.server>" -Tag DatasourceP {
                    $job = Publish-TableauDatasource -Name "AW SalesOrders 3" -InFile "tests/assets/Misc/AW_SalesOrders.tdsx" -ProjectId $samplesProjectId -BackgroundTask -Overwrite
                    $job | Should -Not -BeNullOrEmpty
                    $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 60
                    Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                    $jobFinished.finishCode | Should -Be 0
                    # Remove-TableauDatasource -DatasourceId $datasource.id | Out-Null
                }
                Context "Publish / download datasources from test assets on <ConfigFile.server>"  -Tag DatasourceSamples -ForEach $DatasourceFiles {
                    BeforeAll {
                        $script:sampleDatasourceName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleDatasourceFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server>" {
                        $datasource = Publish-TableauDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Publish file ""<sampleDatasourceFileName>"" into datasource ""<sampleDatasourceName>"" on <ConfigFile.server> (Chunked)" {
                        $datasource = Publish-TableauDatasource -Name $sampleDatasourceName -InFile $_ -ProjectId $samplesProjectId -Overwrite -Chunked
                        $datasource.id | Should -BeOfType String
                        $script:sampleDatasourceId = $datasource.id
                    }
                    It "Download datasource ""<sampleDatasourceName>"" from <ConfigFile.server>" {
                        Export-TableauDatasource -DatasourceId $sampleDatasourceId -OutFile "tests/output/download.tdsx"
                        Test-Path -Path "tests/output/download.tdsx" | Should -BeTrue
                        Remove-Item -Path "tests/output/download.tdsx" | Out-Null
                    }
                }
                Context "Publish live-to-Hyper assets on <ConfigFile.server>"  -Tag Hyper {
                    It "Publish initial Hyper file" {
                        $datasource = Publish-TableauDatasource -Name "World Indicators Data" -InFile './tests/assets/Misc/World Indicators.hyper' -ProjectId $samplesProjectId -Overwrite
                        $datasource.id | Should -BeOfType String
                        $script:hyperDatasourceId = $datasource.id
                    }
                    It "Conditional delete for published Hyper file" {
                        $action = @{action='delete';
                            'target-table'='Extract'; 'target-schema'='Extract';
                            'condition'=@{op='eq'; 'target-col'='Region'; const=@{type='string'; v='Europe'}}
                        }
                        $job = Update-TableauHyperData -InFile './tests/assets/Misc/World Indicators.hyper' -Action $action -DatasourceId $hyperDatasourceId
                        $job | Should -Not -BeNullOrEmpty
                        $job.type | Should -Be "updateUploadedFile"
                        $job.mode | Should -Be "Asynchronous"
                        $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                        Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                        if ($jobFinished.extractRefreshJob.notes) {
                            Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                        }
                        if ($jobFinished.statusNotes) {
                            $jobFinished.statusNotes.statusNote | ForEach-Object {
                                Write-Verbose ("Job status notes: {0}" -f $_.text)
                            }
                        }
                        $jobFinished.finishCode | Should -Be 0
                    }
                    It "Single table append for published Hyper file" {
                        $action = @{action='insert';
                            'source-table'='Extract'; 'source-schema'='Extract';
                            'target-table'='Extract'; 'target-schema'='Extract'
                        }
                        $job = Update-TableauHyperData -InFile './tests/assets/Misc/World Indicators.hyper' -Action $action -DatasourceId $hyperDatasourceId
                        $job | Should -Not -BeNullOrEmpty
                        $job.type | Should -Be "updateUploadedFile"
                        $job.mode | Should -Be "Asynchronous"
                        $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                        Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                        if ($jobFinished.extractRefreshJob.notes) {
                            Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                        }
                        if ($jobFinished.statusNotes) {
                            $jobFinished.statusNotes.statusNote | ForEach-Object {
                                Write-Verbose ("Job status notes: {0}" -f $_.text)
                            }
                        }
                        $jobFinished.finishCode | Should -Be 0
                    }
                    It "Single table append for published Hyper file (with connection)" {
                        $connection = Get-TableauDatasourceConnection -DatasourceId $hyperDatasourceId
                        $action = @{action='insert';
                            'source-table'='Extract'; 'source-schema'='Extract';
                            'target-table'='Extract'; 'target-schema'='Extract'
                        }
                        $job = Update-TableauHyperData -InFile './tests/assets/Misc/World Indicators.hyper' -Action $action -DatasourceId $hyperDatasourceId -ConnectionId $connection.id
                        $job | Should -Not -BeNullOrEmpty
                        $job.type | Should -Be "updateUploadedFile"
                        $job.mode | Should -Be "Asynchronous"
                        $jobFinished = Wait-TableauJob -JobId $job.id -Timeout 300
                        Write-Verbose ("Job completed at {0}, finish code: {1}" -f $jobFinished.completedAt, $jobFinished.finishCode)
                        if ($jobFinished.extractRefreshJob.notes) {
                            Write-Verbose ("Job notes: {0}" -f $jobFinished.extractRefreshJob.notes)
                        }
                        if ($jobFinished.statusNotes) {
                            $jobFinished.statusNotes.statusNote | ForEach-Object {
                                Write-Verbose ("Job status notes: {0}" -f $_.text)
                            }
                        }
                        $jobFinished.finishCode | Should -Be 0
                    }
                    # TODO more examples for different actions, see below:
                    # https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_how_to_update_data_to_hyper.htm#action-examples
                }
            }
        }
        Context "View operations" -Tag View {
            It "Get views on <ConfigFile.server>" {
                $views = Get-TableauView
                ($views | Measure-Object).Count | Should -BeGreaterThan 0
                $viewId = $views | Select-Object -First 1 -ExpandProperty id
                $viewId | Should -BeOfType String
                $view = Get-TableauView -ViewId $viewId
                $view.id | Should -Be $viewId
            }
            It "Query views with options on <ConfigFile.server>" {
                $viewName = Get-TableauView | Select-Object -First 1 -ExpandProperty name
                $views = Get-TableauView -Filter "name:eq:$viewName" -Sort name:asc -Fields id,name
                ($views | Measure-Object).Count | Should -BeGreaterOrEqual 1
                ($views | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
            }
            It "Query views for a workbook on <ConfigFile.server>" {
                $workbookId = Get-TableauWorkbook | Select-Object -First 1 -ExpandProperty id
                $views = Get-TableauView -WorkbookId $workbookId -IncludeUsageStatistics
                ($views | Measure-Object).Count | Should -BeGreaterThan 0
                $views | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                $views | Select-Object -First 1 -ExpandProperty usage | Should -Not -BeNullOrEmpty
            }
            Context "Download views from a sample workbook on <ConfigFile.server>" {
                BeforeAll {
                    $project = New-TableauProject -Name (New-Guid)
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                        $script:samplesProjectId = $null
                    }
                }
                It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                    $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                    $project.id | Should -Be $samplesProjectId
                    # Start-Sleep -s 3
                }
                It "Get sample view id from <ConfigFile.server>" {
                    $view = Get-TableauView -Filter "workbookName:eq:World Indicators","projectName:eq:$samplesProjectName","name:eq:Population" | Select-Object -First 1
                    # if (-not $view) { # fallback: perform filter in PS
                    #     $workbook = Get-TableauWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.name -eq "Superstore"} | Select-Object -First 1
                    #     $view = Get-TableauView | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.workbook.id -eq $workbook.id} | Select-Object -First 1
                    # }
                    $script:sampleViewId = $view.id
                    $sampleViewId | Should -BeOfType String
                    $script:sampleViewName = (Get-TableauView -ViewId $sampleViewId).name
                }
                It "Download sample view as PDF from <ConfigFile.server>" {
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "tests/output/$sampleViewName.pdf"
                    Test-Path -Path "tests/output/$sampleViewName.pdf" | Should -BeTrue
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "tests/output/$sampleViewName.pdf" -PageType 'A5' -PageOrientation 'Landscape' -MaxAge 1
                    Test-Path -Path "tests/output/$sampleViewName.pdf" | Should -BeTrue
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "tests/output/$sampleViewName.pdf" -VizWidth 500 -VizHeight 300
                    Test-Path -Path "tests/output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.pdf" | Out-Null
                }
                It "Query view preview image from <ConfigFile.server>" {
                    $view = Get-TableauView -ViewId $sampleViewId
                    Export-TableauViewImage -ViewId $sampleViewId -Workbook $view.workbook.id -OutFile "tests/output/$sampleViewName.png"
                    Test-Path -Path "tests/output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.png" | Out-Null
                }
                It "Download sample view as PNG from <ConfigFile.server>" {
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format image -OutFile "tests/output/$sampleViewName.png"
                    Test-Path -Path "tests/output/$sampleViewName.png" | Should -BeTrue
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format image -OutFile "tests/output/$sampleViewName.png" -Resolution high
                    Test-Path -Path "tests/output/$sampleViewName.png" | Should -BeTrue
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format image -OutFile "tests/output/$sampleViewName.png" -Resolution standard
                    Test-Path -Path "tests/output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.png" | Out-Null
                }
                It "Download sample workbook as CSV from <ConfigFile.server>" {
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format csv -OutFile "tests/output/$sampleViewName.csv"
                    Test-Path -Path "tests/output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.csv" | Out-Null
                }
                It "Download sample workbook as Excel from <ConfigFile.server>" {
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format excel -OutFile "tests/output/$sampleViewName.xlsx"
                    Test-Path -Path "tests/output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.xlsx" | Out-Null
                }
                It "Download sample view with data filters applied from <ConfigFile.server>" {
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "tests/output/$sampleViewName.pdf" -ViewFilters @{Region="Europe"}
                    Test-Path -Path "tests/output/$sampleViewName.pdf" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.pdf" | Out-Null
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format image -OutFile "tests/output/$sampleViewName.png" -ViewFilters @{Region="Africa"}
                    Test-Path -Path "tests/output/$sampleViewName.png" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.png" | Out-Null
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format csv -OutFile "tests/output/$sampleViewName.csv" -ViewFilters @{"Ease of Business (clusters)"="Low"}
                    Test-Path -Path "tests/output/$sampleViewName.csv" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.csv" | Out-Null
                    Export-TableauViewToFormat -ViewId $sampleViewId -Format excel -OutFile "tests/output/$sampleViewName.xlsx" -ViewFilters @{"Country/Region"="Kyrgyzstan"}
                    Test-Path -Path "tests/output/$sampleViewName.xlsx" | Should -BeTrue
                    Remove-Item -Path "tests/output/$sampleViewName.xlsx" | Out-Null
                }
                It "Add/remove tags for sample view on <ConfigFile.server>" {
                    Add-TableauContentTag -ViewId $sampleViewId -Tags "active","test" | Out-Null
                    ((Get-TableauView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TableauContentTag -ViewId $sampleViewId -Tag "test" | Out-Null
                    ((Get-TableauView -ViewId $sampleViewId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TableauContentTag -ViewId $sampleViewId -Tag "active" | Out-Null
                    (Get-TableauView -ViewId $sampleViewId).tags | Should -BeNullOrEmpty
                }
                It "Update sample workbook (showTabs=false) on <ConfigFile.server>" {
                    $workbook = Get-TableauWorkbook -Filter "name:eq:World Indicators","projectName:eq:$samplesProjectName"
                    # if (-not $workbook) { # fallback: perform filter in PS
                    #     $workbook = Get-TableauWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId -and $_.name -eq "Superstore"} | Select-Object -First 1
                    # }
                    $workbook.id | Should -BeOfType String
                    $workbook = Set-TableauWorkbook -WorkbookId $workbook.id -ShowTabs:$false
                    $workbook.showTabs | Should -Be "false"
                }
                It "Query/remove/add/set view permissions on <ConfigFile.server>" {
                    # note: setting permissions on views only supported on workbooks with ShowTabs=$false
                    $permissions = Get-TableauContentPermission -ViewId $sampleViewId
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $savedPermissionTable = $permissions | ConvertTo-TableauPermissionTable
                    # remove all permissions for all grantees
                    Remove-TableauContentPermission -ViewId $sampleViewId -All | Out-Null
                    $permissions = Get-TableauContentPermission -ViewId $sampleViewId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TableauContentPermission -ViewId $sampleViewId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','Delete','ChangePermissions' # 'ExportXml','Write','ChangeHierarchy','RunExplainData' capabilities are not supported (cf. Workbooks)
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TableauContentPermission -ViewId $sampleViewId -PermissionTable $allPermissionTable
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
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TableauContentPermission -ViewId $sampleViewId -PermissionTable $allPermissionTable
                    $permissions.view.id | Should -Be $sampleViewId
                    $permissions.view.name | Should -Be $sampleViewName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TableauContentPermission -ViewId $sampleViewId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                    $permissions = Get-TableauContentPermission -ViewId $sampleViewId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TableauContentPermission -ViewId $sampleViewId -PermissionTable $savedPermissionTable
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
                                    Remove-TableauContentPermission -ViewId $sampleViewId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode | Out-Null
                                }
                            }
                        }
                        $permissions = Get-TableauContentPermission -ViewId $sampleViewId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'Denied','View','None','Explore','Publish','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$pt}
                        $permissions = Set-TableauContentPermission -ViewId $sampleViewId -PermissionTable $permissionTable
                        $permissions.view.id | Should -Be $sampleViewId
                        $actualPermissionTable = Get-TableauContentPermission -ViewId $sampleViewId | ConvertTo-TableauPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; Filter="Allow"; ViewComments="Allow"; AddComment="Allow"; ExportImage="Allow"; ExportData="Allow"; ShareView="Allow"; ViewUnderlyingData="Allow"; WebAuthoring="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Deny"; Filter="Deny"; ViewComments="Deny"; AddComment="Deny"; ExportImage="Deny"; ExportData="Deny"; ShareView="Deny"; ViewUnderlyingData="Deny"; WebAuthoring="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
                }
                It "Get/hide/unhide view recommendations on <ConfigFile.server>" -Skip { #TODO add test for Get/hide/unhide view recommendations
                }
            }
            It "Get custom views on <ConfigFile.server>" -Skip { #TODO add tests for custom views
            }
            It "Update custom view on <ConfigFile.server>" -Skip {
            }
            It "Remove custom view on <ConfigFile.server>" -Skip {
            }
        }
        Context "Flow operations" -Tag Flow {
            Context "Get, publish, download sample flow on <ConfigFile.server>" {
                BeforeAll {
                    $project = New-TableauProject -Name (New-Guid)
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
                AfterAll {
                    if ($samplesProjectId) {
                        Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                        $script:samplesProjectId = $null
                    }
                }
                It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                    $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                    $project.id | Should -Be $samplesProjectId
                    # Start-Sleep -s 3
                }
                It "Get sample flow id from <ConfigFile.server>" {
                    $flow = Get-TableauFlow -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                    if (-not $flow) { # fallback: perform filter in PS
                        $flow = Get-TableauFlow | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
                    $script:sampleflowId = $flow.id
                    $script:sampleFlowName = $flow.name
                    $sampleflowId | Should -BeOfType String
                }
                It "Get flows on <ConfigFile.server>" {
                    $flows = Get-TableauFlow
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flowId = $flows | Select-Object -First 1 -ExpandProperty id
                    $flowId | Should -BeOfType String
                    $flow = Get-TableauFlow -FlowId $flowId
                    $flow.id | Should -Be $flowId
                    $connections = Get-TableauFlowConnection -FlowId $flowId
                    ($connections | Measure-Object).Count | Should -BeGreaterThan 0
                }
                It "Query flows with options on <ConfigFile.server>" {
                    $flowName = Get-TableauFlow | Select-Object -First 1 -ExpandProperty name
                    $flows = Get-TableauFlow -Filter "name:eq:$flowName" -Sort name:asc -Fields id,name
                    ($flows | Measure-Object).Count | Should -BeGreaterOrEqual 1
                    ($flows | Get-Member -MemberType Property | Measure-Object).Count | Should -BeGreaterOrEqual 2
                }
                It "Query flows for current user on <ConfigFile.server>" {
                    $flows = Get-TableauFlowsForUser -UserId (Get-TableauCurrentUserId)
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flows | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                    $flows = Get-TableauFlowsForUser -UserId (Get-TableauCurrentUserId) -IsOwner
                    ($flows | Measure-Object).Count | Should -BeGreaterThan 0
                    $flows | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                }
                It "Download sample flow from <ConfigFile.server>" {
                    Export-TableauFlow -FlowId $sampleflowId -OutFile "tests/output/$sampleFlowName.tflx"
                    Test-Path -Path "tests/output/$sampleFlowName.tflx" | Should -BeTrue
                }
                It "Publish sample flow on <ConfigFile.server>" {
                    $flow = Publish-TableauFlow -Name $sampleFlowName -InFile "tests/output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite
                    $flow.id | Should -BeOfType String
                    $script:sampleFlowId = $flow.id
                }
                It "Publish sample flow (chunks) on <ConfigFile.server>" {
                    $flow = Publish-TableauFlow -Name $sampleFlowName -InFile "tests/output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite -Chunked
                    $flow.id | Should -BeOfType String
                    $script:sampleFlowId = $flow.id
                }
                # It "Download & remove previous flow revision on <ConfigFile.server>" {
                #     Set-ItResult -Skipped -Because "flow revisions are currently not supported via REST API"
                #     $revisions = Get-TableauFlow -FlowId $sampleFlowId -Revisions
                #     if (($revisions | Measure-Object).Count -gt 1) {
                #         $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
                #         Export-TableauFlow -FlowId $sampleFlowId -Revision $revision -OutFile "tests/output/download_revision.tflx"
                #         Test-Path -Path "tests/output/download_revision.tflx" | Should -BeTrue
                #         Remove-Item -Path "tests/output/download_revision.tflx" | Out-Null
                #         Remove-TableauFlow -FlowId $sampleFlowId -Revision $revision | Out-Null
                #     } else {
                #         Set-ItResult -Skipped -Because "only one revision was found"
                #     }
                # }
                # It "Download latest flow revision on <ConfigFile.server>" -Skip {
                #     $revision = Get-TableauFlow -FlowId $sampleFlowId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
                #     Export-TableauFlow -FlowId $sampleFlowId -Revision $revision -OutFile "tests/output/download_revision.tflx"
                #     Test-Path -Path "tests/output/download_revision.tflx" | Should -BeTrue
                #     Remove-Item -Path "tests/output/download_revision.tflx" | Out-Null
                # }
                It "Add/remove tags for sample flow on <ConfigFile.server>" {
                    Add-TableauContentTag -FlowId $sampleFlowId -Tags "active","test" | Out-Null
                    ((Get-TableauFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 2
                    Remove-TableauContentTag -FlowId $sampleFlowId -Tag "test" | Out-Null
                    ((Get-TableauFlow -FlowId $sampleFlowId).tags.tag | Measure-Object).Count | Should -Be 1
                    Remove-TableauContentTag -FlowId $sampleFlowId -Tag "active" | Out-Null
                    (Get-TableauFlow -FlowId $sampleFlowId).tags | Should -BeNullOrEmpty
                }
                It "Query/remove/add/set flow permissions on <ConfigFile.server>" {
                    $permissions = Get-TableauContentPermission -FlowId $sampleFlowId
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $savedPermissionTable = $permissions | ConvertTo-TableauPermissionTable
                    # remove all permissions for all grantees
                    Remove-TableauContentPermission -FlowId $sampleFlowId -All | Out-Null
                    $permissions = Get-TableauContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # attempt to set permissions with empty capabilities
                    $permissions = Set-TableauContentPermission -FlowId $sampleFlowId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{}}
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add all possible permissions (random Allow/Deny) for the current user
                    $possibleCap = 'Read','ExportXml','Execute','WebAuthoringForFlows','Write','ChangeHierarchy','Delete','ChangePermissions'
                    $allPermissionTable = @()
                    $capabilitiesHashtable = @{}
                    foreach ($cap in $possibleCap) {
                        $capabilitiesHashtable.Add($cap, (Get-Random -InputObject 'Allow','Deny'))
                    }
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Add-TableauContentPermission -FlowId $sampleFlowId -PermissionTable $allPermissionTable
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
                    $allPermissionTable += @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=$capabilitiesHashtable}
                    $permissions = Set-TableauContentPermission -FlowId $sampleFlowId -PermissionTable $allPermissionTable
                    $permissions.flow.id | Should -Be $sampleFlowId
                    $permissions.flow.name | Should -Be $sampleFlowName
                    $permissions.granteeCapabilities | Should -Not -BeNullOrEmpty
                    ($permissions.granteeCapabilities.capabilities.capability | Measure-Object).Count | Should -Be $possibleCap.Length
                    # remove all permissions for the current user
                    Remove-TableauContentPermission -FlowId $sampleFlowId -GranteeType User -GranteeId (Get-TableauCurrentUserId) | Out-Null
                    $permissions = Get-TableauContentPermission -FlowId $sampleFlowId
                    $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    # add back initial permissions configuration
                    if ($savedPermissionTable.Length -gt 0) {
                        $permissions = Add-TableauContentPermission -FlowId $sampleFlowId -PermissionTable $savedPermissionTable
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
                                    Remove-TableauContentPermission -FlowId $sampleFlowId -GranteeType $granteeType -GranteeId $granteeId -CapabilityName $capName -CapabilityMode $capMode | Out-Null
                                }
                            }
                        }
                        $permissions = Get-TableauContentPermission -FlowId $sampleFlowId
                        $permissions.granteeCapabilities | Should -BeNullOrEmpty
                    }
                    # permissions by template for the current user
                    foreach ($pt in 'View','Explore','None','Publish','Denied','Administer') {
                        $permissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); template=$pt}
                        $permissions = Set-TableauContentPermission -FlowId $sampleFlowId -PermissionTable $permissionTable
                        $permissions.flow.id | Should -Be $sampleFlowId
                        $actualPermissionTable = Get-TableauContentPermission -FlowId $sampleFlowId | ConvertTo-TableauPermissionTable
                        switch ($pt) {
                            'View' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"}}
                            }
                            'Explore' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"}}
                            }
                            'Publish' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"; Execute="Allow"; Write="Allow"; WebAuthoringForFlows="Allow"}}
                            }
                            'Administer' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"; ExportXml="Allow"; Execute="Allow"; Write="Allow"; WebAuthoringForFlows="Allow"; ChangeHierarchy="Allow"; Delete="Allow"; ChangePermissions="Allow"}}
                            }
                            'Denied' {
                                $expectedPermissionTable = @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Deny"; ExportXml="Deny"; Execute="Deny"; Write="Deny"; WebAuthoringForFlows="Deny"; ChangeHierarchy="Deny"; Delete="Deny"; ChangePermissions="Deny"}}
                            }
                            default {
                                $expectedPermissionTable = $null
                            }
                        }
                        Assert-Equivalent -Actual $actualPermissionTable -Expected $expectedPermissionTable
                    }
                }
                It "Remove sample flow on <ConfigFile.server>" {
                    Remove-TableauFlow -FlowId $sampleFlowId | Out-Null
                }
                It "Publish flow with invalid extension on <ConfigFile.server>" {
                    {Publish-TableauFlow -Name "Flow" -InFile "tests/assets/Misc/Flow.txt" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish flow with invalid contents on <ConfigFile.server>" {
                    {Publish-TableauFlow -Name "invalid" -InFile "tests/assets/Misc/invalid.tflx" -ProjectId $samplesProjectId} | Should -Throw
                }
                It "Publish and check flow with output steps on <ConfigFile.server>" -Skip { #TODO flow tests with output steps
                    $flow = Publish-TableauFlow -Name $sampleFlowName -InFile "tests/output/$sampleFlowName.tflx" -ProjectId $samplesProjectId -Overwrite
                    $flow.id | Should -BeOfType String
                    $outputSteps = Get-TableauFlow -FlowId $flow.id -OutputSteps
                    ($outputSteps | Measure-Object).Count | Should -BeGreaterThan 0
                    $outputSteps.id | Select-Object -First 1 -ExpandProperty id | Should -BeOfType String
                }
                It "Publish flow with connections on <ConfigFile.server>" -Skip { #TODO flow tests with connections
                    Publish-TableauFlow -Name "Flow" -InFile "tests/assets/Misc/Flow.txt" -ProjectId $samplesProjectId
                }
                It "Publish flow with credentials on <ConfigFile.server>" -Skip { #TODO flow tests with credentials
                    Publish-TableauFlow -Name "Flow" -InFile "tests/assets/Misc/Flow.txt" -ProjectId $samplesProjectId
                }
                Context "Publish / download flows from test assets on <ConfigFile.server>" -Tag FlowSamples -ForEach $FlowFiles {
                    BeforeAll {
                        $script:sampleFlowName = (Get-Item -LiteralPath $_).BaseName
                        $script:sampleFlowFileName = (Get-Item -LiteralPath $_).Name
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server>" {
                        $flow = Publish-TableauFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Publish file ""<sampleFlowFileName>"" into flow ""<sampleFlowName>"" on <ConfigFile.server> (Chunked)" {
                        $flow = Publish-TableauFlow -Name $sampleFlowName -InFile $_ -ProjectId $samplesProjectId -Overwrite -Chunked
                        $flow.id | Should -BeOfType String
                        $script:sampleflowId = $flow.id
                    }
                    It "Download flow ""<sampleFlowName>"" from <ConfigFile.server>" {
                        Export-TableauFlow -FlowId $sampleflowId -OutFile "tests/output/download.tflx"
                        Test-Path -Path "tests/output/download.tflx" | Should -BeTrue
                        Remove-Item -Path "tests/output/download.tflx" | Out-Null
                    }
                }
            }
        }
        Context "Content filtering" -Tag QueryFilter {
            BeforeAll {
                $project = New-TableauProject -Name (New-Guid)
                $script:samplesProjectId = $project.id
                $script:samplesProjectName = $project.name
            }
            AfterAll {
                if ($samplesProjectId) {
                    Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                    $script:samplesProjectId = $null
                }
            }
            It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                $project.id | Should -Be $samplesProjectId
                # Start-Sleep -s 3
            }
            It "Filter users on <ConfigFile.server>" {
                $user = Get-TableauUser -UserId (Get-TableauCurrentUserId)
                Get-TableauUser -Filter "name:eq:$($user.name)" | Should -Not -BeNullOrEmpty
                Get-TableauUser -Filter "siteRole:eq:$($user.siteRole)" | Should -Not -BeNullOrEmpty
                Get-TableauUser -Filter "friendlyName:eq:$($user.fullName)" | Should -Not -BeNullOrEmpty
            }
            It "Filter groups on <ConfigFile.server>" {
                Get-TableauGroup -Filter "name:eq:All Users" | Should -Not -BeNullOrEmpty
                Get-TableauGroup -Filter "isLocal:eq:true" | Should -Not -BeNullOrEmpty
            }
            It "Filter projects on <ConfigFile.server>" {
                $project = Get-TableauProject -Filter "name:eq:$samplesProjectName"
                $project | Should -Not -BeNullOrEmpty
                Get-TableauProject -Filter "name:eq:Default","topLevelProject:eq:true" | Should -Not -BeNullOrEmpty
            }
            It "Filter workbooks on <ConfigFile.server>" {
                $workbook = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                $workbook | Should -Not -BeNullOrEmpty
                Get-TableauWorkbook -Filter "name:eq:$($workbook.name)" | Should -Not -BeNullOrEmpty
                Get-TableauWorkbook -Filter "contentUrl:eq:$($workbook.contentUrl)" | Should -Not -BeNullOrEmpty
                Get-TableauWorkbook -Filter "displayTabs:eq:$($workbook.showTabs)" | Should -Not -BeNullOrEmpty
            }
            It "Filter views by project name on <ConfigFile.server>" {
                $workbook = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                $view = Get-TableauView -Filter "projectName:eq:$samplesProjectName" -Fields id,name,sheetType,contentUrl | Select-Object -First 1
                $view | Should -Not -BeNullOrEmpty
                $viewUrl = $view.contentUrl.Split("/")[-1]
                Get-TableauView -Filter "name:eq:$($view.name)" | Should -Not -BeNullOrEmpty
                Get-TableauView -Filter "sheetType:eq:$($view.sheetType)" | Should -Not -BeNullOrEmpty
                Get-TableauView -Filter "viewUrlName:eq:$viewUrl" | Should -Not -BeNullOrEmpty
                Get-TableauView -Filter "workbookName:eq:$($workbook.name)" | Should -Not -BeNullOrEmpty
            }
            # It "Filter custom views by <> on <ConfigFile.server>" {
            # }
            It "Filter datasources by project name on <ConfigFile.server>" {
                if ((Get-TableauRestVersion) -lt [version]3.13 -or (Get-TableauRestVersion) -gt [version]3.17) { # this filter doesn't work in API 3.13 to 3.17
                    $datasources = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName"
                    $datasources.Length | Should -BeGreaterThan 0
                } else {
                    Write-Verbose "Filtering by projectName doesn't work for datasources in this version"
                }
                $datasource = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                $datasource | Should -Not -BeNullOrEmpty
                Get-TableauDatasource -Filter "name:eq:$($datasource.name)" | Should -Not -BeNullOrEmpty
            }
            It "Filter flows by project name on <ConfigFile.server>" {
                $flow = Get-TableauFlow -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 1
                $flow | Should -Not -BeNullOrEmpty
                Get-TableauFlow -Filter "projectId:eq:$($samplesProjectId)" | Should -Not -BeNullOrEmpty
                Get-TableauFlow -Filter "name:eq:$($flow.name)" | Should -Not -BeNullOrEmpty
            }
            It "Filter flow runs on <ConfigFile.server>" {
                $flowRun = Get-TableauFlowRun | Select-Object -First 1
                if ($flowRun) {
                    Get-TableauFlowRun -Filter "flowId:eq:$($flowRun.flowId)" | Should -Not -BeNullOrEmpty
                } else {
                    Set-ItResult -Skipped -Because "flow runs not found"
                }
            }
            It "Filter jobs on <ConfigFile.server>" {
                $job = Get-TableauJob | Select-Object -First 1
                if ($job) {
                    Get-TableauJob -Filter "jobType:eq:$($job.jobType)" | Should -Not -BeNullOrEmpty
                    Get-TableauJob -Filter "priority:eq:$($job.priority)" | Should -Not -BeNullOrEmpty
                } else {
                    Set-ItResult -Skipped -Because "jobs not found"
                }
            }
            # It "Filter metrics by <> on <ConfigFile.server>" {
            # }
        }
        Context "Favorite operations" -Tag Favorite {
            BeforeAll {
                $project = New-TableauProject -Name (New-Guid)
                $script:samplesProjectId = $project.id
                $script:samplesProjectName = $project.name
            }
            AfterAll {
                if ($samplesProjectId) {
                    Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                    $script:samplesProjectId = $null
                }
            }
            It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                $project.id | Should -Be $samplesProjectId
                # Start-Sleep -s 3
            }
            It "Add sample contents to user favorites on <ConfigFile.server>" {
                Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -ProjectId $samplesProjectId
                $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName"
                # if (-not $workbooks) { # fallback: perform filter in PS
                #     $workbooks = Get-TableauWorkbook | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                # }
                $workbooks | ForEach-Object {
                    Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -WorkbookId $_.id
                }
                $datasources = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName"
                if (-not $datasources) { # fallback: perform filter in PS
                    $datasources = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                }
                $datasources | ForEach-Object {
                    Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -DatasourceId $_.id
                }
                $views = Get-TableauView -Filter "projectName:eq:$samplesProjectName"
                # if (-not $views) { # fallback: perform filter in PS
                #     $views = Get-TableauView | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                # }
                $views | ForEach-Object {
                    Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -ViewId $_.id
                }
                $flows = Get-TableauFlow -Filter "projectName:eq:$samplesProjectName"
                # if (-not $flows) { # fallback: perform filter in PS
                #     $flows = Get-TableauFlow | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                # }
                $flows | ForEach-Object {
                    Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FlowId $_.id
                }
            }
            It "Get/reorder user favorites for sample contents on <ConfigFile.server>" {
                $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName"
                $workbook_id = $workbooks | Select-Object -First 1 -ExpandProperty id
                $datasources = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName"
                if (-not $datasources) { # fallback: perform filter in PS
                    $datasources = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId}
                }
                $datasource_id = $datasources | Select-Object -First 1 -ExpandProperty id
                $views = Get-TableauView -Filter "projectName:eq:$samplesProjectName"
                $totalCount = $datasources.Length + $workbooks.Length + $views.Length
                $favorites = Get-TableauUserFavorite -UserId (Get-TableauCurrentUserId)
                ($favorites | Measure-Object).Count | Should -BeGreaterThan $totalCount
                # swap favorites order for first workbook/datasource and sample
                $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                # if ($workbook_id) {
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeLessThan $pos_project
                    Move-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FavoriteId $workbook_id -FavoriteType Workbook -AfterFavoriteId $samplesProjectId -AfterFavoriteType Project
                    $favorites = Get-TableauUserFavorite -UserId (Get-TableauCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook = $favorites | Where-Object -FilterScript {$_.workbook.id -eq $workbook_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_workbook | Should -BeGreaterThan $pos_project
                # }
                # if ($datasource_id) {
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeLessThan $pos_project
                    Move-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FavoriteId $datasource_id -FavoriteType Datasource -AfterFavoriteId $samplesProjectId -AfterFavoriteType Project
                    $favorites = Get-TableauUserFavorite -UserId (Get-TableauCurrentUserId)
                    $pos_project = $favorites | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource = $favorites | Where-Object -FilterScript {$_.datasource.id -eq $datasource_id} | Select-Object -First 1 -ExpandProperty position
                    $pos_datasource | Should -BeGreaterThan $pos_project
                # }
                if ($views.Length -ge 2) {
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 | Should -BeLessThan $pos_view0
                    Move-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FavoriteId $views[1].id -FavoriteType View -AfterFavoriteId $views[0].id -AfterFavoriteType View
                    $favorites = Get-TableauUserFavorite -UserId (Get-TableauCurrentUserId)
                    $pos_view0 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[0].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1 = $favorites | Where-Object -FilterScript {$_.view.id -eq $views[1].id} | Select-Object -First 1 -ExpandProperty position
                    $pos_view1| Should -BeGreaterThan $pos_view0
                }
            }
            It "Remove sample contents from user favorites on <ConfigFile.server>" {
                Remove-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -ProjectId $samplesProjectId | Out-Null
                $datasources = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName"
                if (-not $datasources) { # fallback: perform filter in PS
                    $datasources = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId}
                }
                $datasources | ForEach-Object {
                    Remove-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -DatasourceId $_.id | Out-Null
                }
                Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -WorkbookId $_.id | Out-Null
                }
                Get-TableauView -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -ViewId $_.id | Out-Null
                }
                Get-TableauFlow -Filter "projectName:eq:$samplesProjectName" | ForEach-Object {
                    Remove-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FlowId $_.id | Out-Null
                }
            }
        }
        Context "Server schedule operations" -Tag ServerSchedule {
            It "Add new schedule on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $scheduleName = New-Guid
                    $schedule = New-TableauSchedule -Name $scheduleName -Type Extract -Frequency Daily -StartTime "11:30:00"
                    $schedule.id | Should -BeOfType String
                    $script:testScheduleId = $schedule.id
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Update schedule <testScheduleId> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $testScheduleId) {
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -State Suspended -Priority 10 -Frequency Daily -StartTime "13:45:00"
                    $schedule.state | Should -Be "Suspended"
                    $schedule.priority | Should -Be 10
                    $schedule.frequencyDetails.start | Should -Be "13:45:00"
                    $scheduleNewName = New-Guid
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Name $scheduleNewName -State Active -ExecutionOrder Serial
                    $schedule.state | Should -Be "Active"
                    $schedule.executionOrder | Should -Be "Serial"
                    $schedule.name | Should -Be $scheduleNewName
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "16:00:00" -IntervalHours 1
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.start | Should -Be "12:00:00"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "1"
                    $schedule.frequencyDetails.end | Should -Be "16:00:00"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "18:00:00" -IntervalHours 2
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "2"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 4
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "4"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 6
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "6"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "18:00:00" -IntervalHours 8
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "8"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "08:00:00" -EndTime "22:00:00" -IntervalHours 12
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.intervals.interval.hours | Should -Be "12"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "14:00:00" -EndTime "15:30:00" -IntervalMinutes 30
                    $schedule.frequency | Should -Be "Hourly"
                    $schedule.frequencyDetails.start | Should -Be "14:00:00"
                    $schedule.frequencyDetails.intervals.interval.minutes | Should -Be "30"
                    $schedule.frequencyDetails.end | Should -Be "15:30:00"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Daily -StartTime "14:30:00" -EndTime "15:00:00" -IntervalMinutes 15
                    $schedule.frequency | Should -Be "Daily"
                    $schedule.frequencyDetails.start | Should -Be "14:30:00"
                    $schedule.frequencyDetails.end | Should -BeNullOrEmpty
                    $schedule.frequencyDetails.intervals.interval.minutes | Should -BeNullOrEmpty
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Weekly -StartTime "10:00:00" -IntervalWeekdays Sunday
                    $schedule.frequency | Should -Be "Weekly"
                    $schedule.frequencyDetails.start | Should -Be "10:00:00"
                    $schedule.frequencyDetails.intervals.interval | Should -HaveCount 1
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Be "Sunday"
                    $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Weekly -StartTime "10:00:00" -IntervalWeekdays Monday,Wednesday
                    $schedule.frequency | Should -Be "Weekly"
                    $schedule.frequencyDetails.intervals.interval | Should -HaveCount 2
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Contain "Monday"
                    $schedule.frequencyDetails.intervals.interval.weekDay | Should -Contain "Wednesday"
                    # note: updating monthly schedule via REST API doesn't seem to work
                    # $schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3
                    # $schedule.frequency | Should -Be "Monthly"
                    # $schedule.frequencyDetails.start | Should -Be "08:00:00"
                    # $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "3"
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Query schedules on <ConfigFile.server>" {
                $schedules = Get-TableauSchedule
                ($schedules | Measure-Object).Count | Should -BeGreaterThan 0
                if ($testScheduleId) {
                    $schedules | Where-Object id -eq $testScheduleId | Should -Not -BeNullOrEmpty
                    $schedule = Get-TableauSchedule -ScheduleId $testScheduleId
                    $schedule.id | Should -Be $testScheduleId
                } else {
                    $firstScheduleId = $schedules | Select-Object -First 1 -ExpandProperty id
                    $schedule = Get-TableauSchedule -ScheduleId $firstScheduleId
                    $schedule.id | Should -Be $firstScheduleId
                }
            }
            It "Query extract refresh tasks on <ConfigFile.server>" {
                $extractScheduleId = Get-TableauSchedule | Where-Object type -eq "Extract" | Select-Object -First 1 -ExpandProperty id
                (Get-TableauExtractRefreshTask -ScheduleId $extractScheduleId | Measure-Object).Count | Should -BeGreaterOrEqual 0
            }
            It "Remove schedule <testScheduleId> on <ConfigFile.server>" {
                if ($ConfigFile.server_admin -and $testScheduleId) {
                    $response = Remove-TableauSchedule -ScheduleId $testScheduleId
                    $response | Should -BeOfType String
                    $script:testScheduleId = $null
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
            It "Add/remove monthly schedule on <ConfigFile.server>" {
                if ($ConfigFile.server_admin) {
                    $schedule = New-TableauSchedule -Name (New-Guid) -Type Extract -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3
                    $schedule.frequency | Should -Be "Monthly"
                    $schedule.state | Should -Be "Active"
                    $schedule.type | Should -Be "Extract"
                    $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "3"
                    $response = Remove-TableauSchedule -ScheduleId $schedule.id
                    $response | Should -BeOfType String
                    $schedule = New-TableauSchedule -Name (New-Guid) -Type Subscription -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 0
                    $schedule.frequency | Should -Be "Monthly"
                    $schedule.state | Should -Be "Active"
                    $schedule.type | Should -Be "Subscription"
                    $schedule.frequencyDetails.intervals.interval.monthDay | Should -Be "LastDay"
                    $response = Remove-TableauSchedule -ScheduleId $schedule.id
                    $response | Should -BeOfType String
                } else {
                    Set-ItResult -Skipped -Because "Server admin privileges required"
                }
            }
        }
        Context "Common schedule operations" -Tag Schedule {
            BeforeAll {
                if (-Not $ConfigFile.tableau_cloud) {
                    $project = New-TableauProject -Name (New-Guid)
                    $script:samplesProjectId = $project.id
                    $script:samplesProjectName = $project.name
                }
            }
            AfterAll {
                if ($samplesProjectId) {
                    Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                    $script:samplesProjectId = $null
                }
            }
            It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                if ($samplesProjectId) {
                    $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                    $project.id | Should -Be $samplesProjectId
                    # Start-Sleep -s 3
                } else {
                    Set-ItResult -Skipped -Because "sample project doesn't exist"
                }
            }
            It "Add extract refresh tasks into a schedule on <ConfigFile.server>" {
                if (-Not $ConfigFile.tableau_cloud) {
                    $extractScheduleId = Get-TableauSchedule | Where-Object type -eq "Extract" | Select-Object -First 1 -ExpandProperty id
                    $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName"
                    $workbooks | ForEach-Object {
                        Add-TableauContentToSchedule -ScheduleId $extractScheduleId -WorkbookId $_.id | Out-Null
                    }
                    $datasources = Get-TableauDatasource -Filter "projectName:eq:$samplesProjectName"
                    if (-not $datasources) { # fallback: perform filter in PS
                        $datasources = Get-TableauDatasource | Where-Object -FilterScript {$_.project.id -eq $samplesProjectId} | Select-Object -First 1
                    }
                    $datasources | ForEach-Object {
                        Add-TableauContentToSchedule -ScheduleId $extractScheduleId -DatasourceId $_.id | Out-Null
                    }
                } else {
                    Set-ItResult -Skipped -Because "feature not available for Tableau Cloud"
                }
                (Get-TableauExtractRefreshTask -ScheduleId $extractScheduleId | Measure-Object).Count | Should -BeGreaterThan 0
            }
        }
        Context "Tasks operations" -Tag Task {
            BeforeAll {
                $project = New-TableauProject -Name (New-Guid)
                $script:samplesProjectId = $project.id
                $script:samplesProjectName = $project.name
            }
            AfterAll {
                if ($samplesProjectId) {
                    Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                    $script:samplesProjectId = $null
                    $script:workbookForTasks = $null
                    $script:datasourceForTasks = $null
                    $script:flowForTasks = $null
                }
            }
            It "Publish test content into project <samplesProjectName> on <ConfigFile.server>" {
                $securePw = Get-SecurePassword -Namespace "asl-tableau-testsql" -Username "sqladmin"
                $credentials = @{username="sqladmin"; password=$securePw; embed="true" }
                $script:workbookForTasks = Publish-TableauWorkbook -Name "AW Customer Address" -InFile "tests/assets/Misc/AW_Customer_Address.twbx" -ProjectId $samplesProjectId -Credentials $credentials
                $script:workbookForTasks | Should -Not -BeNullOrEmpty
                $script:datasourceForTasks = Publish-TableauDatasource -Name "AW SalesOrders" -InFile "tests/assets/Misc/AW_SalesOrders.tdsx" -ProjectId $samplesProjectId -Credentials $credentials
                $script:datasourceForTasks | Should -Not -BeNullOrEmpty
                $connections = @( @{serverAddress="asl-tableau-testsql.database.windows.net"; serverPort="3389"; credentials=@{username="sqladmin"; password=$securePw; embed="true" }} )
                $script:flowForTasks = Publish-TableauFlow -Name "AW ProductDescription Flow" -InFile "tests/assets/Misc/AW_ProductDescription.tfl" -ProjectId $samplesProjectId -Connections $connections
                $script:flowForTasks | Should -Not -BeNullOrEmpty
                # Start-Sleep -s 3
            }
            It "Schedule and run extract refresh tasks on <ConfigFile.server>" {
                if (-Not $ConfigFile.tableau_cloud) {
                    $extractScheduleId = Get-TableauSchedule | Where-Object type -eq "Extract" | Select-Object -First 1 -ExpandProperty id
                    Write-Verbose "Extract schedule $extractScheduleId found"
                    Write-Verbose ("Adding workbook {0}" -f $workbookForTasks.id)
                    $contentScheduleTask = Add-TableauContentToSchedule -ScheduleId $extractScheduleId -WorkbookId $workbookForTasks.id
                    $extractTaskId = Get-TableauTask -Type ExtractRefresh | Where-Object -FilterScript {$_.workbook.id -eq $workbookForTasks.id} | Select-Object -First 1 -ExpandProperty id
                    $extractTaskId | Should -Be $contentScheduleTask.extractRefresh.id
                    Write-Verbose "Extract task id: $extractTaskId"
                    $job = Start-TableauTaskNow -Type ExtractRefresh -TaskId $extractTaskId
                    $job | Should -Not -BeNullOrEmpty
                    Stop-TableauJob -JobId $job.id
                    Remove-TableauTask -Type ExtractRefresh -TaskId $extractTaskId | Out-Null
                    Write-Verbose ("Adding datasource {0}" -f $datasourceForTasks.id)
                    $contentScheduleTask = Add-TableauContentToSchedule -ScheduleId $extractScheduleId -DatasourceId $datasourceForTasks.id
                    $extractTaskId = Get-TableauTask -Type ExtractRefresh | Where-Object -FilterScript {$_.datasource.id -eq $datasourceForTasks.id} | Select-Object -First 1 -ExpandProperty id
                    $extractTaskId | Should -Be $contentScheduleTask.extractRefresh.id
                    Write-Verbose "Extract task id: $extractTaskId"
                    $job = Start-TableauTaskNow -Type ExtractRefresh -TaskId $extractTaskId
                    $job | Should -Not -BeNullOrEmpty
                    Stop-TableauJob -JobId $job.id
                    Remove-TableauTask -Type ExtractRefresh -TaskId $extractTaskId | Out-Null
                } else { # Tableau Cloud methods
                    Write-Verbose ("Adding workbook {0}" -f $workbookForTasks.id)
                    $extractTaskResult = New-TableauCloudExtractRefreshTask -WorkbookId $workbookForTasks.id -Type FullRefresh -Frequency Daily -StartTime 12:00:00 -IntervalWeekdays 'Sunday','Monday'
                    $extractTaskResult | Should -Not -BeNullOrEmpty
                    $extractTaskId = Get-TableauTask -Type ExtractRefresh | Where-Object -FilterScript {$_.workbook.id -eq $workbookForTasks.id} | Select-Object -First 1 -ExpandProperty id
                    $extractTaskId | Should -Be $extractTaskResult.extractRefresh.id
                    Write-Verbose "Extract task id: $extractTaskId"
                    # HTTP 405 The HTTP method 'PUT' is not supported for the given resource
                    # $extractTaskResult = Set-TableauCloudExtractRefreshTask -TaskId $extractTaskId -WorkbookId $workbookForTasks.id -Type FullRefresh -Frequency Daily -StartTime 08:00:00 -EndTime 20:00:00 -IntervalHours 6 -IntervalWeekdays 'Tuesday'
                    # $extractTaskResult | Should -Not -BeNullOrEmpty
                    $job = Start-TableauTaskNow -Type ExtractRefresh -TaskId $extractTaskId
                    $job | Should -Not -BeNullOrEmpty
                    Stop-TableauJob -JobId $job.id
                    Remove-TableauTask -Type ExtractRefresh -TaskId $extractTaskId | Out-Null
                    Write-Verbose ("Adding datasource {0}" -f $datasourceForTasks.id)
                    $extractTaskResult = New-TableauCloudExtractRefreshTask -DatasourceId $datasourceForTasks.id -Type FullRefresh -Frequency Daily -StartTime 12:00:00 -EndTime 20:00:00 -IntervalHours 2 -IntervalWeekdays 'Sunday','Monday'
                    $extractTaskResult | Should -Not -BeNullOrEmpty
                    $extractTaskId = Get-TableauTask -Type ExtractRefresh | Where-Object -FilterScript {$_.datasource.id -eq $datasourceForTasks.id} | Select-Object -First 1 -ExpandProperty id
                    $extractTaskId | Should -Be $extractTaskResult.extractRefresh.id
                    Write-Verbose "Extract task id: $extractTaskId"
                    # HTTP 405 The HTTP method 'PUT' is not supported for the given resource
                    # $extractTaskResult = Set-TableauCloudExtractRefreshTask -TaskId $extractTaskId -DatasourceId $datasourceForTasks.id -Type FullRefresh -Frequency Monthly -StartTime 08:00:00 -IntervalMonthdays 1,15
                    # $extractTaskResult | Should -Not -BeNullOrEmpty
                    $job = Start-TableauTaskNow -Type ExtractRefresh -TaskId $extractTaskId
                    $job | Should -Not -BeNullOrEmpty
                    Stop-TableauJob -JobId $job.id
                    Remove-TableauTask -Type ExtractRefresh -TaskId $extractTaskId | Out-Null
                }
            }
            It "Schedule and run flow task on <ConfigFile.server>" {
                if (-Not $ConfigFile.tableau_cloud) {
                    if ($ConfigFile.prep_conductor) {
                        $runFlowScheduleId = Get-TableauSchedule | Where-Object type -eq "Flow" | Select-Object -First 1 -ExpandProperty id
                        Write-Verbose "Flow schedule $runFlowScheduleId found"
                        $contentScheduleTask = Add-TableauContentToSchedule -ScheduleId $runFlowScheduleId -FlowId $flowForTasks.id
                        $flowTaskId = Get-TableauTask -Type FlowRun | Where-Object -FilterScript {$_.flow.id -eq $flowForTasks.id} | Select-Object -First 1 -ExpandProperty id
                        $flowTaskId | Should -Be $contentScheduleTask.flowRun.id
                        Write-Verbose "Flow task id: $flowTaskId"
                        $job = Start-TableauTaskNow -Type FlowRun -TaskId $flowTaskId
                        $job | Should -Not -BeNullOrEmpty
                        Stop-TableauJob -JobId $job.id
                    } else {
                        Set-ItResult -Skipped -Because "Prep Conductor is not configured"
                    }
                } else { # TODO Tableau Cloud methods
                    Set-ItResult -Skipped
                }
            }
        }
        Context "Subscription operations" -Tag Subscription {
            BeforeAll {
                $project = New-TableauProject -Name (New-Guid)
                $script:samplesProjectId = $project.id
                $script:samplesProjectName = $project.name
            }
            AfterAll {
                if ($samplesProjectId) {
                    Remove-TableauProject -ProjectId $samplesProjectId | Out-Null
                    $script:samplesProjectId = $null
                }
            }
            It "Publish samples into project <samplesProjectName> on <ConfigFile.server>" {
                $project = Set-TableauProject -ProjectId $samplesProjectId -PublishSamples
                $project.id | Should -Be $samplesProjectId
                # Start-Sleep -s 3
            }
            It "Add/update subscriptions on <ConfigFile.server>" {
                if ($ConfigFile.tableau_cloud) {
                    $views = Get-TableauView -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 2
                    $views | ForEach-Object {
                        Write-Verbose ("Adding subscription for view '{0}'" -f $_.name)
                        $subscription = New-TableauSubscription -ContentType View -ContentId $_.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId) -Frequency Weekly -StartTime 12:00:00 -IntervalWeekdays 'Sunday'
                        $subscription | Should -Not -BeNullOrEmpty
                        $subscription = Set-TableauSubscription -SubscriptionId $subscription.id -ContentType View -ContentId $_.id -Subject "test1" -Message "Test subscription1" -UserId (Get-TableauCurrentUserId) -Frequency Monthly -StartTime 14:00:00 -IntervalMonthdays 5,10
                        $subscription | Should -Not -BeNullOrEmpty
                    }
                    $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 2
                    $workbooks | ForEach-Object {
                        Write-Verbose ("Adding subscription for workbook '{0}'" -f $_.name)
                        $subscription = New-TableauSubscription -ContentType Workbook -ContentId $_.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId) -Frequency Weekly -StartTime 12:00:00 -IntervalWeekdays 'Sunday'
                        $subscription | Should -Not -BeNullOrEmpty
                        $subscription = Set-TableauSubscription -SubscriptionId $subscription.id -ContentType Workbook -ContentId $_.id -Subject "test1" -Message "Test subscription1" -UserId (Get-TableauCurrentUserId) -Frequency Monthly -StartTime 14:00:00 -IntervalMonthdays 5,10
                        $subscription | Should -Not -BeNullOrEmpty
                    }
                } else {
                    $subscriptionScheduleId = Get-TableauSchedule | Where-Object type -eq "Subscription" | Select-Object -First 1 -ExpandProperty id
                    $views = Get-TableauView -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 2
                    $views | ForEach-Object {
                        Write-Verbose ("Adding view '{0}' to subscription schedule {1}" -f $_.name, $subscriptionScheduleId)
                        $subscription = New-TableauSubscription -ScheduleId $subscriptionScheduleId -ContentType View -ContentId $_.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId)
                        $subscription | Should -Not -BeNullOrEmpty
                        $subscription = Set-TableauSubscription -SubscriptionId $subscription.id -ScheduleId $subscriptionScheduleId -ContentType View -ContentId $_.id -SendIfViewEmpty false -Subject "test1" -Message "Test subscription1"
                        $subscription | Should -Not -BeNullOrEmpty
                    }
                    $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$samplesProjectName" | Select-Object -First 2
                    $workbooks | ForEach-Object {
                        Write-Verbose ("Adding workbook '{0}' to subscription schedule {1}" -f $_.name, $subscriptionScheduleId)
                        $subscription = New-TableauSubscription -ScheduleId $subscriptionScheduleId -ContentType Workbook -ContentId $_.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId)
                        $subscription | Should -Not -BeNullOrEmpty
                        $subscription = Set-TableauSubscription -SubscriptionId $subscription.id -ScheduleId $subscriptionScheduleId -ContentType Workbook -ContentId $_.id -Subject "test1" -Message "Test subscription1"
                        $subscription | Should -Not -BeNullOrEmpty
                    }
                }
            }
            It "Get subscriptions on <ConfigFile.server>" {
                $subscriptions = Get-TableauSubscription
                $subscriptions | Should -Not -BeNullOrEmpty
                $subscriptionId = $subscriptions | Select-Object -First 1 -ExpandProperty id
                $subscription = Get-TableauSubscription -SubscriptionId $subscriptionId
                $subscription | Should -Not -BeNullOrEmpty
            }
            It "Remove subscription on <ConfigFile.server>" {
                $subscriptionId = Get-TableauSubscription | Select-Object -First 1 -ExpandProperty id
                $subscriptionId | Should -Not -BeNullOrEmpty
                Remove-TableauSubscription -SubscriptionId $subscriptionId | Out-Null
            }
        }
        Context "Metadata operations" -Tag Metadata {
            It "Query databases on <ConfigFile.server>" -Skip {
                # TODO Query databases doesn't work for some reason
                $databases = Get-TableauDatabase
                ($databases | Measure-Object).Count | Should -BeGreaterThan 0
                $databaseId = $databases | Select-Object -First 1 -ExpandProperty id
                $databaseId | Should -BeOfType String
                $database = Get-TableauDatabase -DatabaseId $databaseId
                $database.id | Should -Be $databaseId
            }
            It "Query tables on <ConfigFile.server>" {
                $tables = Get-TableauTable
                ($tables | Measure-Object).Count | Should -BeGreaterThan 0
                $script:tableId = $tables | Select-Object -First 1 -ExpandProperty id
                $script:tableId | Should -BeOfType String
                $table = Get-TableauTable -TableId $script:tableId
                $table.id | Should -Be $script:tableId
            }
            It "Query columns in <tableId> on <ConfigFile.server>" {
                $columns = Get-TableauTableColumn -TableId $script:tableId
                ($columns | Measure-Object).Count | Should -BeGreaterThan 0
                $columnId = $columns | Select-Object -First 1 -ExpandProperty id
                $columnId | Should -BeOfType String
                $column = Get-TableauTableColumn -TableId $script:tableId -ColumnId $columnId
                $column.id | Should -Be $columnId
            }
            It "Non-paginated GraphQL queries on <ConfigFile.server>" {
                $query = Get-Content "tests/assets/GraphQL/workbooks.gql" | Out-String
                $result = Get-TableauMetadataObject -Query $query
                ($result | Measure-Object).Count | Should -BeGreaterThan 0
            }
            It "Non-paginated GraphQL queries with variables on <ConfigFile.server>" {
                $query = Get-Content "tests/assets/GraphQL/workbook-sheets.gql" | Out-String
                $workbooks = Get-TableauMetadataObject -Query $query
                if ($workbooks) {
                    $query = Get-Content "tests/assets/GraphQL/workbook-sheet-vars.gql" | Out-String
                    $wb_tested = @()
                    foreach ($wb in $workbooks) {
                        if ($wb.name -NotIn $wb_tested) {
                            # Write-Warning $wb.name
                            $vars = @{workbookName=$wb.name; sheetName=($wb.sheets | Select-Object -First 1).name}
                            # Write-Warning ($vars | ConvertTo-Json -Depth 4)
                            $result = Get-TableauMetadataObject -Query $query -Variables $vars
                            # Write-Warning ($result | ConvertTo-Json)
                            ($result | Measure-Object).Count | Should -BeGreaterThan 0
                            ($result | Where-Object name -eq $wb.name | Measure-Object).Count | Should -Be ($result | Measure-Object).Count
                            $wb_tested += $wb.name
                            if ($wb_tested.length -ge 3) { # test on 3 different workbooks
                                break
                            }
                        }
                    }
                } else {
                    Set-ItResult -Skipped -Because "Workbooks content is empty"
                }
            }
            It "Paginated GraphQL queries with variables on <ConfigFile.server>" {
                $query = Get-Content "tests/assets/GraphQL/workbook-sheets.gql" | Out-String
                $workbooks = Get-TableauMetadataObject -Query $query
                if ($workbooks) {
                    $query = Get-Content "tests/assets/GraphQL/workbooks-paginated-vars.gql" | Out-String
                    $wb_tested = @()
                    foreach ($wb in $workbooks) {
                        if ($wb.name -NotIn $wb_tested) {
                            $vars = @{workbookName=$wb.name}
                            $result = Get-TableauMetadataObject -Query $query -Variables $vars -PaginatedEntity workbooksConnection -PageSize 3
                            ($result | Measure-Object).Count | Should -BeGreaterThan 0
                            ($result | Where-Object name -eq $wb.name | Measure-Object).Count | Should -Be ($result | Measure-Object).Count
                            $wb_tested += $wb.name
                            if ($wb_tested.length -ge 3) { # test on 3 different workbooks
                                break
                            }
                        }
                    }
                } else {
                    Set-ItResult -Skipped -Because "Workbooks content is empty"
                }
            }
            It "Paginated GraphQL queries on <ConfigFile.server>" {
                $query = Get-Content "tests/assets/GraphQL/fields-paginated.gql" | Out-String
                # Query-TableauMetadata: alias -> Get-TableauMetadataObject
                $result = Query-TableauMetadata -Query $query -PaginatedEntity fieldsConnection
                ($result | Measure-Object).Count | Should -BeGreaterThan 100
                $result = Query-TableauMetadata -Query $query -PaginatedEntity fieldsConnection -PageSize 500
                ($result | Measure-Object).Count | Should -BeGreaterThan 100
                $result = Query-TableauMetadata -Query $query -PaginatedEntity fieldsConnection -PageSize 1000
                ($result | Measure-Object).Count | Should -BeGreaterThan 100
                $result = Query-TableauMetadata -Query $query -PaginatedEntity fieldsConnection -PageSize 20000
                ($result | Measure-Object).Count | Should -BeGreaterThan 100
            }
        }
    }
}
