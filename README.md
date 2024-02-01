## PSTableauREST
This is a PowerShell module that facilitates working with Tableau Server REST API and implements wrapper functions for the API calls.
It enables to implement automation processes for Server operations, such as:
- content migration (workbooks/datasources)
- user/group setup and license assignment
- validating permissions configuration
- batch running tasks (flow run, extract refresh)
- querying metadata API on a regular basis

To try out the functionality, obtaining a free Developer access to Tableau Cloud is recommended.

## Install and Importing Module

### Install PSTableauREST from the Powershell Gallery

    Find-Module PSTableauREST | Install-Module

### Import Module

    Import-Module PSTableauREST

## Usage Examples

### Example: Workbooks operation
This example uses Sign-in via username / password

    $credentials = Connect-TableauServer -Server $server -Site $site -Username $username -SecurePassword $securePw
    $workbooks = Get-TableauWorkbook
    $workbooksFiltered = Get-TableauWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name
    $description = "Test description"
    workbookId = $workbooks[0].id
    $workbook = Set-TableauWorkbook -WorkbookId $workbookId -Description $description
    Export-TableauWorkbook -WorkbookId $workbookId -OutFile "workbook.twbx"
    Export-TableauWorkbookToFormat -WorkbookId $workbookId -Format pdf -OutFile "workbook.pdf"
    $workbook = Publish-TableauWorkbook -Name "My Workbook" -InFile "workbook.twbx" -Overwrite

### Example: Users/Groups operations
This example uses Sign-in via Personal Access Token

    $credentials = Connect-TableauServer -Server $server -Site $site -PersonalAccessTokenName $patName -PersonalAccessTokenSecret $patSecret
    $users = Get-TableauUser
    $newGroup = New-TableauGroup -Name "Test Group" -MinimumSiteRole Viewer
    $testUser = New-TableauUser -Name "testuser" -SiteRole Unlicensed
    $user = Add-TableauUserToGroup -UserId $testUser.id -GroupId $newGroup.id
    $usersInGroup = Get-TableauUsersInGroup -GroupId $newGroup.id
    $user = Set-TableauUser -UserId $testUser.id -SiteRole Explorer
    Remove-TableauUser -UserId $testUser.id
    Remove-TableauGroup -GroupId $newGroup.id

### Example: Run Metadata API query (GraphQL)

    $credentials = Connect-TableauServer -Server $server -Site $site -Username $username -SecurePassword $securePw
    $query = Get-Content "fields-paginated.graphql" | Out-String
    $results = Query-TableauMetadata -Query $query -PaginatedEntity "fieldsConnection" -PageSize 500

## Help Files
The help files for each cmdlet are located in the *help* folder.

# Testing
This repository also contains a suite of Pester tests:
- Module validation tests (tests/PSTableauREST.Module.Tests.ps1)
- Basic unit tests for module functions (tests/PSTableauREST.Unit.Tests.ps1)
- Comprehensive integration tests, with functionality testing on real Tableau environments (tests/PSTableauREST.Integration.Tests.ps1)

The tests can be executed using Pester, e.g.

    Invoke-Pester -Tag Module
    Invoke-Pester -Tag Unit -Output Diagnostic
    Invoke-Pester -Tag Auth -Output Diagnostic
    Invoke-Pester -Tag Workbook -Output Diagnostic

The other standalone functionality testing script is tests/FunctionalTests.ps1
It runs with a configuration file provided in the variable $ConfigFile and executes a sample of test routines for REST API calls.
The temporaty content objects are then removed from the test system.
