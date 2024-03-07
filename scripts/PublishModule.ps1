###
#.SYNOPSIS
# Publish to PSGallery
#
#.DESCRIPTION
# Publishes the latest version of the module to PowerShell Gallery.
# The API key is retrieved from the secure store (KeyChain).
#
#.EXAMPLE
# PS:> ./scripts/PublishModule.ps1
###
[CmdletBinding()]
Param()

$ModuleName = (Split-Path -Leaf (Get-Item $PSCommandPath).Directory.Parent.FullName)
# Import-Module ./$ModuleName -Force
. ./scripts/SecretStore.Functions.ps1
$Release = (Import-PowerShellDataFile ./$ModuleName/$ModuleName.psd1).ModuleVersion
$Tags = (Import-PowerShellDataFile ./$ModuleName/$ModuleName.psd1).PrivateData.PSData.Tags

# https://cli.github.com/manual/gh_release_create
$secureKey = Get-SecurePassword -Namespace 'https://www.github.com' -Username GithubCliToken
(New-Object System.Net.NetworkCredential("", $secureKey)).Password | gh auth login --with-token
gh release create "v$Release" --notes "Module v$Release"
gh auth logout

Write-Host "Module $ModuleName, release $Release is published to GitHub"

$secureKey = Get-SecurePassword -Namespace 'https://www.powershellgallery.com' -Username NuGetApiKey
$NuGetApiKey = (New-Object System.Net.NetworkCredential("", $secureKey)).Password

Publish-Module -Path ./$ModuleName -NuGetApiKey $NuGetApiKey -Tags $Tags # -Verbose -Repository PSGallery

Write-Host "Module $ModuleName, release $Release is published to PSGallery"
