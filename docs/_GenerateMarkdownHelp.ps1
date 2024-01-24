$ModuleName = (Split-Path -Leaf (Get-Item $PSCommandPath).Directory.Parent.FullName)
Import-Module platyPS
Import-Module ./$ModuleName -Force
$Module = Get-Module $ModuleName
$CommandList = $Module.ExportedFunctions.Keys
$CommandList += $Module.ExportedCmdlets.Keys

# https://onprem.wtf/post/converting-powershell-help-to-a-website/
foreach ($Command in $CommandList) {
    $Help = Get-Help -Name $Command -Full
    $Metadata = @{
        'layout' = 'pshelp';
        'author' = 'tto';
        'title' = $($Command);
        'category' = $($ModuleName.ToLower());
        'excerpt' = "`"$($Help.Synopsis)`"";
        'date' = $(Get-Date -Format yyyy-MM-dd);
        'redirect_from' = "[`"/PowerShell/$($ModuleName)/$($Command)/`", `"/PowerShell/$($ModuleName)/$($Command.ToLower())/`", `"/PowerShell/$($Command.ToLower())/`"]"
    }
    if($Help.Synopsis -notmatch "\[|\]") {
        New-MarkdownHelp -Command $Command -OutputFolder . -Metadata $Metadata -Force
    }
}