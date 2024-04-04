#
# Module manifest for module 'PSTableauREST'
#
# Generated by: Andrey Sluzhivoy
#
# Generated on: 8/31/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSTableauREST.psm1'

# Version number of this module.
ModuleVersion = '0.6.4'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '2b5cbae2-d2e6-418a-af90-f8c7ddf8a3e4'

# Author of this module
Author = 'Andrey Sluzhivoy'

# Company or vendor of this module
# CompanyName = 'D ONE'

# Copyright statement for this module
# Copyright = '(c) Andrey Sluzhivoy. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This PowerShell module facilitates working with Tableau REST API for automation tasks. Most functions are implemented as wrappers for the corresponding API calls.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
### General methods
'Invoke-TableauRestMethod',
### API version methods
'Assert-TableauRestVersion', 'Get-TableauRestVersion', 'Set-TableauRestVersion',
### Authentication / Server methods
'Get-TableauServerInfo', 'Connect-TableauServer', 'Switch-TableauSite', 'Disconnect-TableauServer', 'Revoke-TableauServerAdminPAT', 'Get-TableauCurrentUserId',
'Get-TableauSession', 'Remove-TableauSession', 'Get-TableauActiveDirectoryDomain', 'Set-TableauActiveDirectoryDomain',
### Site methods
'Get-TableauSite', 'New-TableauSite', 'Set-TableauSite', 'Remove-TableauSite',
'Get-TableauRecentlyViewedContent', 'Get-TableauSiteSettingsEmbedding', 'Set-TableauSiteSettingsEmbedding',
# Get Data Acceleration Report for a Site - feature deprecated in API 3.16
### Projects methods
'Get-TableauProject', 'New-TableauProject', 'Set-TableauProject', 'Remove-TableauProject', 'Get-TableauDefaultProject',
### Users and Groups methods
'Get-TableauUser', 'New-TableauUser', 'Set-TableauUser', 'Remove-TableauUser',
'Get-TableauGroup', 'New-TableauGroup', 'Set-TableauGroup', 'Remove-TableauGroup',
'Add-TableauUserToGroup', 'Remove-TableauUserFromGroup', 'Get-TableauUsersInGroup', 'Get-TableauGroupsForUser',
'Import-TableauUsersCsv', 'Remove-TableauUsersCsv',
# new group set methods - API 3.22
'Get-TableauGroupSet','New-TableauGroupSet','Set-TableauGroupSet','Remove-TableauGroupSet',
'Add-TableauGroupToGroupSet','Remove-TableauGroupFromGroupSet',
### Publishing methods
'Send-TableauFileUpload',
### Workbooks methods
'Get-TableauWorkbook', 'Get-TableauWorkbooksForUser', 'Export-TableauWorkbook', 'Publish-TableauWorkbook', 'Set-TableauWorkbook', 'Remove-TableauWorkbook',
'Get-TableauWorkbookDowngradeInfo', 'Export-TableauWorkbookToFormat',
'Get-TableauWorkbookConnection', 'Set-TableauWorkbookConnection', 'Update-TableauWorkbookNow',
### Datasources methods
'Get-TableauDatasource', 'Export-TableauDatasource', 'Publish-TableauDatasource', 'Set-TableauDatasource', 'Remove-TableauDatasource',
'Get-TableauDatasourceConnection', 'Set-TableauDatasourceConnection', 'Update-TableauDatasourceNow', 'Update-TableauHyperData',
### Views methods
'Get-TableauView', 'Export-TableauViewImage', 'Export-TableauViewToFormat', 'Get-TableauViewUrl',
'Get-TableauViewRecommendation', 'Hide-TableauViewRecommendation', 'Show-TableauViewRecommendation',
'Get-TableauCustomView', 'Get-TableauCustomViewUserDefault', 'Set-TableauCustomViewUserDefault', 'Set-TableauCustomView', 'Remove-TableauCustomView',
'Export-TableauCustomViewImage',
### Flow methods
'Get-TableauFlow', 'Get-TableauFlowsForUser', 'Get-TableauFlowConnection', 'Export-TableauFlow', 'Publish-TableauFlow', 'Set-TableauFlow', 'Remove-TableauFlow',
'Set-TableauFlowConnection', 'Start-TableauFlowNow', 'Get-TableauFlowRun', 'Stop-TableauFlowRun',
### Permissions methods
'Get-TableauContentPermission', 'Set-TableauContentPermission', 'Add-TableauContentPermission', 'Remove-TableauContentPermission',
'ConvertTo-TableauPermissionTable',
'Get-TableauDefaultPermission', 'Set-TableauDefaultPermission', 'Remove-TableauDefaultPermission',
# List/Add/Delete Ask Data Lens Permissions - retired in API 3.22
### Tags methods
'Add-TableauContentTag', 'Remove-TableauContentTag',
### Jobs, Tasks and Schedules methods
'Get-TableauSchedule', 'New-TableauSchedule', 'Set-TableauSchedule', 'Remove-TableauSchedule', 'Add-TableauContentToSchedule',
'Get-TableauJob', 'Stop-TableauJob', 'Wait-TableauJob',
'Get-TableauTask', 'Remove-TableauTask', 'Start-TableauTaskNow',
### Extract and Encryption methods
'Get-TableauExtractRefreshTask',
'Add-TableauContentExtract', 'Remove-TableauContentExtract',
'New-TableauCloudExtractRefreshTask', 'Set-TableauCloudExtractRefreshTask',
'Set-TableauEncryption',
### Favorites methods
'Get-TableauUserFavorite', 'Add-TableauUserFavorite', 'Remove-TableauUserFavorite', 'Move-TableauUserFavorite',
# Add Metric to Favorites - retired in API 3.22
### Subscription methods
'Get-TableauSubscription', 'New-TableauSubscription', 'Set-TableauSubscription', 'Remove-TableauSubscription',
### Tableau Extensions Settings Methods - introduced in API 3.21
'Get-TableauServerSettingsExtension', 'Set-TableauServerSettingsExtension',
'Get-TableauSiteSettingsExtension', 'Set-TableauSiteSettingsExtension',
### Dashboard Extensions Settings methods - introduced in API 3.11, retired in API 3.21
'Get-TableauServerSettingsBlockedExtension','Add-TableauServerSettingsBlockedExtension','Remove-TableauServerSettingsBlockedExtension',
'Get-TableauSiteSettingsAllowedExtension','Set-TableauSiteSettingsAllowedExtension',
'Add-TableauSiteSettingsAllowedExtension','Remove-TableauSiteSettingsAllowedExtension',
### Analytics Extensions Settings methods - introduced in API 3.11
'Get-TableauAnalyticsExtension', 'Set-TableauAnalyticsExtension',
'New-TableauAnalyticsExtension', 'Remove-TableauAnalyticsExtension',
'Get-TableauAnalyticsExtensionState', 'Set-TableauAnalyticsExtensionState',
### Connected App methods
'Get-TableauConnectedApp', 'Set-TableauConnectedApp',
'New-TableauConnectedApp', 'Remove-TableauConnectedApp',
'Get-TableauConnectedAppSecret', 'New-TableauConnectedAppSecret', 'Remove-TableauConnectedAppSecret',
'Get-TableauConnectedAppEAS', 'Set-TableauConnectedAppEAS',
'New-TableauConnectedAppEAS', 'Remove-TableauConnectedAppEAS',

### Notifications methods
'Get-TableauDataAlert', 'New-TableauDataAlert', 'Set-TableauDataAlert', 'Remove-TableauDataAlert',
'Add-TableauDataAlertUser', 'Remove-TableauDataAlertUser',
'Get-TableauWebhook', 'New-TableauWebhook', 'Set-TableauWebhook', 'Remove-TableauWebhook',
'Test-TableauWebhook','Get-TableauSiteSettingsNotification','Set-TableauSiteSettingsNotification'

### Content Exploration methods
# Get content Suggestions
# Get content search results
# Get batch content usage statistics
# Get usage statistics for content item

### Ask Data Lens methods - retired in API 3.22
### Metrics methods - retired in API 3.22

### Identity Pools methods - introduced in API 3.19
# List Authentication Configurations
# Create Authentication Configuration
# Update Authentication Configuration
# Delete Authentication Configuration
# List Identity Pools
# Get Identity Pool
# Create Identity Pool
# Update Identity Pool
# Delete Identity Pool
# Add User to Identity Pool
# Remove User from Identity Pool
# List Identity Stores
# Configure Identity Store
# Delete Identity Store

### Virtual Connections methods
# List Virtual Connections
# List Virtual Connection Database Connections
# Update Virtual Connection Database Connections

### Metadata methods - introduced in API API 3.5
'Get-TableauDatabase', 'Get-TableauTable', 'Get-TableauTableColumn', 'Get-TableauMetadataObject'
# Query Data Quality Warning by ID
# Query Data Quality Warning by Content
# Query Data Quality Certification by ID
# Query Data Quality Certifications by Content
# Query Quality Warning Trigger
# Query All Quality Warning Triggers by Content
# Query Database Permissions
# Query Default Database Permissions
# Query Table Permissions
# Add Database Permissions
# Add Default Database Permissions
# Add Data Quality Warning - API 3.9
# Batch Add or Update Data Quality Warnings
# Batch Add or Update Data Quality Certifications
# Add (or Update) Quality Warning Trigger
# Add Table Permissions
# Add Tags to Column - API 3.9
# Add Tags to Database - API 3.9
# Add Tags to Table - API 3.9
# Batch Add Tags - API 3.9
# Create or Update labelValue
# Delete Database Permissions
# Delete Default Database Permissions
# Delete Data Quality Warning by ID
# Delete Data Quality Warning by Content
# Batch Delete Data Quality Warnings
# Delete Data Quality Certification by ID
# Delete Data Quality Certifications by Content
# Delete Quality Warning Trigger by ID
# Delete Quality Warning Triggers by Content
# Delete Label
# Delete Labels
# Delete labelValue
# Delete Table Permissions
# Delete Tag from Column - API 3.9
# Delete Tag from Database - API 3.9
# Delete Tag from Table - API 3.9
# Batch Delete Tags - API 3.9
# Get Label
# Get Labels
# Get labelValue
# Get Databases and Tables from Connection
# List labelValues on Site
# Move Database
# Move Table
# Remove Column
# Remove Database
# Remove Table
# Update Column
# Update Database
# Update Data Quality Warning
# Update Quality Warning Trigger
# Update Label
# Update Labels
# Update labelValue
# Update Table

### Tableau Pulse methods - introduced in API 3.21
# Metric definitions
# - Create, update, and delete metric definitions
# - Get a list of metric definitions for a site
# - Get a list of metrics for a metric definition
# - Get a specified batch of metric definitions
# Metrics
# - Get the details of a metric
# - Get a metric if it exists or create it if it doesn't
# - Create, update, and delete a metric
# - Get a specified batch of metrics
# Metric Insights
# - Generate a basic insight bundle for a metric
# - Generate a springboard insight bundle for a metric
# - Generate a detail insight bundle for a metric
# Metric Subscriptions
# - Get the details of a subscription to a metric
# - Get a list of subscriptions to a metric for a user
# - Create or delete a subscription to a metric
# - Update the followers of a metric
# - Get a specified batch of subscriptions to a metric
# - Create subscriptions for a batch of users or groups to a metric
# - Get a count of followers for a specified batch of subscriptions to a metric

### Mobile Settings Methods - introduced in API 3.19
# Get Mobile Security Settings for Server
# Get Mobile Security Settings for Site
# Update Mobile Security Settings for Site

### OpenID Connect Methods - introduced in API 3.22
# Create OpenID Connect Configuration
# Get OpenID Connect Configuration
# Remove OpenID Connect Configuration
# Update OpenID Connect Configuration
)
# see also: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_whats_new.htm#added-in-rest-api-315-for-tableau-server-20221-and-tableau-cloud

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @('Login-TableauServer','Logout-TableauServer',
'Update-TableauSiteSettingsEmbedding','Add-TableauFileUpload',
'Update-TableauActiveDirectoryDomain','Update-TableauSite',
'Query-TableauProject','Update-TableauProject',
'Query-TableauUser','Add-TableauUser','Update-TableauUser',
'Query-TableauGroup','Add-TableauGroup','Update-TableauGroup',
'Add-TableauGroupSet','Update-TableauGroupSet',
'Query-TableauWorkbook','Update-TableauWorkbook',
'Query-TableauWorkbooksForUser','Update-TableauWorkbookConnection',
'Download-TableauWorkbook','Upload-TableauWorkbook','Download-TableauWorkbookToFormat',
'Query-TableauDatasource','Update-TableauDatasource',
'Update-TableauDatasourceConnection','Download-TableauDatasource','Upload-TableauDatasource',
'Query-TableauView','Download-TableauViewImage','Download-TableauViewToFormat',
'Unhide-TableauViewRecommendation',
'Query-TableauCustomView','Update-TableauCustomView','Download-TableauCustomViewImage',
'Query-TableauFlow','Update-TableauFlow','Query-TableauFlowsForUser',
'Download-TableauFlow','Upload-TableauFlow','Update-TableauFlowConnection',
'Run-TableauFlow','Query-TableauFlowRun','Cancel-TableauFlowRun','Update-TableauSchedule',
'Query-TableauJob','Cancel-TableauJob', 'Run-TableauTask',
'Create-TableauContentExtract','Add-TableauCloudExtractRefreshTask','Update-TableauCloudExtractRefreshTask',
'Add-TableauSubscription','Update-TableauSubscription',
'Update-TableauServerSettingsExtension','Update-TableauSiteSettingsExtension',
'Update-TableauAnalyticsExtension','Add-TableauAnalyticsExtension','Update-TableauAnalyticsExtensionState',
'Update-TableauConnectedApp','Add-TableauConnectedApp','Add-TableauConnectedAppSecret',
'Update-TableauConnectedAppEAS','Add-TableauConnectedAppEAS',
'Query-TableauDataAlert','Add-TableauDataAlert','Update-TableauDataAlert',
'Query-TableauWebhook','Add-TableauWebhook','Update-TableauWebhook','Update-TableauSiteSettingsNotification',
'Run-TableauMetadataGraphQL','Query-TableauMetadata')

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = 'PSTableauREST.psm1', 'PSTableauREST.psd1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('tableau','tableauserver','rest','restapi')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/asluzh/PSTableauREST/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/asluzh/PSTableauREST'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

