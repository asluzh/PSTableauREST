Import-Module ./PSTableauREST -Force
. ./scripts/SecretStore.Functions.ps1

# $script:VerbosePreference = 'Continue' # display verbose output of the module functions
Write-Host "This script export all published contents (without extracts) from the configured test servers."

$ConfigFiles = Get-ChildItem -Path "./tests/config" -Filter "test_*.json" | Resolve-Path -Relative
foreach ($ConfigFile in $ConfigFiles) {
    $ConfigName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigFile) -replace '["`]',''
    $OutputDir = "./tests/Output/" + $ConfigName
    try {
        $Config = Get-Content $ConfigFile | ConvertFrom-Json
        if ($Config.username -eq '') {
            $Config.username = $env:USERNAME
        }
        if ($Config.username) {
            $Config | Add-Member -MemberType NoteProperty -Name "credential" -Value (New-Object System.Management.Automation.PSCredential($Config.username, (Get-SecurePassword -Namespace $Config.server -Username $Config.username)))
        }
        if ($Config.pat_name) {
            $Config | Add-Member -MemberType NoteProperty -Name "pat_credential" -Value (New-Object System.Management.Automation.PSCredential($Config.pat_name, (Get-SecurePassword -Namespace $Config.server -Username $Config.pat_name)))
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
        Write-Host ("Successfully logged in on {2}, site {3} as user: {0} ({1})" -f $user.name, $user.fullName, $Config.server, $Config.site)

        $projectNames = @{}
        $projectParents = @{}
        $projectStructure = @{}
        Get-TableauProject | ForEach-Object {
            $projectNames.Add($_.id, $_.name)
            $projectStructure.Add($_.id, $_.name)
            $projectParents.Add($_.id, $_.parentProjectId)
        }
        # traverse project structure
        do {
            $parentsFound = $false
            foreach ($p in $projectParents.GetEnumerator()) {
                $projectId = $p.Key
                $parentProjectId = $p.Value
                if ($parentProjectId) {
                    $projectStructure[$projectId] = $projectNames[$parentProjectId] + '/' + $projectStructure[$projectId]
                    $projectParents[$projectId] = $projectParents[$parentProjectId]
                    $parentsFound = $true
                    break
                }
            }
        } while ($parentsFound)

        foreach ($p in $projectStructure.GetEnumerator()) {
            Write-Host ("Creating folder {0}" -f ($OutputDir + '/' + $p.Value))
            New-Item -ItemType Directory -Force -Path ($OutputDir + '/' + $p.Value) | Out-Null
        }

        $workbooks = Get-TableauWorkbook
        Write-Host ("{0} workbook(s) found" -f $workbooks.Length)
        foreach ($wb in $workbooks) {
            Write-Host ("Downloading workbook {0}" -f $wb.name)
            $outfile = $OutputDir + '/' + $projectStructure[$wb.project.id] + '/' + ($wb.name -replace '["`\/]','') + '.twbx'
            Export-TableauWorkbook -WorkbookId $wb.id -ExcludeExtract -OutFile $outfile
        }

        $datasources = Get-TableauDatasource
        Write-Host ("{0} datasource(s) found" -f $datasources.Length)
        foreach ($ds in $datasources) {
            Write-Host ("Downloading datasource {0}" -f $ds.name)
            $outfile = $OutputDir + '/' + $projectStructure[$ds.project.id] + '/' + ($ds.name -replace '["`\/]','') + '.tdsx'
            Export-TableauDatasource -DatasourceId $ds.id -ExcludeExtract -OutFile $outfile
        }

        Write-Host "All contents exported!" -ForegroundColor Green

    } finally {
        Disconnect-TableauServer | Out-Null
    }
}