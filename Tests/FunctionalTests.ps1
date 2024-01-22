Import-Module ./PSTableauREST -Force
. ./Tests/Test.Functions.ps1

# $script:VerbosePreference = 'Continue' # display verbose output of the module functions
Write-Host "This script runs a suite of tests with various REST API calls. The temporary content objects are then removed."

try {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
    if ($Config.username -eq '') {
        $Config.username = $env:USERNAME
    }
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
    $user = Get-TSUser -UserId $credentials.user.id
    Write-Host ("Successfully logged in as user: {0} ({1})" -f $user.name, $user.fullName)

    $project = Add-TSProject -Name (New-Guid)
    $testProjectId = $project.id
    $testProjectName = $project.name
    $project = Update-TSProject -ProjectId $testProjectId -PublishSamples

    $workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
    Write-Host ("Workbooks available for user: {0}" -f ($workbooks | Measure-Object).Count)
    $workbooks = Get-TSWorkbook -Filter "projectName:eq:$testProjectName"
    Write-Host ("Sample workbooks found: {0}" -f ($workbooks | Measure-Object).Count)
    if (($workbooks | Measure-Object).Count -lt 2) {
        Write-Host "Waiting for sample content to update..."
        Start-Sleep -s 3
        $workbooks = Get-TSWorkbook -Filter "projectName:eq:$testProjectName"
        Write-Host ("Sample workbooks found: {0}" -f ($workbooks | Measure-Object).Count)
    }

    $workbook = Get-TSWorkbook -Filter "projectName:eq:$testProjectName","name:eq:Superstore" | Select-Object -First 1
    if ($workbook) {
        $testWorkbookId = $workbook.id
        $testWorkbookName = $workbook.name
        Write-Host ("Superstore workbook: {0} {1}" -f $testWorkbookId, $testWorkbookName)

        Write-Host "Testing export functionality (twbx, pdf, pptx, png)"
        Export-TSWorkbook -WorkbookId $testWorkbookId -OutFile "Tests/Output/$testWorkbookName.twbx"
        Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format pdf -OutFile "Tests/Output/$testWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1
        Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format powerpoint -OutFile "Tests/Output/$testWorkbookName.pptx"
        Export-TSWorkbookToFormat -WorkbookId $testWorkbookId -Format image -OutFile "Tests/Output/$testWorkbookName.png"

        Write-Host "Testing publish functionality (overwrite, chunked, hideviews)"
        $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite
        $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -Chunked
        $workbook = Publish-TSWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}

        Write-Host "Testing update functionality"
        $workbook = Update-TSWorkbook -WorkbookId $testWorkbookId -ShowTabs:$false
        if ((Get-TSRestApiVersion) -ge 3.21) {
            $description = "Testing sample workbook - description 456"
            $workbook = Update-TSWorkbook -WorkbookId $testWorkbookId -Description $description
        }

        Write-Host "Testing revisions functionality"
        $revisions = Get-TSWorkbook -WorkbookId $testWorkbookId -Revisions
        if (($revisions | Measure-Object).Count -gt 1) {
            $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
            Export-TSWorkbook -WorkbookId $testWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"
        }

        Write-Host "Testing tags functionality"
        $null = Add-TSTagsToContent -WorkbookId $testWorkbookId -Tags "active","test"
        $null = Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "test"
        $null = Remove-TSTagFromContent -WorkbookId $testWorkbookId -Tag "active"
    } else {
        Write-Host "Couldn't find the sample workbook" -ForegroundColor Red
    }

    $datasource = Get-TSDatasource -Filter "projectName:eq:$testProjectName" | Select-Object -First 1
    if ($datasource) {
        $testDatasourceId = $datasource.id
        $testDatasourceName = $datasource.name
        Write-Host ("Sample datasource: {0} {1}" -f $testDatasourceId, $testDatasourceName)

        Write-Host "Testing export functionality (tdsx)"
        Export-TSDatasource -DatasourceId $testDatasourceId -OutFile "Tests/Output/$testDatasourceName.tdsx"

        Write-Host "Testing publish functionality (overwrite, chunked)"
        $datasource = Publish-TSDatasource -Name $testDatasourceName -InFile "Tests/Output/$testDatasourceName.tdsx" -ProjectId $testProjectId -Overwrite
        $datasource = Publish-TSDatasource -Name $testDatasourceName -InFile "Tests/Output/$testDatasourceName.tdsx" -ProjectId $testProjectId -Overwrite -Chunked

        Write-Host "Testing update functionality"
        $datasource = Update-TSDatasource -DatasourceId $testDatasourceId -Certified -CertificationNote "Testing"

        Write-Host "Testing revisions functionality"
        $revisions = Get-TSDatasource -DatasourceId $testDatasourceId -Revisions
        if (($revisions | Measure-Object).Count -gt 1) {
            $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
            Export-TSDatasource -DatasourceId $testDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"
        }

        Write-Host "Testing tags functionality"
        $null = Add-TSTagsToContent -DatasourceId $testDatasourceId -Tags "active","test"
        $null = Remove-TSTagFromContent -DatasourceId $testDatasourceId -Tag "test"
        $null = Remove-TSTagFromContent -DatasourceId $testDatasourceId -Tag "active"
    } else {
        Write-Host "Couldn't find the sample datasource" -ForegroundColor Red
    }

    Write-Host "All tests completed!" -ForegroundColor Green

} finally {
    if ($testProjectId) {
        Remove-TSProject -ProjectId $testProjectId
        $testProjectId = $null
    }
}