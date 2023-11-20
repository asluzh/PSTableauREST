BeforeAll {
    Import-Module PSScriptAnalyzer
    Import-Module Assert
    # $script:VerbosePreference = 'Continue' # display verbose output of the tests
    $script:DebugPreference = 'Continue' # display debug output of the tests
}
BeforeDiscovery {
    $script:ParentDir = (Get-Item $PSCommandPath).Directory.Parent.FullName
    $script:ModuleName = (Split-Path -Leaf $PSCommandPath) -Replace ".Module.Tests.ps1"
    $script:ModuleFile =     "$ParentDir/$ModuleName/$ModuleName.psm1"
    $script:ModuleManifest = "$ParentDir/$ModuleName/$ModuleName.psd1"
    $script:CodeFiles = Get-ChildItem -Path "$ParentDir" -Filter *.ps1 -Recurse | Resolve-Path -Relative
    $script:ScriptAnalyzerRules = Get-ScriptAnalyzerRule
    $script:ScriptAnalyzerResults = Invoke-ScriptAnalyzer -Path $ModuleFile -ExcludeRule PSUseBOMForUnicodeEncodedFile -Severity Error,Warning
}

Describe "Module Structure and Validation Tests" -Tag Module -WarningAction SilentlyContinue {
    Context "Module File <ModuleFile>" {
        It "has the root module <ModuleName>" {
            "$ModuleFile" | Should -Exist
        }

        It "has the a manifest file of <ModuleName>" {
            "$ModuleManifest" | Should -Exist
            "$ModuleManifest" | Should -FileContentMatch "$ModuleName.psm1"
        }

        It "<ModuleFile> contains valid PowerShell code" {
            $psFile = Get-Content -Path $ModuleFile -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            if ($errors) {
                Write-Debug ($errors | ConvertTo-Json -Compress)
            }
            $errors.Count | Should -Be 0
        }
    }

    Context "Code Validation <file>" -ForEach $CodeFiles {
        It "<_> is valid PowerShell code" {
            $fileItem = Get-Item -LiteralPath $_
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($fileItem.FullName, [ref]$null, [ref]$errors)
            if ($errors) {
                Write-Debug ($errors | ConvertTo-Json -Compress)
            }
            $errors.Count | Should -Be 0
        }
    }

    Context "Module Manifest of <ModuleName>" {
        It "Import module with module manifest file" {
            { Import-Module -Name $ModuleManifest -Force -ErrorAction Stop } | Should -Not -Throw
        }
        It "Test module manifest" {
            { Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Testing module <ModuleName> against PSSA rules" -ForEach $ScriptAnalyzerRules {
        BeforeAll {
            Get-ScriptAnalyzerRule | Where-Object RuleName -eq $_ | Select-Object -ExpandProperty CommonName -OutVariable commonName
        }
        It "should pass rule '<_> (<commonName>)'" {
            if ($ScriptAnalyzerResults.RuleName -contains $_) {
                $ScriptAnalyzerResults | Where-Object RuleName -eq $_ | Select-Object Severity,ScriptName,Line,Message -OutVariable err | ForEach-Object {
                    Write-Error ("{0} {1}: {2}" -f $_.Severity,$_.ScriptName,$_.Line,$_.Message)
                }
                $err.Message | Should -BeNullOrEmpty
            }
        }
    }

}
