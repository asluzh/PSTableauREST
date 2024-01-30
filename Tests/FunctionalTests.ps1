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
        $Config | Add-Member -MemberType NoteProperty -Name "credential" -Value (New-Object System.Management.Automation.PSCredential($Config.username, (Test-GetSecurePassword -Namespace $Config.server -Username $Config.username)))
    }
    if ($Config.pat_name) {
        $Config | Add-Member -MemberType NoteProperty -Name "pat_credential" -Value (New-Object System.Management.Automation.PSCredential($Config.pat_name, (Test-GetSecurePassword -Namespace $Config.server -Username $Config.pat_name)))
    }
} catch {
    Write-Error 'Please provide a valid configuration file via $ConfigFile variable' -ErrorAction Stop
}

try {
    if ($Config.pat_name) {
        $response = Connect-TableauServer -Server $Config.server -Site $Config.site -Credential $Config.pat_credential -PersonalAccessToken
    } else {
        $response = Connect-TableauServer -Server $Config.server -Site $Config.site -Credential $Config.credential
    }
    $user = Get-TableauUser -UserId $response.user.id
    Write-Host ("Successfully logged in as user: {0} ({1})" -f $user.name, $user.fullName)

    $project = New-TableauProject -Name (New-Guid)
    $testProjectId = $project.id
    $testProjectName = $project.name
    $project = Update-TableauProject -ProjectId $testProjectId -PublishSamples

    $workbooks = Get-TableauWorkbooksForUser -UserId (Get-TableauCurrentUserId)
    Write-Host ("Workbooks available for user: {0}" -f ($workbooks | Measure-Object).Count)
    $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$testProjectName"
    Write-Host ("Sample workbooks found: {0}" -f ($workbooks | Measure-Object).Count)
    if (($workbooks | Measure-Object).Count -lt 2) {
        Write-Host "Waiting for sample content to update..."
        Start-Sleep -s 3
        $workbooks = Get-TableauWorkbook -Filter "projectName:eq:$testProjectName"
        Write-Host ("Sample workbooks found: {0}" -f ($workbooks | Measure-Object).Count)
    }

    $workbook = Get-TableauWorkbook -Filter "projectName:eq:$testProjectName","name:eq:Superstore" | Select-Object -First 1
    if ($workbook) {
        $testWorkbookId = $workbook.id
        $testWorkbookName = $workbook.name
        Write-Host ("Superstore workbook: {0} {1}" -f $testWorkbookId, $testWorkbookName)

        Write-Host "Testing download functionality (twbx, pdf, pptx, png)"
        Export-TableauWorkbook -WorkbookId $testWorkbookId -OutFile "Tests/Output/$testWorkbookName.twbx"
        Export-TableauWorkbookToFormat -WorkbookId $testWorkbookId -Format pdf -OutFile "Tests/Output/$testWorkbookName.pdf" -PageType 'A3' -PageOrientation 'Landscape' -MaxAge 1
        Export-TableauWorkbookToFormat -WorkbookId $testWorkbookId -Format powerpoint -OutFile "Tests/Output/$testWorkbookName.pptx"
        Export-TableauWorkbookToFormat -WorkbookId $testWorkbookId -Format image -OutFile "Tests/Output/$testWorkbookName.png"

        Write-Host "Testing publish functionality (overwrite, chunked, hideviews)"
        $workbook = Publish-TableauWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite
        $workbook = Publish-TableauWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -Chunked
        $workbook = Publish-TableauWorkbook -Name $testWorkbookName -InFile "Tests/Output/$testWorkbookName.twbx" -ProjectId $testProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}

        Write-Host "Testing update functionality"
        $workbook = Update-TableauWorkbook -WorkbookId $testWorkbookId -ShowTabs:$false
        if ((Get-TableauRestVersion) -ge 3.21) {
            $description = "Testing sample workbook - description 456"
            $workbook = Update-TableauWorkbook -WorkbookId $testWorkbookId -Description $description
        }

        Write-Host "Testing revisions functionality"
        $revisions = Get-TableauWorkbook -WorkbookId $testWorkbookId -Revisions
        if (($revisions | Measure-Object).Count -gt 1) {
            $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
            Export-TableauWorkbook -WorkbookId $testWorkbookId -Revision $revision -OutFile "Tests/Output/download_revision.twbx"
        }

        Write-Host "Testing tags functionality"
        Add-TableauContentTag -WorkbookId $testWorkbookId -Tags "active","test" | Out-Null
        Remove-TableauContentTag -WorkbookId $testWorkbookId -Tag "test" | Out-Null
        Remove-TableauContentTag -WorkbookId $testWorkbookId -Tag "active" | Out-Null
    } else {
        Write-Host "Couldn't find the sample workbook" -ForegroundColor Red
    }

    $datasource = Get-TableauDatasource -Filter "projectName:eq:$testProjectName" | Select-Object -First 1
    if ($datasource) {
        $testDatasourceId = $datasource.id
        $testDatasourceName = $datasource.name
        Write-Host ("Sample datasource: {0} {1}" -f $testDatasourceId, $testDatasourceName)

        Write-Host "Testing download functionality (tdsx)"
        Export-TableauDatasource -DatasourceId $testDatasourceId -OutFile "Tests/Output/$testDatasourceName.tdsx"

        Write-Host "Testing publish functionality (overwrite, chunked)"
        $datasource = Publish-TableauDatasource -Name $testDatasourceName -InFile "Tests/Output/$testDatasourceName.tdsx" -ProjectId $testProjectId -Overwrite
        $datasource = Publish-TableauDatasource -Name $testDatasourceName -InFile "Tests/Output/$testDatasourceName.tdsx" -ProjectId $testProjectId -Overwrite -Chunked

        Write-Host "Testing update functionality"
        $datasource = Update-TableauDatasource -DatasourceId $testDatasourceId -Certified -CertificationNote "Testing"

        Write-Host "Testing revisions functionality"
        $revisions = Get-TableauDatasource -DatasourceId $testDatasourceId -Revisions
        if (($revisions | Measure-Object).Count -gt 1) {
            $revision = $revisions | Sort-Object revisionNumber -Descending | Select-Object -Skip 1 -First 1 -ExpandProperty revisionNumber
            Export-TableauDatasource -DatasourceId $testDatasourceId -Revision $revision -OutFile "Tests/Output/download_revision.tdsx"
        }

        Write-Host "Testing tags functionality"
        Add-TableauContentTag -DatasourceId $testDatasourceId -Tags "active","test" | Out-Null
        Remove-TableauContentTag -DatasourceId $testDatasourceId -Tag "test" | Out-Null
        Remove-TableauContentTag -DatasourceId $testDatasourceId -Tag "active" | Out-Null
    } else {
        Write-Host "Couldn't find the sample datasource" -ForegroundColor Red
    }

    Write-Host "All tests completed!" -ForegroundColor Green

} finally {
    if ($testProjectId) {
        Remove-TableauProject -ProjectId $testProjectId | Out-Null
        $testProjectId = $null
    }
    Disconnect-TableauServer # | Out-Null
}