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
ModuleVersion = '0.2.0'

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
### API version methods
'Assert-TSRestApiVersion', 'Get-TSRestApiVersion', 'Set-TSRestApiVersion',

### Authentication / Server methods
'Get-TSServerInfo', 'Open-TSSignIn', 'Switch-TSSite', 'Close-TSSignOut', 'Revoke-TSServerAdminPAT', 'Get-TSCurrentUserId',
'Get-TSCurrentSession', 'Remove-TSSession',
# List Server Active Directory Domains
# Update Server Active Directory Domain

### Site methods
'Get-TSSite', 'Add-TSSite', 'Update-TSSite', 'Remove-TSSite',
'Get-TSRecentlyViewedContent', 'Get-TSSettingsForEmbedding', 'Update-TSSettingsForEmbedding',
# Get Data Acceleration Report for a Site - feature deprecated in 2022.1 (API 3.16)

### Projects methods
'Get-TSProject', 'Add-TSProject', 'Update-TSProject', 'Remove-TSProject', 'Get-TSDefaultProject',

### Users and Groups methods
'Get-TSUser', 'Add-TSUser', 'Update-TSUser', 'Remove-TSUser',
'Get-TSGroup', 'Add-TSGroup', 'Update-TSGroup', 'Remove-TSGroup',
'Add-TSUserToGroup', 'Remove-TSUserFromGroup', 'Get-TSUsersInGroup', 'Get-TSGroupsForUser',
# Import Users to Site from CSV - request body with multipart
# Delete Users from Site with CSV - request body with multipart

### Publishing methods
'Send-TSFileUpload',

### Workbooks methods
'Get-TSWorkbook', 'Get-TSWorkbooksForUser', 'Export-TSWorkbook', 'Publish-TSWorkbook', 'Update-TSWorkbook', 'Remove-TSWorkbook',
'Get-TSWorkbookDowngradeInfo', 'Export-TSWorkbookToFormat',
'Get-TSWorkbookConnection', 'Update-TSWorkbookConnection', 'Update-TSWorkbookNow',

### Datasources methods
'Get-TSDatasource', 'Export-TSDatasource', 'Publish-TSDatasource', 'Update-TSDatasource', 'Remove-TSDatasource',
'Get-TSDatasourceConnection', 'Update-TSDatasourceConnection', 'Update-TSDatasourceNow',
# Update Data in Hyper Connection - requires json body - API 3.12
# Update Data in Hyper Data Source - requires json body - API 3.12

### Views methods
'Get-TSView', 'Export-TSViewPreviewImage', 'Export-TSViewToFormat', 'Get-TSViewUrl',
'Get-TSViewRecommendation', 'Hide-TSViewRecommendation', 'Show-TSViewRecommendation',
'Get-TSCustomView', 'Get-TSCustomViewAsUserDefault', 'Set-TSCustomViewAsUserDefault', 'Update-TSCustomView', 'Remove-TSCustomView',
'Export-TSCustomViewImage',

### Flow methods
'Get-TSFlow', 'Get-TSFlowsForUser', 'Get-TSFlowConnection', 'Export-TSFlow', 'Publish-TSFlow', 'Update-TSFlow', 'Remove-TSFlow',
'Update-TSFlowConnection', 'Start-TSFlowNow', 'Get-TSFlowRun', 'Stop-TSFlowRun',

### Permissions methods
'Get-TSContentPermission', 'Set-TSContentPermission', 'Add-TSContentPermission', 'Remove-TSContentPermission',
'ConvertTo-TSPermissionTable',
'Get-TSDefaultPermission', 'Set-TSDefaultPermission', 'Remove-TSDefaultPermission',
# List/Add/Delete Ask Data Lens Permissions - will be retired in 2024.2 (API 3.22)

### Tags methods
'Add-TSTagsToContent', 'Remove-TSTagFromContent',

### Jobs, Tasks and Schedules methods
'Get-TSSchedule', 'Add-TSSchedule', 'Update-TSSchedule', 'Remove-TSSchedule', 'Add-TSContentToSchedule',
'Get-TSJob', 'Stop-TSJob', 'Wait-TSJob',
'Get-TSTask', 'Remove-TSTask', 'Start-TSTaskNow',
# TODO Wait for job to finish (see tsc: wait_for_job)

### Extract and Encryption methods
'Get-TSExtractRefreshTasksInSchedule',
'Add-TSExtractsInContent', 'Remove-TSExtractsInContent',
'Add-TSExtractsRefreshTask', 'Update-TSExtractsRefreshTask',
'Invoke-TSEncryption',

### Favorites methods
'Get-TSUserFavorite', 'Add-TSUserFavorite', 'Remove-TSUserFavorite', 'Move-TSUserFavorite',
# Add Metric to Favorites - will be retired in 2024.2 (API 3.22)

### Subscription methods
'Get-TSSubscription', 'Add-TSSubscription', 'Update-TSSubscription', 'Remove-TSSubscription',

### Dashboard Extensions Settings methods - API 3.8
# List settings for dashboard extensions on server
# List allowed dashboard extensions on site
# List blocked dashboard extensions on server
# List dashboard extension settings of site
# Update dashboard extensions settings of server
# Get allowed dashboard extension on site
# Get blocked dashboard extension on server
# Allow dashboard extension on site
# Disallow dashboard extension on site
# Block dashboard extension on server
# Unblock dashboard extension on server
# Update settings for allowed dashboard extension on site
# Update dashboard extension settings of site

### Analytics Extensions Settings methods - API 3.8
# List analytics extension connections on site
# Add analytics extension connection to site
# Update analytics extension connection of site
# Delete analytics extension connection from site
# Get enabled state of analytics extensions on site
# Update enabled state of analytics extensions on site
# Get enabled state of analytics extensions on server
# Enable or disable analytics extensions on server
# Get analytics extension details
# List analytics extension connections of workbook
# Get current analytics extension for workbook
# Update analytics extension for workbook
# Remove current analytics extension connection for workbook

### Connected App methods
# List Connected Apps
# Get Connected App
# Create Connected App
# Delete Connected App
# Update Connected App
# Get Connected App Secret
# Create Connected App Secret
# Delete Connected App Secret
# List All Registered EAS
# List Registered EAS
# Register EAS
# Update EAS
# Delete EAS

### Notifications methods
'Get-TSDataAlert', 'Add-TSDataAlert', 'Update-TSDataAlert', 'Remove-TSDataAlert',
'Add-TSUserToDataAlert', 'Remove-TSUserFromDataAlert',
# List Webhooks - API 3.6
# Get a Webhook
# Create a Webhook
# Test a Webhook
# Update a Webhook
# Delete a Webhook
# Get User Notification Preferences
# Update User Notification Preferences

### Content Exploration methods
# Get content Suggestions
# Get content search results
# Get batch content usage statistics
# Get usage statistics for content item

### Ask Data Lens methods
# List ask data lenses in site
# Get ask data lens
# Create ask data lens
# Import ask data lens
# Delete ask data lens

### Metrics methods
# List Metrics for Site
# Get Metric
# Get Metric Data
# Update Metric
# Delete Metric

### Identity Pools methods
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

### Metadata methods - require API API 3.5
'Get-TSDatabase', 'Get-TSTable', 'Get-TSTableColumn', 'Get-TSMetadataGraphQL'
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
)
# see also: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_whats_new.htm#added-in-rest-api-315-for-tableau-server-20221-and-tableau-cloud

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

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

