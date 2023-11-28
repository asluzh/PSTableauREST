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

    $credentials = Open-TSSignIn -Server $server -Site $site -Username $username -SecurePassword $securePw
    $workbooks = Get-TSWorkbook
    $workbooksFiltered = Get-TSWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name
    $description = "Test description"
    workbookId = $workbooks[0].id
    $workbook = Update-TSWorkbook -WorkbookId $workbookId -Description $description
    Export-TSWorkbook -WorkbookId $workbookId -OutFile "workbook.twbx"
    Export-TSWorkbookToFormat -WorkbookId $workbookId -Format pdf -OutFile "workbook.pdf"
    $workbook = Publish-TSWorkbook -Name "My Workbook" -InFile "workbook.twbx" -Overwrite

### Example: Users/Groups operations
This example uses Sign-in via Personal Access Token

    $credentials = Open-TSSignIn -Server $server -Site $site -PersonalAccessTokenName $patName -PersonalAccessTokenSecret $patSecret
    $users = Get-TSUser
    $newGroup = Add-TSGroup -Name "Test Group" -MinimumSiteRole Viewer
    $testUser = Add-TSUser -Name "testuser" -SiteRole Unlicensed
    $user = Add-TSUserToGroup -UserId $testUser.id -GroupId $newGroup.id
    $usersInGroup = Get-TSUsersInGroup -GroupId $newGroup.id
    $user = Update-TSUser -UserId $testUser.id -SiteRole Explorer
    Remove-TSUser -UserId $testUser.id
    Remove-TSGroup -GroupId $newGroup.id

### Example: Run Metadata API query (GraphQL)

    $credentials = Open-TSSignIn -Server $server -Site $site -Username $username -SecurePassword $securePw
    $query = Get-Content "fields-paginated.graphql" | Out-String
    $results = Get-TSMetadataGraphQL -Query $query -PaginatedEntity "fieldsConnection" -PageSize 500

## Help Files
The help files for each cmdlet are located in the *docs* folder.

# Testing
This repository also contains a suite of module tests for PSTableauREST:
- Module integrity tests (PSTableauREST.Module.Tests.ps1)
- Basic unit tests for module functions (PSTableauREST.Unit.Tests.ps1)
- Comprehensive functional tests, based on pre-configured environment(s) (PSTableauREST.Functional.Tests.ps1)

The tests can be executed using Pester, e.g.

    Invoke-Pester -Tag Module
    Invoke-Pester -Tag Unit -Output Diagnostic
