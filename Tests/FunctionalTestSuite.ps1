Import-Module ./PSTableauREST -Force
. ./Tests/Test.Functions.ps1

$ConfigFile = 'Tests/Config/test_tableau_cloud.json'

# $script:VerbosePreference = 'Continue' # display verbose output of the module functions
Write-Host "This script runs a suite of tests with various REST API calls. The temporary content objects are then removed."

try {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
    if ($Config.username) {
        $Config | Add-Member -MemberType NoteProperty -Name "secure_password" -Value (Test-GetSecurePassword -Namespace $Config.server -Username $Config.username)
    }
    if ($Config.pat_name) {
        $Config | Add-Member -MemberType NoteProperty -Name "pat_secret" -Value (Test-GetSecurePassword -Namespace $Config.server -Username $Config.pat_name)
    }
} catch {
    Write-Error 'Please provide a valid configuration file via $ConfigFile variable' -ErrorAction Stop
}


try {

    if ($Config.pat_name) {
        $credentials = Open-TSSignIn -Server $Config.server -Site $Config.site -PersonalAccessTokenName $Config.pat_name -PersonalAccessTokenSecret $Config.pat_secret
    } else {
        $credentials = Open-TSSignIn -Server $Config.server -Site $Config.site -Username $Config.username -SecurePassword $Config.secure_password
    }
    Write-Host ("Successfully logged in as user id: {0}" -f $credentials.user.id)

    $project = Add-TSProject -Name (New-Guid)
    $testProjectId = $project.id
    $testProjectName = $project.name
    $project = Update-TSProject -ProjectId $testProjectId -PublishSamples
    $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
    Write-Host ("Workbooks available for user: {0}" -f ($workbooks | Measure-Object).Count)
    $workbooks = Get-TSWorkbook -Filter "projectName:eq:$testProjectName"
    Write-Host ("Sample workbooks found: {0}" -f ($workbooks | Measure-Object).Count)

    $workbook = Get-TSWorkbook -Filter "projectName:eq:$testProjectName","name:eq:Superstore" | Select-Object -First 1
    $testWorkbookId = $workbook.id
    $testWorkbookName = $workbook.name
    Write-Host ("Sample workbook id: {0}" -f $testWorkbookId)

    Export-TSWorkbook -WorkbookId $testWorkbookId -OutFile "Tests/Output/$testWorkbookName.twbx"
    Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format pdf -OutFile "Tests/Output/$testWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1
    Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format powerpoint -OutFile "Tests/Output/$testWorkbookName.pptx"
    Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format image -OutFile "Tests/Output/$testWorkbookName.png"

    $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite
    $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -Chunked
    $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}

    $workbook = Update-TSWorkbook -WorkbookId $testWorkbookId -ShowTabs:$false
    if ((Get-TSRestApiVersion) -ge 3.21) {
        $description = "Testing sample workbook - description 456" # - special symbols äöü©®!?
        $workbook = Update-TSWorkbook -WorkbookId $testWorkbookId -Description $description
    }

    $revisions = Get-TSWorkbook -WorkbookId $testWorkbookId -Revisions
    if (($revisions | Measure-Object).Count -gt 1) {
        $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
        Export-TSWorkbook -WorkbookId $testWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"
    }

    $null = Add-TSTagsToContent -WorkbookId $testWorkbookId -Tags "active","test"
    $null = Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "test"
    $null = Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "active"

    Write-Host "All tests completed!" -ForegroundColor Green

} finally {
    if ($testProjectId) {
        Remove-TSProject -ProjectId $testProjectId
        $testProjectId = $null
    }
}