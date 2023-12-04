BeforeAll {
    Import-Module PSScriptAnalyzer
    # Import-Module Assert
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

# https://vexx32.github.io/2020/07/08/Verify-Module-Help-Pester/
Describe "Module Help" -Tag Module {
    BeforeAll {
        Import-Module -Name $ModuleManifest -Force -ErrorAction Stop
    }
    BeforeDiscovery {
        $Module = Get-Module $ModuleName
        $script:CommandList = $Module.ExportedFunctions.Keys
        $script:CommandList += $Module.ExportedCmdlets.Keys
    }
    Context "Module <ModuleName> contains help for all functions" -ForEach $CommandList {
        BeforeEach {
            $Command = $_
            $Help = Get-Help -Name $Command -Full | Select-Object -Property *
            $Help | Out-Null
        }
        It " <Command>: help contains synopsis" {
            $Help.Synopsis | Should -Not -BeNullOrEmpty
        }
        It " <Command>: help contains description" {
            $Help.Description | Should -Not -BeNullOrEmpty
        }
        It " <Command>: help contains for all parameters" {
            $Ast = (Get-Content -Path "function:/$Command" -ErrorAction Ignore).Ast
            $ShouldProcessParameters = 'WhatIf', 'Confirm'
            $Parameters = Get-Help -Name $Command -Parameter * -ErrorAction Ignore | Where-Object { $_.Name -and $_.Name -notin $ShouldProcessParameters }
            $Parameters.Count | Should -Be $Ast.Body.ParamBlock.Parameters.Count -Because 'the number of parameters in the help should match the number in the function script'
            foreach ($param in $Parameters) {
                $param.Description.Text | Should -Not -BeNullOrEmpty -Because "parameter $($param.Name) should have a help description"
            }
        }
        It " <Command>: help contains at least one usage example" {
            $Help.Examples.Example.Code.Count | Should -BeGreaterOrEqual 1
        }
        It " <Command>: help example should contain the command" {
            $Help.Examples.Example.Code | ForEach-Object {
                $_.Contains($Command) | Should -BeTrue
            }
        }
    }
}
