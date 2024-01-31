###
#.SYNOPSIS
# Generates Markdown help files for this PowerShell module or its specific command.
#
#.DESCRIPTION
# Using PlatyPS, generates or updates Markdown help files based on module's cmdlet structure.
#
#.EXAMPLE
# PS:> ./scripts/GenerateMarkdownHelp.ps1
#
#.EXAMPLE
# PS:> ./scripts/GenerateMarkdownHelp.ps1 Get-TableauWorkbook
#
#.NOTES
# For more information on PlatyPS, see https://github.com/PowerShell/platyPS.
###
[CmdletBinding()]
Param(
    [Parameter(Position=0)][string] $Item
)

$ModuleName = (Split-Path -Leaf (Get-Item $PSCommandPath).Directory.Parent.FullName)
Import-Module platyPS
Import-Module ./$ModuleName -Force
$Module = Get-Module $ModuleName

if ($Item) {
    $CommandList = @($Item)
} else {
    $CommandList = $Module.ExportedFunctions.Keys
    $CommandList += $Module.ExportedCmdlets.Keys
}

# https://onprem.wtf/post/converting-powershell-help-to-a-website/
foreach ($Command in $CommandList) {
    $Help = Get-Help -Name $Command -Full
    $Metadata = @{
    #     'layout' = 'pshelp';
    #     'author' = 'asluzh';
        'title' = $($Command);
    #     'category' = $($ModuleName.ToLower());
    #     'excerpt' = "`"$($Help.Synopsis)`"";
    #     'date' = $(Get-Date -Format yyyy-MM-dd);
    #     'redirect_from' = "[`"/PowerShell/$($ModuleName)/$($Command)/`", `"/PowerShell/$($ModuleName)/$($Command.ToLower())/`", `"/PowerShell/$($Command.ToLower())/`"]"
    }
    if ($Help.Synopsis -notmatch "\[|\]") {
        New-MarkdownHelp -Command $Command -OutputFolder ./help -Force -Metadata $Metadata
    }
}