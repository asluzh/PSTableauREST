Import-Module ./PSTableauREST -Force
. ./Tests/Test.Functions.ps1

# $script:VerbosePreference = 'Continue' # display verbose output of the module functions
$ConfigFile = Get-Content 'Tests/Config/test_tableau_cloud.json' | ConvertFrom-Json

if ($ConfigFile.username) {
    $ConfigFile | Add-Member -MemberType NoteProperty -Name "secure_password" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.username)
}
if ($ConfigFile.pat_name) {
    $ConfigFile | Add-Member -MemberType NoteProperty -Name "pat_secret" -Value (Test-GetSecurePassword -Namespace $ConfigFile.server -Username $ConfigFile.pat_name)
}

try {

    if ($ConfigFile.pat_name) {
        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -PersonalAccessTokenName $ConfigFile.pat_name -PersonalAccessTokenSecret $ConfigFile.pat_secret
    } else {
        $credentials = Open-TSSignIn -Server $ConfigFile.server -Site $ConfigFile.site -Username $ConfigFile.username -SecurePassword $ConfigFile.secure_password
    }
    Write-Host ("Logged in user id: {0}" -f $credentials.user.id)

    $project = Add-TSProject -Name (New-Guid)
    $testProjectId = $project.id
    $testProjectName = $project.name
    $project = Update-TSProject -ProjectId $testProjectId -PublishSamples
    $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
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
    Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "test"
    Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "active"

    Write-Host "All tests completed!" -ForegroundColor Green

} finally {
    if ($testProjectId) {
        Remove-TSProject -ProjectId $testProjectId
        $testProjectId = $null
    }
}