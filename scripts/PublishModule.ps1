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

$secureKey = Get-SecurePassword -Namespace 'https://www.powershellgallery.com' -Username NuGetApiKey
$NuGetApiKey = (New-Object System.Net.NetworkCredential("", $secureKey)).Password

Publish-Module -Path ./$ModuleName -NuGetApiKey $NuGetApiKey # -Verbose -Repository PSGallery
