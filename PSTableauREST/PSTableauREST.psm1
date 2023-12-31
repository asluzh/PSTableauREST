### Module variables and helper functions
$TSRestApiVersion = [version] 2.4 # initial/minimum supported version
$TSRestApiMinVersion = [version] 2.4 # supported version for initial sign-in calls
$TSRestApiFileSizeLimit = 64*1048576 # 64MB
$TSRestApiChunkSize = 2*1048576 # 2MB or 5MB or 50MB

function Invoke-TSRestApiMethod {
<#
.SYNOPSIS
Proxy function to call Tableau Server REST API with Invoke-RestMethod

.DESCRIPTION
Internal function.
Calls Tableau Server REST API with Invoke-RestMethod.
See help for Invoke-RestMethod for common parameters description.

.PARAMETER NoStandardHeader
Switch parameter, indicates not to include the standard Tableau Server auth token in the headers

.LINK
Invoke-RestMethod
#>
[OutputType()]
Param(
    # proxy params
    [Parameter(Mandatory)][Microsoft.PowerShell.Commands.WebRequestMethod] $Method,
    [Parameter(Mandatory)][uri] $Uri,
    [Parameter(ValueFromPipeline=$true)][System.Object] $Body,
    [Parameter()][string] $InFile,
    [Parameter()][string] $OutFile,
    [Parameter()][ValidateRange(0, 2147483647)][int] $TimeoutSec,
    [Parameter()][string] $ContentType,
    [Parameter()][switch] $SkipCertificateCheck,
    # own params
    [Parameter()][switch] $NoStandardHeader
)
    begin {
        if ($NoStandardHeader) {
            $PSBoundParameters.Remove('NoStandardHeader')
        } else {
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            if ($script:TSAuthToken) {
                $headers.Add('X-Tableau-Auth', $script:TSAuthToken)
            }
            # if ($ContentType) { # not needed, already considered via the param to Invoke-RestMethod
            #     $headers.Add('Content-Type', $ContentType)
            # }
            $PSBoundParameters.Add('Headers', $headers)
        }
        if ($DebugPreference -eq 'Continue') {
            $requestInfo = "{0} {1} " -f $Method.ToString().ToUpper(), $Uri
            $PSBoundParameters.GetEnumerator() | ForEach-Object {
                if ($_.Key -notin 'Method','Uri') { $requestInfo += "<{0}>" -f $_.Key }
            }
            Write-Debug $requestInfo
        }
    }
    process {
        try {
            Invoke-RestMethod @PSBoundParameters
        } catch [System.Net.WebException],[System.Net.Http.HttpRequestException] { # WebException is generated on PS5, HttpRequestException on PS7
            # note: if parameter -Exception $_.Exception is included, re-throws same exception, but doesn't show message in output (PS7)
            # therefore we generate "WriteErrorException" instead
            Write-Error ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Category InvalidResult -ErrorAction Stop #-Exception $_.Exception
        }
    }
    end {}
}

function Get-TSRequestUri {
<#
.SYNOPSIS
Generates and returns specific Tableau Server REST API call URL

.DESCRIPTION
Internal function.
Generates and returns specific Tableau Server REST API call URL.

.PARAMETER Endpoint
Endpoint entity. Usually the URL includes the entity in plural.

.PARAMETER Param
URL parameter to add upon the endpoint entity.

.NOTES
Expand ValidateSet to add support for more Endpoints.
#>
[OutputType([string])]
Param(
    [Parameter(Mandatory)][ValidateSet('Auth','Site','Session','Project','User','Group','Workbook','Datasource','View','Flow','FileUpload',
        'Recommendation','CustomView','Favorite','OrderFavorites','Schedule','ServerSchedule','Job','Task','Subscription','DataAlert',
        'Database','Table','GraphQL')][string] $Endpoint,
    [Parameter()][string] $Param
)
    $Uri = "$script:TSServerUrl/api/$script:TSRestApiVersion/"
    switch ($Endpoint) {
        'Auth' {
            $Uri += "auth/$Param"
        }
        'Site' {
            $Uri += "sites"
            if ($Param) { $Uri += "/$Param" }
        }
        'Session' {
            $Uri += "sessions"
            if ($Param) { $Uri += "/$Param" }
        }
        'ServerSchedule' {
            $Uri += "schedules"
            if ($Param) { $Uri += "/$Param" }
        }
        'FileUpload' {
            $Uri += "sites/$script:TSSiteId/fileUploads"
            if ($Param) { $Uri += "/$Param" }
        }
        'OrderFavorites' {
            $Uri += "sites/$script:TSSiteId/orderFavorites"
            if ($Param) { $Uri += "/$Param" }
        }
        'DataAlert' {
            $Uri += "sites/$script:TSSiteId/dataAlerts"
            if ($Param) { $Uri += "/$Param" }
        }
        'GraphQL' {
            $Uri = "$script:TSServerUrl/api/metadata/graphql"
        }
        default {
            $Uri += "sites/$script:TSSiteId/" + $Endpoint.ToLower() + "s" # User -> users, etc.
            if ($Param) { $Uri += "/$Param" }
        }
    }
    return $Uri
}

function Add-TSCredentialsElement {
<#
.SYNOPSIS
Helper function for generating XML element connectionCredentials

.DESCRIPTION
Internal function.
Helper function for generating XML element "connectionCredentials".
Modifies the XML object by appending into $Element.
#>
[OutputType()]
Param(
    [Parameter(Mandatory)][System.Xml.XmlElement] $Element,
    [Parameter(Mandatory)][hashtable] $Credentials
)
    if (-Not ($Credentials["username"] -and $Credentials["password"])) {
        Write-Error "Credentials must contain both username and password" -Category InvalidArgument -ErrorAction Stop
    }
    $el_connection = $Element.AppendChild($Element.OwnerDocument.CreateElement("connectionCredentials"))
    $el_connection.SetAttribute("name", $Credentials["username"])
    if ($Credentials["password"] -isnot [securestring]) {
        Write-Error "Password must be a SecureString" -Category InvalidArgument -ErrorAction Stop
    }
    $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $Credentials["password"])).Password
    $el_connection.SetAttribute("password", $private:PlainPassword)
    if ($Credentials["embed"]) {
        $el_connection.SetAttribute("embed", $Credentials["embed"])
    }
    if ($Credentials["oAuth"]) {
        $el_connection.SetAttribute("oAuth", $Credentials["oAuth"])
    }
}

function Add-TSConnectionsElement {
<#
.SYNOPSIS
Helper function for generating XML element connections

.DESCRIPTION
Internal function.
Helper function for generating XML element "connections".
Modifies the XML object by appending into $Element.
#>
[OutputType()]
Param(
    [Parameter(Mandatory)][System.Xml.XmlElement] $Element,
    [Parameter(Mandatory)][hashtable[]] $Connections
)
    $el_connections = $Element.AppendChild($Element.OwnerDocument.CreateElement("connections"))
    foreach ($connection in $Connections) {
        $el_connection = $el_connections.AppendChild($Element.OwnerDocument.CreateElement("connection"))
        if ($connection["serverAddress"]) {
            $el_connection.SetAttribute("serverAddress", $connection["serverAddress"])
        } else {
            Write-Error "Connection must have a server address" -Category InvalidArgument -ErrorAction Stop
        }
        if ($connection["serverPort"]) {
            $el_connection.SetAttribute("serverPort", $connection["serverPort"])
        }
        if ($connection["credentials"] -and ($connection["credentials"] -is [hashtable])) {
            Add-TSCredentialsElement -Element $el_connection -Credentials $connection["credentials"]
        } elseif ($connection["username"] -and $connection["password"] -and $connection["embed"]) {
            Add-TSCredentialsElement -Element $el_connection -Credentials @{
                username = $connection["username"]
                password = $connection["password"]
                embed = $connection["embed"]
            }
        }
    }
}

### API version methods
function Assert-TSRestApiVersion {
<#
.SYNOPSIS
Assert check for Tableau Server REST API version

.DESCRIPTION
Assert check for Tableau Server REST API version.
If the version is not compatible with the parameter inputs, an exception is generated through Write-Error call.

.PARAMETER AtLeast
Demands that the REST API version has to be at least this version number.
This is useful when a specific functionality has been introduced with this version.

.PARAMETER LessThan
Demands that the REST API version has to be less than this version number.
This is needed for compatibility when a specific functionality has been decommissioned.

.EXAMPLE
Assert-TSRestApiVersion -AtLeast 3.16

.NOTES
Version mapping: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_versions.htm
What's new in REST API: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_whats_new.htm
#>
[OutputType()]
Param(
    [Parameter()][version] $AtLeast,
    [Parameter()][version] $LessThan
)
    if ($AtLeast -and $script:TSRestApiVersion -lt $AtLeast) {
        Write-Error "Method or Parameter not supported, needs API version >= $AtLeast" -Category NotImplemented -ErrorAction Stop
    }
    if ($LessThan -and $script:TSRestApiVersion -ge $LessThan) {
        Write-Error "Method or Parameter not supported, needs API version < $LessThan" -Category NotImplemented -ErrorAction Stop
    }
}

function Get-TSRestApiVersion {
<#
.SYNOPSIS
Returns currently selected Tableau Server REST API version

.DESCRIPTION
Returns currently selected Tableau Server REST API version (stored in module variable).

.EXAMPLE
$apiVer = Get-TSRestApiVersion
#>
[OutputType([version])]
Param()
    return $script:TSRestApiVersion
}

function Set-TSRestApiVersion {
<#
.SYNOPSIS
Selects Tableau Server REST API version for future calls

.DESCRIPTION
Selects Tableau Server REST API version for future calls (stored in module variable).

.PARAMETER ApiVersion
The specific API version to switch to.

.EXAMPLE
Set-TSRestApiVersion -ApiVersion 3.20
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType()]
Param(
    [Parameter()][version] $ApiVersion
)
    if ($PSCmdlet.ShouldProcess($ApiVersion)) {
        $script:TSRestApiVersion = $ApiVersion
    }
}

### Authentication / Server methods
function Get-TSServerInfo {
<#
.SYNOPSIS
Retrieves the object with Tableau Server info

.DESCRIPTION
Retrieves the object with Tableau Server info, such as build number, product version, etc.

.PARAMETER ServerUrl
Optional parameter with Tableau Server URL. If not provided, the current Server URL (when signed-in) is used.

.EXAMPLE
$serverInfo = Get-TSServerInfo

.NOTES
This API can be called by anyone, even non-authenticated, so it doesn't require X-Tableau-Auth header.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#server_info
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter()][string] $ServerUrl
)
    # Assert-TSRestApiVersion -AtLeast 2.4
    if (-Not $ServerUrl) {
        $ServerUrl = $script:TSServerUrl
    }
    $apiVersion = $script:TSRestApiMinVersion
    if ($script:TSRestApiVersion) {
        $apiVersion = $script:TSRestApiVersion
    }
    $response = Invoke-TSRestApiMethod -Uri $ServerUrl/api/$apiVersion/serverinfo -Method Get -NoStandardHeader
    return $response.tsResponse.serverInfo
}

function Open-TSSignIn {
<#
.SYNOPSIS
Sign In (using username and password, or using PAT)

.DESCRIPTION
Signs you in as a user on the specified site on Tableau Server or Tableau Cloud.
This function initiates the session and stores the auth token that's needed for almost other REST API calls.
Authentication on Tableau Server (or Tableau Cloud) can be done with either
- username and password
- personal access token (PAT), using PAT name and PAT secret

.PARAMETER ServerUrl
The URL of the Tableau Server, including the protocol (usually https://) and the FQDN (not including the URL path).
For Tableau Cloud, the server address in the URI must contain the pod name, such as 10az, 10ay, or us-east-1.

.PARAMETER Username
The name of the user when signing in with username and password.

.PARAMETER SecurePassword
SecureString, containing the password when signing in with username and password.

.PARAMETER PersonalAccessTokenName
The name of the personal access token when signing in with a personal access token.
The token name is available on a user’s account page on Tableau server or online.

.PARAMETER PersonalAccessTokenSecret
SecureString, containing the secret value of the personal access token when signing in with a personal access token.

.PARAMETER Site
The permanent name of the site to sign in to (aka content URL).
By default, the default site with content URL "" is selected.

.PARAMETER ImpersonateUserId
The user ID to impersonate upon sign-in. This can be only used by Server Administrators.

.PARAMETER UseServerVersion
Boolean, if true, sets current REST API version to the latest version supported by the Tableau Server. Default is true.
If false, the minimum supported version 2.4 is retained.

.EXAMPLE
$credentials = Open-TSSignIn -Server https://tableau.myserver.com -Username $user -SecurePassword $securePw

.EXAMPLE
$credentials = Open-TSSignIn -Server https://10ay.online.tableau.com -Site sandboxXXXXXXNNNNNN -PersonalAccessTokenName $pat_name -PersonalAccessTokenSecret $pat_secret

.NOTES
This function has to be called prior to other REST API function calls.
Typically, a credentials token is valid for 240 minutes.
With administrator permissions on Tableau Server you can increase this idle timeout.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ServerUrl,
    [Parameter()][string] $Username,
    [Parameter()][securestring] $SecurePassword,
    [Parameter()][string] $PersonalAccessTokenName,
    [Parameter()][securestring] $PersonalAccessTokenSecret,
    [Parameter()][string] $Site = '',
    [Parameter()][string] $ImpersonateUserId,
    [Parameter()][bool] $UseServerVersion = $true
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $script:TSServerUrl = $ServerUrl
    $serverInfo = Get-TSServerInfo
    $script:TSProductVersion = $serverInfo.productVersion.InnerText
    $script:TSProductVersionBuild = $serverInfo.productVersion.build
    # $serverInfo.prepConductorVersion
    if ($UseServerVersion) {
        $script:TSRestApiVersion = [version]$serverInfo.restApiVersion
    } else {
        $script:TSRestApiVersion = [version]$script:TSRestApiMinVersion
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_credentials = $tsRequest.AppendChild($xml.CreateElement("credentials"))
    $el_site = $el_credentials.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("contentUrl", $Site)
    if ($ImpersonateUserId) {
        $el_user = $el_credentials.AppendChild($xml.CreateElement("user"))
        $el_user.SetAttribute("id", $ImpersonateUserId)
    }
    if ($Username -and $SecurePassword) {
        $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $SecurePassword)).Password
        $el_credentials.SetAttribute("name", $Username)
        $el_credentials.SetAttribute("password", $private:PlainPassword)
        # if ($ImpersonateUserId) { Assert-TSRestApiVersion -AtLeast 2.0 }
    } elseif ($PersonalAccessTokenName -and $PersonalAccessTokenSecret) {
        Assert-TSRestApiVersion -AtLeast 3.6
        $private:PlainSecret = (New-Object System.Net.NetworkCredential("", $PersonalAccessTokenSecret)).Password
        $el_credentials.SetAttribute("personalAccessTokenName", $PersonalAccessTokenName)
        $el_credentials.SetAttribute("personalAccessTokenSecret", $private:PlainSecret)
        if ($ImpersonateUserId) { Assert-TSRestApiVersion -AtLeast 3.11 }
    } else {
        Write-Error "Sign-in parameters not provided (needs either username/password or PAT)" -Category InvalidArgument -ErrorAction Stop
    }
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param signin) -Body $xml.OuterXml -Method Post -NoStandardHeader
    $script:TSAuthToken = $response.tsResponse.credentials.token
    $script:TSSiteId = $response.tsResponse.credentials.site.id
    $script:TSUserId = $response.tsResponse.credentials.user.id
    return $response.tsResponse.credentials
}

function Switch-TSSite {
<#
.SYNOPSIS
Switch Site

.DESCRIPTION
Switches you onto another site of Tableau Server without having to provide a user name and password again.

.PARAMETER Site
The permanent name of the site to sign in to (aka content URL). E.g. mySite is the content URL in the following example:
http://<server or cloud URL>/#/site/mySite/explore

.EXAMPLE
$credentials = Switch-TSSite -Site 'mySite'

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#switch_site
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter()][string] $Site = ''
)
    Assert-TSRestApiVersion -AtLeast 2.6
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("contentUrl", $Site)
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param switchSite) -Body $xml.OuterXml -Method Post
    $script:TSAuthToken = $response.tsResponse.credentials.token
    $script:TSSiteId = $response.tsResponse.credentials.site.id
    $script:TSUserId = $response.tsResponse.credentials.user.id
    return $response.tsResponse.credentials
}

function Close-TSSignOut {
<#
.SYNOPSIS
Sign Out

.DESCRIPTION
Signs you out of the current session. This call invalidates the authentication token that is created by a call to Open-TSSignIn.

.EXAMPLE
Close-TSSignOut

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#sign_out
#>
[OutputType([PSCustomObject])]
Param()
    # Assert-TSRestApiVersion -AtLeast 2.0
    $response = $null
    if ($null -ne $script:TSServerUrl -and $null -ne $script:TSAuthToken) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param signout) -Method Post
        $script:TSServerUrl = $null
        $script:TSAuthToken = $null
        $script:TSSiteId = $null
        $script:TSUserId = $null
        $script:TSRestApiVersion = $script:TSRestApiMinVersion # reset to minimum supported version
    } else {
        Write-Warning "Currently not signed in."
    }
    return $response
}

function Revoke-TSServerAdminPAT {
<#
.SYNOPSIS
Revoke Administrator Personal Access Tokens

.DESCRIPTION
Revokes all personal access tokens created by server administrators.
This method is not available for Tableau Cloud.

.EXAMPLE
$response = Revoke-TSServerAdminPAT

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#revoke_administrator_personal_access_tokens
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param()
    Assert-TSRestApiVersion -AtLeast 3.10
    if ($PSCmdlet.ShouldProcess()) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param serverAdminAccessTokens) -Method Delete
    }
}

function Get-TSCurrentUserId {
<#
.SYNOPSIS
Returns the current user ID

.DESCRIPTION
Returns the user ID of the currently signed in user (stored in an internal module variable)

.EXAMPLE
$userId = Get-TSCurrentUserId
#>
[OutputType([string])]
Param()
    return $script:TSUserId
}

function Get-TSCurrentSession {
<#
.SYNOPSIS
Get Current Server Session

.DESCRIPTION
Returns details of the current session of Tableau Server.

.EXAMPLE
$session = Get-TSCurrentSession

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#get-current-server-session
#>
[OutputType([PSCustomObject])]
Param()
    Assert-TSRestApiVersion -AtLeast 3.1
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Session -Param current) -Method Get
    return $response.tsResponse.session
}

function Remove-TSSession {
<#
.SYNOPSIS
Delete Server Session

.DESCRIPTION
Deletes a specified session.
This method is not available for Tableau Cloud and is typically used in programmatic management of the life cycles of embedded Tableau sessions.

.PARAMETER SessionId
The session ID to be deleted.

.EXAMPLE
$response = Remove-TSSession -SessionId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#delete_server_session
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $SessionId
)
    Assert-TSRestApiVersion -AtLeast 3.9
    if ($PSCmdlet.ShouldProcess($SessionId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Session -Param $SessionId) -Method Delete
    }
}

### Site methods
function Get-TSSite {
<#
.SYNOPSIS
Query Site / Query Sites

.DESCRIPTION
Option 1: $Current = $true
Returns information about the specified site, with the option to return information about the storage space and user count for the site.
Option 2: $Current = $false
Returns a list of the sites on the server that the caller of this method has access to. This method is not available for Tableau Cloud.

.PARAMETER Current
Boolean switch, specifies if only the current site (where the user session is signed in) is returned (option 1), or all sites (option 2).

.PARAMETER IncludeUsageStatistics
(Optional for current site)
Boolean switch, specifies if site usage statistics should be included in the response.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$site = Get-TSSite -Current

.NOTES
Notes on API query options: it's also possible to use ?key=contentUrl to get site, but also works only with current site.
It's also possible to use ?key=name to get site, but also works only with current site.
Thus it doesn't make much sense to implement these options

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_site

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_sites
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='CurrentSite')][switch] $Current,
    [Parameter(ParameterSetName='CurrentSite')][switch] $IncludeUsageStatistics,
    [Parameter(ParameterSetName='Sites')][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($Current) { # get single (current) site
        $uri = Get-TSRequestUri -Endpoint Site -Param $script:TSSiteId
        if ($IncludeUsageStatistics) {
            $uri += "?includeUsageStatistics=true"
        }
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        return $response.tsResponse.site
    } else { # get all sites
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Site
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.sites.site
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Add-TSSite {
<#
.SYNOPSIS
Create Site

.DESCRIPTION
Creates a site on Tableau Server. To make changes to an existing site, call Update Site. This method is not available for Tableau Cloud.

.PARAMETER Name
The name of the site.

.PARAMETER ContentUrl
The subdomain name of the site's URL.
This value can contain only characters that are upper or lower case alphabetic characters, numbers, hyphens (-), or underscores (_).

.PARAMETER SiteParams
(Optional)
Hashtable with site options. Please check the linked help page for up-to-date supported options.
Currently supported SiteParams:
- adminMode, userQuota, storageQuota, disableSubscriptions, subscribeOthersEnabled
- revisionLimit, dataAccelerationMode
- set_versioned_flow_attributes(flows_all, flows_edit, flows_schedule, parent_srv, site_element, site_item)
- allowSubscriptionAttachments, guestAccessEnabled, cacheWarmupEnabled, commentingEnabled, revisionHistoryEnabled
- extractEncryptionMode, requestAccessEnabled, runNowEnabled, tierCreatorCapacity, tierExplorerCapacity, tierViewerCapacity
- dataAlertsEnabled, commentingMentionsEnabled, catalogObfuscationEnabled, flowAutoSaveEnabled, webExtractionEnabled
- metricsContentTypeEnabled, notifySiteAdminsOnThrottle, authoringEnabled, customSubscriptionEmailEnabled, customSubscriptionEmail
- customSubscriptionFooterEnabled, customSubscriptionFooter, askDataMode, namedSharingEnabled, mobileBiometricsEnabled
- sheetImageEnabled, catalogingEnabled, derivedPermissionsEnabled, userVisibilityMode, useDefaultTimeZone, timeZone
- autoSuspendRefreshEnabled, autoSuspendRefreshInactivityWindow

.EXAMPLE
$site = Add-TSSite -Name "Test Site" -ContentUrl TestSite -SiteParams @{adminMode='ContentOnly'; revisionLimit=20}

.NOTES
This method can only be called by server administrators.
No validation is done for SiteParams. If some invalid option is included in the request, an HTTP error will be returned by the request.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#create_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][string] $ContentUrl,
    [Parameter()][hashtable] $SiteParams
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($SiteParams.Keys -contains 'adminMode' -and $SiteParams.Keys -contains 'userQuota' -and $SiteParams["adminMode"] -eq "ContentOnly") {
        Write-Error "You cannot set admin_mode to ContentOnly and also set a user quota" -Category InvalidArgument -ErrorAction Stop
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("name", $Name)
    $el_site.SetAttribute("contentUrl", $ContentUrl)
    foreach ($param in $SiteParams.Keys) {
        $el_site.SetAttribute($param, $SiteParams[$param])
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.site
    }
}

function Update-TSSite {
<#
.SYNOPSIS
Update Site

.DESCRIPTION
Modifies settings for the specified site, including the content URL, administration mode, user quota, state (active or suspended),
storage quota, whether flows are enabled, whether subscriptions are enabled, and whether revisions are enabled.

.PARAMETER SiteId
The LUID of the site to update.

.PARAMETER Name
(Optional)
The new name of the site.

.PARAMETER SiteParams
(Optional)
Hashtable with site options. Please check the linked help page for up-to-date supported options.
See also Add-TSSite

.EXAMPLE
$site = Update-TSSite -SiteId $siteId -Name "New Site" -SiteParams @{adminMode="ContentAndUsers"; userQuota="1"}

.NOTES
You must be signed in to a site in order to update it.
No validation is done for SiteParams. If some invalid option is included in the request, an HTTP error will be returned by the request.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $SiteId,
    [Parameter()][string] $Name,
    [Parameter()][hashtable] $SiteParams
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($SiteParams.Keys -contains 'adminMode' -and $SiteParams.Keys -contains 'userQuota' -and $SiteParams["adminMode"] -eq "ContentOnly") {
        Write-Error "You cannot set admin_mode to ContentOnly and also set a user quota" -Category InvalidArgument -ErrorAction Stop
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    if ($Name) {
        $el_site.SetAttribute("name", $Name)
    }
    foreach ($param in $SiteParams.Keys) {
        $el_site.SetAttribute($param, $SiteParams[$param])
    }
    if ($PSCmdlet.ShouldProcess($SiteId)) {
        if ($SiteId -eq $script:TSSiteId) {
            $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId) -Body $xml.OuterXml -Method Put
            return $response.tsResponse.site
        } else {
            Write-Error "You can only update the site for which you are currently authenticated" -Category PermissionDenied -ErrorAction Stop
        }
    }
}

function Remove-TSSite {
<#
.SYNOPSIS
Delete Site

.DESCRIPTION
Deletes the specified site.

.PARAMETER SiteId
The LUID of the site to be deleted. Should be the current site's ID.

.PARAMETER BackgroundTask
(Introduced in API 3.18) If you set this to true, the process runs asynchronously.

.EXAMPLE
$response = Remove-TSSite -SiteId $testSiteId

.NOTES
You must be signed in to a site in order to update it.
This method can only be called by server administrators. Not supported on Tableau Cloud.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#delete_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $SiteId,
    [Parameter()][switch] $BackgroundTask
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $uri = Get-TSRequestUri -Endpoint Site -Param $SiteId
    if ($BackgroundTask) {
        # Assert-TSRestApiVersion -AtLeast 3.18
        # no restriction by the Tableau Server implied, don't need to assert API version
        $uri += "?asJob=true"
    }
    if ($SiteId -eq $script:TSSiteId) {
        if ($PSCmdlet.ShouldProcess($SiteId)) {
            Invoke-TSRestApiMethod -Uri $uri -Method Delete
        }
    } else {
        Write-Error "You can only remove the site for which you are currently authenticated" -Category PermissionDenied -ErrorAction Stop
    }
}

function Get-TSRecentlyViewedContent {
<#
.SYNOPSIS
Get Recently Viewed for Site

.DESCRIPTION
Gets the details of the views and workbooks on a site that have been most recently created, updated, or accessed by the signed in user.
The 24 most recently viewed items are returned, though it may take some minutes after being viewed for an item to appear in the results.

.EXAMPLE
$recents = Get-TSRecentlyViewedContent

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#get_recently_viewed
#>
[OutputType([PSCustomObject[]])]
Param()
    Assert-TSRestApiVersion -AtLeast 3.5
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId/content/recent) -Method Get
    return $response.tsResponse.recents.recent
}

function Get-TSSettingsForEmbedding {
<#
.SYNOPSIS
Get Embedding Settings for a Site

.DESCRIPTION
Returns the current embedding settings for the current site.

.EXAMPLE
$settings = Get-TSSettingsForEmbedding

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#embedding_settings_for_site
#>
[OutputType([PSCustomObject[]])]
Param()
    Assert-TSRestApiVersion -AtLeast 3.16
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId/settings/embedding) -Method Get
    return $response.tsResponse.site.settings
}

function Update-TSSettingsForEmbedding {
<#
.SYNOPSIS
Update Embedding Settings for Site

.DESCRIPTION
Updates the embedding settings for a site. Embedding settings can be used to restrict embedding Tableau views to only certain domains.

.PARAMETER UnrestrictedEmbedding
(Optional) Boolean switch, specifies whether embedding is not restricted to certain domains.
When supplied, Tableau views on this site can be embedded in any domain.

.PARAMETER AllowDomains
(Optional) Specifies the domains where Tableau views on this site can be embedded.
Use this setting with UnrestrictedEmbedding set to false, to restrict embedding functionality to only certain domains.

.EXAMPLE
$result = Update-TSSettingsForEmbedding -Unrestricted false -Allow "mydomain.com"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_embedding_settings_for_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='Unrestricted')][switch] $UnrestrictedEmbedding,
    [Parameter(Mandatory,ParameterSetName='AllowDomains')][string] $AllowDomains
)
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_settings = $el_site.AppendChild($xml.CreateElement("settings"))
    if ($UnrestrictedEmbedding) {
        $el_settings.SetAttribute("unrestrictedEmbedding", $UnrestrictedEmbedding)
    } else {
        $el_settings.SetAttribute("unrestrictedEmbedding", $false)
        $el_settings.SetAttribute("allowList", $AllowDomains)
    }
    if ($PSCmdlet.ShouldProcess("Unrestricted embedding: $UnrestrictedEmbedding, allow domains: $AllowDomains")) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId/settings/embedding) -Method Put
        return $response.tsResponse.site.settings
    }
}

### Projects methods
function Get-TSProject {
<#
.SYNOPSIS
Query Projects

.DESCRIPTION
Returns a list of projects on the specified site, with optional parameters.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#projects

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#projects

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_projects

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$defaultProject = Get-TSProject -Filter "name:eq:Default","topLevelProject:eq:true"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#query_projects
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter()][string[]] $Filter, # https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm
    [Parameter()][string[]] $Sort,
    [Parameter()][string[]] $Fields, # https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_projects
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint Project
        $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $uriParam.Add("pageSize", $PageSize)
        $uriParam.Add("pageNumber", $pageNumber)
        if ($Filter) {
            $uriParam.Add("filter", $Filter -join ',')
        }
        if ($Sort) {
            $uriParam.Add("sort", $Sort -join ',')
        }
        if ($Fields) {
            $uriParam.Add("fields", $Fields -join ',')
        }
        $uriRequest = [System.UriBuilder]$uri
        $uriRequest.Query = $uriParam.ToString()
        $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.projects.project
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Add-TSProject {
<#
.SYNOPSIS
Create Project

.DESCRIPTION
Creates a project on the specified site.

.PARAMETER Name
The name for the project.

.PARAMETER Description
(Optional) The description for the project.

.PARAMETER ContentPermissions
(Optional) This option specifies content permissions inheritance in the project.

.PARAMETER OwnerId
(Optional) The LUID of the user that owns the project.

.PARAMETER ParentProjectId
(Optional) The project LUID of the parent project. Use this option to create or change project hierarchies.
If omitted, the project is created at the top level.

.EXAMPLE
$project = Add-TSProject -Name $projectName

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#create_project
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter()][string] $Description,
    [Parameter()][ValidateSet('ManagedByOwner','LockedToProject','LockedToProjectWithoutNested')][string] $ContentPermissions,
    [Parameter()][string] $OwnerId,
    [Parameter()][string] $ParentProjectId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_project = $tsRequest.AppendChild($xml.CreateElement("project"))
    $el_project.SetAttribute("name", $Name)
    if ($Description) {
        $el_project.SetAttribute("description", $Description)
    }
    if ($ContentPermissions) {
        $el_project.SetAttribute("contentPermissions", $ContentPermissions)
    }
    if ($ParentProjectId) {
        $el_project.SetAttribute("parentProjectId", $ParentProjectId)
    }
    if ($OwnerId) {
        Assert-TSRestApiVersion -AtLeast 3.21
        $el_owner = $el_project.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $OwnerId)
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $uri = Get-TSRequestUri -Endpoint Project
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post
        $response.tsResponse.project
    }
}

function Update-TSProject {
<#
.SYNOPSIS
Update Project

.DESCRIPTION
Updates the name, description, or project hierarchy of the specified project.

.PARAMETER ProjectId
The LUID of the project being updated.

.PARAMETER Name
(Optional) The new name for the project.

.PARAMETER Description
(Optional) The new description for the project.

.PARAMETER ContentPermissions
(Optional) This option specifies content permissions inheritance in the project.

.PARAMETER ParentProjectId
(Optional) The new identifier of the parent project. Use this option to create or change project hierarchies.

.PARAMETER OwnerId
(Optional) The LUID of the user that owns the project.

.PARAMETER PublishSamples
(Optional) Boolean switch value that specifies whether to publish the sample workbooks provided by Tableau to the project when you update the project.

.EXAMPLE
$project = Update-TSProject -ProjectId $testProjectId -Name $projectNewName -PublishSamples

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#update_project
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ProjectId,
    [Parameter()][string] $Name,
    [Parameter()][string] $Description,
    [Parameter()][ValidateSet('ManagedByOwner','LockedToProject','LockedToProjectWithoutNested')][string] $ContentPermissions,
    [Parameter()][string] $ParentProjectId,
    [Parameter()][string] $OwnerId,
    [Parameter()][switch] $PublishSamples
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_project = $tsRequest.AppendChild($xml.CreateElement("project"))
    if ($Name) {
        $el_project.SetAttribute("name", $Name)
    }
    if ($Description) {
        $el_project.SetAttribute("description", $Description)
    }
    if ($ContentPermissions) {
        $el_project.SetAttribute("contentPermissions", $ContentPermissions)
    }
    if ($ParentProjectId) {
        $el_project.SetAttribute("parentProjectId", $ParentProjectId)
    }
    if ($OwnerId) {
        Assert-TSRestApiVersion -AtLeast 3.21
        $el_owner = $el_project.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $OwnerId)
    }
    $uri = Get-TSRequestUri -Endpoint Project -Param $ProjectId
    if ($PublishSamples) {
        $uri += "?publishSamples=true"
    }
    if ($PSCmdlet.ShouldProcess($ProjectId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        $response.tsResponse.project
    }
}

function Remove-TSProject {
<#
.SYNOPSIS
Delete Project

.DESCRIPTION
Deletes the specified project on a specific site.
When a project is deleted, all Tableau assets inside of it are also deleted, including assets like associated workbooks, data sources, project view options, and rights.

.PARAMETER ProjectId
The LUID of the project to delete.

.EXAMPLE
$response = Remove-TSProject -ProjectId $testProjectId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#delete_project
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ProjectId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($PSCmdlet.ShouldProcess($ProjectId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Project -Param $ProjectId) -Method Delete
    }
}

function Get-TSDefaultProject {
<#
.SYNOPSIS
Get Default Project

.DESCRIPTION
Helper function that queries the projects with filter and returns the Default project.

.EXAMPLE
$defaultProject = Get-TSDefaultProject
#>
[OutputType([PSCustomObject[]])]
Param()
    Get-TSProject -Filter "name:eq:Default","topLevelProject:eq:true"
}

### Users and Groups methods
function Get-TSUser {
<#
.SYNOPSIS
Query User On Site / Get Users on Site

.DESCRIPTION
Returns the users associated with the specified site, or information about the specified user.

.PARAMETER UserId
Query User On Site: the LUID of the user to get information for.

.PARAMETER Filter
(Optional, Get Users on Site)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

.PARAMETER Sort
(Optional, Get Users on Site)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

.PARAMETER Fields
(Optional, Get Users on Site)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#get-users_site

.PARAMETER PageSize
(Optional, Get Users on Site) Page size when paging through results.

.EXAMPLE
$user = Get-TSUser -Filter "name:eq:$userName"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_user_on_site

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_on_site
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='UserById')][string] $UserId,
    [Parameter(ParameterSetName='Users')][string[]] $Filter,
    [Parameter(ParameterSetName='Users')][string[]] $Sort,
    [Parameter(ParameterSetName='Users')][string[]] $Fields,
    [Parameter(ParameterSetName='Users')][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($UserId) { # Query User On Site
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Method Get
        $response.tsResponse.user
    } else { # Get Users on Site
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint User
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.users.user
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Add-TSUser {
<#
.SYNOPSIS
Add User to Site

.DESCRIPTION
Adds a user to Tableau Server or Tableau Cloud and assigns the user to the specified site.

.PARAMETER Name
The name of the user.
For local authentication: any valid user name.
For AD authentication: the name of an existing user in Active Directory.
For Tableau Cloud: The user-name is the email address the user will use to sign in to Tableau Cloud.

.PARAMETER SiteRole
The site role to assign to the user.
You can assign the following roles: Creator, Explorer, ExplorerCanPublish, SiteAdministratorExplorer, SiteAdministratorCreator, Unlicensed, or Viewer.

.PARAMETER AuthSetting
(Optional) The authentication type for the user, e.g. if site-specific SAML is enabled.

.EXAMPLE
$user = Add-TSUser -Name $userName -SiteRole Viewer

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#add_user_to_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $SiteRole,
    [Parameter()][string] $AuthSetting
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_user = $tsRequest.AppendChild($xml.CreateElement("user"))
    $el_user.SetAttribute("name", $Name)
    $el_user.SetAttribute("siteRole", $SiteRole)
    if ($AuthSetting) {
        $el_user.SetAttribute("authSetting", $AuthSetting)
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint User) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.user
    }
}

function Update-TSUser {
<#
.SYNOPSIS
Update User

.DESCRIPTION
Modifies information about the specified user.

.PARAMETER UserId
The LUID of the user to update.

.PARAMETER FullName
(Optional) The new display name for the user.

.PARAMETER Email
(Optional) The new email address for the user. Not supported in Tableau Cloud.

.PARAMETER SecurePassword
(Optional) The new password for the user, if local authentication is used. Should be provided via SecureString.

.PARAMETER SiteRole
(Optional) The new site role to assign to the user.

.PARAMETER AuthSetting
(Optional) The authentication type for the user (e.g. if site-specific SAML is enabled)

.EXAMPLE
$user = Update-TSUser -UserId $userId -SiteRole Explorer -FullName "John Doe"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#update_user
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][string] $FullName,
    [Parameter()][string] $Email,
    [Parameter()][securestring] $SecurePassword,
    [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $SiteRole,
    [Parameter()][string] $AuthSetting
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_user = $tsRequest.AppendChild($xml.CreateElement("user"))
    if ($FullName) {
        $el_user.SetAttribute("fullName", $FullName)
    }
    if ($Email) {
        $el_user.SetAttribute("email", $Email)
    }
    if ($SecurePassword) {
        $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $SecurePassword)).Password
        $el_user.SetAttribute("password", $private:PlainPassword)
    }
    if ($SiteRole) {
        $el_user.SetAttribute("siteRole", $SiteRole)
    }
    if ($AuthSetting) {
        $el_user.SetAttribute("authSetting", $AuthSetting)
    }
    if ($PSCmdlet.ShouldProcess($UserId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.user
    }
}

function Remove-TSUser {
<#
.SYNOPSIS
Remove User from Site

.DESCRIPTION
Removes a user from the specified site.

.PARAMETER UserId
The LUID of the user to remove.

.PARAMETER MapAssetsToUserId
(Optional) The LUID of a user that receives ownership of contents of the user being removed.

.EXAMPLE
Remove-TSUser -UserId $userId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#remove_user_from_site
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][string] $MapAssetsToUserId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $uri = Get-TSRequestUri -Endpoint User -Param $UserId
    if ($MapAssetsToUserId) {
        $uri += "?mapAssetsTo=$MapAssetsToUserId"
    }
    if ($PSCmdlet.ShouldProcess($UserId)) {
        Invoke-TSRestApiMethod -Uri $uri -Method Delete
    }
}

function Get-TSGroup {
<#
.SYNOPSIS
Query Groups

.DESCRIPTION
Returns a list of groups on current site.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#groups

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#groups

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_groups

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$group = Get-TSGroup -Filter "name:eq:$groupName"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_groups
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter()][string[]] $Filter,
    [Parameter()][string[]] $Sort,
    [Parameter()][string[]] $Fields,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint Group
        $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $uriParam.Add("pageSize", $PageSize)
        $uriParam.Add("pageNumber", $pageNumber)
        if ($Filter) {
            $uriParam.Add("filter", $Filter -join ',')
        }
        if ($Sort) {
            $uriParam.Add("sort", $Sort -join ',')
        }
        if ($Fields) {
            $uriParam.Add("fields", $Fields -join ',')
        }
        $uriRequest = [System.UriBuilder]$uri
        $uriRequest.Query = $uriParam.ToString()
        $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.groups.group
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Add-TSGroup {
<#
.SYNOPSIS
Create Group

.DESCRIPTION
Creates a group on Tableau Server or Tableau Cloud site.

.PARAMETER Name
The name for the new group.

.PARAMETER MinimumSiteRole
Site role that is granted for new users of this group (grant license on-sync or on-login mode).

.PARAMETER DomainName
(Optional) The domain of the Active Directory group to import (applicable for AD setup).

.PARAMETER GrantLicenseMode
(Optional) The mode for automatically applying licenses for group members.
When the mode is onLogin, a license is granted for each group member when they log in to a site.
For AD setup, the mode can be also onSync.

.PARAMETER EphemeralUsersEnabled
(Optional) A boolean value that is used to enable on-demand access for embedded Tableau content when the
Tableau Cloud site is licensed with Embedded Analytics(Link opens in a new window) usage-based model.

.PARAMETER BackgroundTask
(Optional) Boolean switch, if true, the import process runs as an asynchronous process.

.EXAMPLE
$group = Add-TSGroup -Name $groupName -MinimumSiteRole Viewer -GrantLicenseMode onLogin

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#create_group
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $MinimumSiteRole,
    [Parameter()][string] $DomainName,
    [Parameter()][ValidateSet('onLogin','onSync')][string] $GrantLicenseMode,
    [Parameter()][switch] $EphemeralUsersEnabled,
    [Parameter()][switch] $BackgroundTask
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_group = $tsRequest.AppendChild($xml.CreateElement("group"))
    $el_group.SetAttribute("name", $Name)
    if ($DomainName) { # Importing a group from Active Directory
        $el_import = $el_group.AppendChild($xml.CreateElement("import"))
        $el_import.SetAttribute("source", "ActiveDirectory")
        $el_import.SetAttribute("domainName", $DomainName)
        if ($GrantLicenseMode) {
            $el_import.SetAttribute("grantLicenseMode", $GrantLicenseMode)
            $el_import.SetAttribute("siteRole", $MinimumSiteRole)
        }
    } else { # Creating a local group
        if ($MinimumSiteRole) {
            $el_group.SetAttribute("minimumSiteRole", $MinimumSiteRole)
        }
        if ($EphemeralUsersEnabled) {
            Assert-TSRestApiVersion -AtLeast 3.21
            $el_group.SetAttribute("ephemeralUsersEnabled", "true")
        }
    }
    $uri = Get-TSRequestUri -Endpoint Group
    if ($BackgroundTask) {
        $uri += "?asJob=true"
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post
        if ($BackgroundTask) {
            return $response.tsResponse.job
        } else {
            return $response.tsResponse.group
        }
    }
}

function Update-TSGroup {
<#
.SYNOPSIS
Update Group

.DESCRIPTION
Updates a group on a Tableau Server or Tableau Cloud site.

.PARAMETER GroupId
The LUID of the group to update.

.PARAMETER Name
(Optional) The new name for the group.

.PARAMETER MinimumSiteRole
(Optional) Site role that is granted for new users of this group (grant license on-sync or on-login mode).

.PARAMETER DomainName
(Optional) The domain of the Active Directory group (for AD setup).

.PARAMETER GrantLicenseMode
(Optional) The mode for automatically applying licenses for group members.
When the mode is onLogin, a license is granted for each group member when they log in to a site.
For AD setup, the mode can be also onSync.

.PARAMETER EphemeralUsersEnabled
(Optional) A boolean value that is used to enable on-demand access for embedded Tableau content when the
Tableau Cloud site is licensed with Embedded Analytics(Link opens in a new window) usage-based model.

.PARAMETER BackgroundTask
(Optional) Boolean switch, if true, the import process runs as an asynchronous process.

.EXAMPLE
$group = Update-TSGroup -GroupId $groupId -Name $groupNewName

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#update_group
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $GroupId,
    [Parameter()][string] $Name,
    [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $MinimumSiteRole,
    [Parameter()][string] $DomainName,
    [Parameter()][ValidateSet('onLogin','onSync')][string] $GrantLicenseMode,
    [Parameter()][switch] $EphemeralUsersEnabled,
    [Parameter()][switch] $BackgroundTask
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_group = $tsRequest.AppendChild($xml.CreateElement("group"))
    $el_group.SetAttribute("name", $Name)
    if ($DomainName) { # Updating an Active Directory group
        $el_import = $el_group.AppendChild($xml.CreateElement("import"))
        $el_import.SetAttribute("source", "ActiveDirectory")
        $el_import.SetAttribute("domainName", $DomainName)
        if ($GrantLicenseMode) {
            $el_import.SetAttribute("grantLicenseMode", $GrantLicenseMode)
            $el_import.SetAttribute("siteRole", $MinimumSiteRole)
        }
    } else { # Updating a local group
        if ($MinimumSiteRole) {
            $el_group.SetAttribute("minimumSiteRole", $MinimumSiteRole)
        }
        if ($PSBoundParameters.ContainsKey('EphemeralUsersEnabled')) {
            Assert-TSRestApiVersion -AtLeast 3.21
            $el_group.SetAttribute("ephemeralUsersEnabled", $EphemeralUsersEnabled)
        }
    }
    $uri = Get-TSRequestUri -Endpoint Group -Param $GroupId
    if ($BackgroundTask) {
        $uri += "?asJob=true"
    }
    if ($PSCmdlet.ShouldProcess($GroupId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        if ($BackgroundTask) {
            return $response.tsResponse.job
        } else {
            return $response.tsResponse.group
        }
    }
}

function Remove-TSGroup {
<#
.SYNOPSIS
Delete Group

.DESCRIPTION
Deletes the group on the current site.
Deleting a group does not delete the users in group, but users are no longer members of the group.

.PARAMETER GroupId
The LUID of the group to delete.

.EXAMPLE
$response = Remove-TSGroup -GroupId $testGroupId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#delete_group
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $GroupId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($PSCmdlet.ShouldProcess($GroupId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId) -Method Delete
    }
}

function Add-TSUserToGroup {
<#
.SYNOPSIS
Add User to Group

.DESCRIPTION
Adds a user to the specified group.

.PARAMETER UserId
The LUID of the user to add.

.PARAMETER GroupId
The LUID of the group to add the user to.

.EXAMPLE
$user = Add-TSUserToGroup -UserId $userId -GroupId $adminGroupId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#add_user_to_group
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter(Mandatory)][string] $GroupId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_user = $tsRequest.AppendChild($xml.CreateElement("user"))
    $el_user.SetAttribute("id", $UserId)
    if ($PSCmdlet.ShouldProcess("user:$UserId, group:$GroupId")) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId/users) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.user
    }
}

function Remove-TSUserFromGroup {
<#
.SYNOPSIS
Remove User from Group

.DESCRIPTION
Removes a user from the specified group.

.PARAMETER UserId
The LUID of the user to remove.

.PARAMETER GroupId
The LUID of the group to remove the user from.

.EXAMPLE
$response = Remove-TSUserFromGroup -UserId $userId -GroupId $adminGroupId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#remove_user_to_group
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter(Mandatory)][string] $GroupId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($PSCmdlet.ShouldProcess("user:$UserId, group:$GroupId")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId/users/$UserId) -Method Delete
    }
}

function Get-TSUsersInGroup {
<#
.SYNOPSIS
Get Users in Group

.DESCRIPTION
Gets a list of users in the specified group.

.PARAMETER GroupId
The LUID of the group to get the users for.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$users = Get-TSUsersInGroup -GroupId $groupId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_in_group
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $GroupId,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint Group -Param $GroupId/users
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.users.user
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Get-TSGroupsForUser {
<#
.SYNOPSIS
Get Groups for a User

.DESCRIPTION
Gets a list of groups of which the specified user is a member.

.PARAMETER UserId
The LUID of the user whose group memberships are listed.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$groups = Get-TSGroupsForUser -UserId $selectedUserId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_groups_for_a_user
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.7
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint User -Param $UserId/groups
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.groups.group
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

### Publishing methods
function Send-TSFileUpload {
<#
.SYNOPSIS
Perform File Upload in Chunks

.DESCRIPTION
Initiates the upload process for a file, and then performs Append to File Upload to send individual blocks of the file to the server.
When the complete file has been sent to the server, the result (upload id string) can be used to publish the file as workbook, datasource or flow.
Note: this is an internal routine for Publish- methods, should not be used separately.

.PARAMETER InFile
The filename of the file to upload.

.PARAMETER FileName
(Optional) The filename (without path) that is included into the request payload.
This usually doesn't matter for Tableau Server uploads.
By default, the filename is sent as "file".

.EXAMPLE
$uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#initiate_file_upload

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#append_to_file_upload
#>
[OutputType([string])]
Param(
    [Parameter(Mandatory)][string] $InFile,
    [Parameter()][string] $FileName = "file"
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($FileName -match '[^\x20-\x7e]') { # special non-ASCII characters in the filename cause issues on some API versions
        Write-Verbose "Filename $FileName contains special characters, replacing with tableau_file"
        $FileName = "tableau_file" # fallback to standard filename (doesn't matter for file upload)
    }
    $fileItem = Get-Item -LiteralPath $InFile
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint FileUpload) -Method Post
    $uploadSessionId = $response.tsResponse.fileUpload.GetAttribute("uploadSessionId")
    $chunkNumber = 0
    $buffer = New-Object System.Byte[]($script:TSRestApiChunkSize)
    $fileStream = New-Object System.IO.FileStream($fileItem.FullName, [System.IO.FileMode]::Open)
    $byteReader = $null
    try {
        $byteReader = New-Object System.IO.BinaryReader($fileStream)
        # $totalChunks = [Math]::Ceiling($fileItem.Length / $script:TSRestApiChunkSize) # not required here
        $totalSizeMb = [Math]::Round($fileItem.Length / 1048576)
        $bytesUploaded = 0
        $startTime = Get-Date
        do {
            $chunkNumber++
            $boundaryString = (New-Guid).ToString("N")
            $bytesRead = $byteReader.Read($buffer, 0, $buffer.Length)
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                Write-Verbose "Using MultipartFormDataContent as -Body in Invoke-RestMethod (PS6.0+)"
                $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
                $null = $multipartContent.Headers.Remove("Content-Type")
                $null = $multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
                $stringContent = New-Object System.Net.Http.StringContent("", [System.Text.Encoding]::UTF8)
                $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
                $stringContent.Headers.ContentDisposition.Name = "request_payload"
                $multipartContent.Add($stringContent)
                $memoryStream = New-Object System.IO.MemoryStream($buffer, 0, $bytesRead)
                $fileContent = New-Object System.Net.Http.StreamContent($memoryStream)
                $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
                $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
                $fileContent.Headers.ContentDisposition.Name = "tableau_file"
                $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
                $multipartContent.Add($fileContent)
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint FileUpload -Param $uploadSessionId) -Body $multipartContent -Method Put
            } else {
                Write-Verbose "Using String as -Body in Invoke-RestMethod (PS5.x)"
                $bodyLines = @(
                    "--$boundaryString",
                    "Content-Type: text/xml; charset=utf-8",
                    "Content-Disposition: form-data; name=request_payload",
                    "",
                    "",
                    "--$boundaryString",
                    "Content-Type: application/octet-stream",
                    "Content-Disposition: form-data; name=tableau_file; filename=`"$FileName`"",
                    "",
                    [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($buffer[0..($bytesRead-1)]),
                    "--$boundaryString--"
                    )
                $multipartContent = $bodyLines -join "`r`n"
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint FileUpload -Param $uploadSessionId) -Body $multipartContent -Method Put -ContentType "multipart/mixed; boundary=$boundaryString"
            }
            $bytesUploaded += $bytesRead
            $elapsedTime = $(Get-Date) - $startTime
            # $remainingTime = $elapsedTime * ($fileItem.Length / $bytesUploaded - 1) # note compatibility issue: op_Multiply for TimeSpan is not available in PS5.1
            $remainingTime = New-Object TimeSpan($elapsedTime.Ticks * ($fileItem.Length / $bytesUploaded - 1)) # calculate via conversion to Ticks
            # calculate uploaded size and percentage for Write-Progress
            $uploadedSizeMb = [Math]::Round($bytesUploaded / 1048576)
            $percentCompleted = [Math]::Round($bytesUploaded / $fileItem.Length * 100)
            Write-Progress -Activity "Uploading file $FileName" -Status "$uploadedSizeMb / $totalSizeMb MB uploaded ($percentCompleted%)" -PercentComplete $percentCompleted -SecondsRemaining $remainingTime.TotalSeconds
        } until ($script:TSRestApiChunkSize*$chunkNumber -ge $fileItem.Length)
    } finally {
        if ($byteReader) {
            $byteReader.Dispose()
        }
        $fileStream.Dispose()
    }
    # final Write-Progress update
    Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb / $totalSizeMb MB uploaded (100%)" -PercentComplete 100
    Start-Sleep -m 100
    Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb MB uploaded" -Completed
    return $uploadSessionId
}

### Workbooks methods
function Get-TSWorkbook {
<#
.SYNOPSIS
Get Workbook / Workbooks on Site / Workbook Revisions

.DESCRIPTION
Returns information about the specified workbook, or workbooks on a site.

.PARAMETER WorkbookId
Get Workbook by Id: The LUID of the workbook.

.PARAMETER ContentUrl
Get Workbook by Content URL: The content URL of the workbook.

.PARAMETER Revisions
(Get Workbook Revisions) Boolean switch, if supplied, the workbook revisions are returned.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#workbooks

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#workbooks

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_workbooks_site

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$workbook = Get-TSWorkbook -WorkbookId $workbookId

.EXAMPLE
$workbookRevisions = Get-TSWorkbook -WorkbookId $workbookId -Revisions

.EXAMPLE
$workbooks = Get-TSWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_site

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_revisions
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='WorkbookById')]
    [Parameter(Mandatory,ParameterSetName='WorkbookRevisions')]
    [string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='WorkbookByContentUrl')][string] $ContentUrl,
    [Parameter(Mandatory,ParameterSetName='WorkbookRevisions')][switch] $Revisions,
    [Parameter(ParameterSetName='Workbooks')][string[]] $Filter,
    [Parameter(ParameterSetName='Workbooks')][string[]] $Sort,
    [Parameter(ParameterSetName='Workbooks')][string[]] $Fields,
    [Parameter(ParameterSetName='Workbooks')]
    [Parameter(ParameterSetName='WorkbookRevisions')]
    [ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($ContentUrl) {
        Assert-TSRestApiVersion -AtLeast 3.17
    }
    if ($Revisions) { # Get Workbook Revisions
        # Assert-TSRestApiVersion -AtLeast 2.3
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/revisions
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.revisions.revision
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } elseif ($WorkbookId) { # Get Workbook by Id
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId) -Method Get
        $response.tsResponse.workbook
    } elseif ($ContentUrl) { # Get Workbook by ContentUrl
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $ContentUrl
        $uri += "?key=contentUrl"
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $response.tsResponse.workbook
    } else { # Query Workbooks on Site
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Workbook
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.workbooks.workbook
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSWorkbooksForUser {
<#
.SYNOPSIS
Query Workbooks for User

.DESCRIPTION
Returns the workbooks that the specified user owns or has read (view) permissions for.

.PARAMETER UserId
The LUID of the user to get workbooks for.

.PARAMETER IsOwner
(Optional) Boolean switch, if supplied, returns only workbooks that the specified user owns.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_user
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][switch] $IsOwner,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint User -Param $UserId/workbooks
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        if ($IsOwner) { $uri += "&ownedBy=true" }
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.workbooks.workbook
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Get-TSWorkbookConnection {
<#
.SYNOPSIS
Query Workbook Connections

.DESCRIPTION
Returns a list of data connections for the specific workbook.

.PARAMETER WorkbookId
The LUID of the workbook to return connection information about.

.EXAMPLE
$workbookConnections = Get-TSWorkbookConnection -WorkbookId $workbookId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_connections
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSWorkbook {
<#
.SYNOPSIS
Download Workbook / Download Workbook Revision

.DESCRIPTION
Downloads a workbook or workbook revision in .twb or .twbx format.

.PARAMETER WorkbookId
The LUID of the workbook to be downloaded.

.PARAMETER OutFile
(Optional) Filename where the workbook is saved upon download.
If not provided, the downloaded content is piped to the output.

.PARAMETER ExcludeExtract
(Optional) Boolean switch, if supplied and the workbook contains an extract, it is not included for the download.

.PARAMETER Revision
(Optional) If revision number is specified, this revision will be downloaded.

.EXAMPLE
Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Superstore.twbx"

.EXAMPLE
Export-TSWorkbook -WorkbookId $sampleWorkbookId -OutFile "Superstore_1.twbx" -Revision 1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#download_workbook_revision
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter()][string] $OutFile,
    [Parameter()][switch] $ExcludeExtract,
    [Parameter()][int] $Revision
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    if ($Revision) {
        # Assert-TSRestApiVersion -AtLeast 2.3
        $lastRevision = Get-TSWorkbook -WorkbookId $WorkbookId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
        # Note that the current revision of a workbook cannot be accessed by the /revisions endpoint; in this case we ignore the -Revision parameter
        if ($Revision -lt $lastRevision) {
            $uri += "/revisions/$Revision"
        }
    }
    $uri += "/content"
    if ($ExcludeExtract) {
        Assert-TSRestApiVersion -AtLeast 2.5
        $uri += "?includeExtract=false"
    }
    Invoke-TSRestApiMethod -Uri $uri -Method Get -TimeoutSec 600 @OutFileParam
}

function Publish-TSWorkbook {
<#
.SYNOPSIS
Publish Workbook

.DESCRIPTION
Publishes supplied workbook.

.PARAMETER InFile
The filename (incl. path) of the workbook to upload and publish.

.PARAMETER Name
The name for the published workbook.

.PARAMETER FileName
(Optional) The filename (without path) that is included into the request payload.
If omitted, the filename is derived from the InFile parameter.

.PARAMETER FileType
(Optional) The file type of the workbook file.
If omitted, the file type is derived from the Filename parameter.

.PARAMETER Description
(Optional) The description for the published workbook.

.PARAMETER ProjectId
(Optional) The LUID of the project to assign the workbook to.
If the project is not specified, the workbook will be published to the default project.

.PARAMETER ShowTabs
(Optional) Boolean switch, if supplied, the published workbook shows views in tabs.

.PARAMETER HideViews
(Optional) Hashtable, containing the mapping of view names and true/false if the specific view should be hidden in the published workbook.
If omitted, all original views are snown.

.PARAMETER ThumbnailsUserId
(Optional) The LUID of the user to generate thumbnails as.

.PARAMETER Overwrite
(Optional) Boolean switch, if supplied, the workbook will be overwritten (otherwise existing published workbook with the same name is not overwritten).

.PARAMETER SkipConnectionCheck
(Optional) Boolean switch, if supplied, Tableau server will not check if a non-published connection of a workbook is reachable.

.PARAMETER BackgroundTask
(Optional) Boolean switch, if supplied, the publishing process (its final stage) is run asynchronously.

.PARAMETER Chunked
(Optional) Boolean switch, if supplied, the publish process is forced to run as chunked.
By default, the payload is send in one request for files < 64MB size.
This can be helpful if timeouts occur during upload.

.PARAMETER Credentials
(Optional) Hashtable containing connection credentials (see online help).

.PARAMETER Connections
(Optional) Hashtable array containing connection attributes and credentials (see online help).

.EXAMPLE
$workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Superstore.twbx" -ProjectId $samplesProjectId

.EXAMPLE
$workbook = Publish-TSWorkbook -Name $sampleWorkbookName -InFile "Superstore.twbx" -ProjectId $samplesProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#publish_workbook
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $InFile,
    [Parameter(Mandatory)][string] $Name,
    [Parameter()][string] $FileName,
    [Parameter()][string] $FileType,
    [Parameter()][string] $Description,
    [Parameter()][string] $ProjectId,
    [Parameter()][switch] $ShowTabs,
    [Parameter()][hashtable] $HideViews,
    [Parameter()][string] $ThumbnailsUserId,
    [Parameter()][switch] $Overwrite,
    [Parameter()][switch] $SkipConnectionCheck,
    [Parameter()][switch] $BackgroundTask,
    [Parameter()][switch] $Chunked,
    [Parameter()][hashtable] $Credentials,
    [Parameter()][hashtable[]] $Connections
    # [Parameter()][switch] $EncryptExtracts,
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $fileItem = Get-Item -LiteralPath $InFile
    if (-Not $FileName) {
        $FileName = $fileItem.Name -replace '["`]','' # remove special chars
    }
    if (-Not $FileType) {
        $FileType = $fileItem.Extension.Substring(1)
    }
    if ($FileType -eq 'zip') {
        $FileType = 'twbx'
        $FileName = $FileName -ireplace 'zip$','twbx'
    } elseif ($FileType -eq 'xml') {
        $FileType = 'twb'
        $FileName = $FileName -ireplace 'xml$','twb'
    }
    if (-Not ($FileType -In @("twb", "twbx"))) {
        throw "File type unsupported (supported types are: twb, twbx)"
    }
    if ($FileName -match '[^\x20-\x7e]') { # special non-ASCII characters in the filename cause issues on some API versions
        Write-Verbose "Filename $FileName contains special characters, replacing with tableau_workbook.$FileType"
        $FileName = "tableau_workbook.$FileType" # fallback to standard filename (doesn't matter for file upload)
    }
    if ($fileItem.Length -ge $script:TSRestApiFileSizeLimit) {
        $Chunked = $true
    }
    $uri = Get-TSRequestUri -Endpoint Workbook
    $uri += "?workbookType=$FileType"
    if ($Overwrite) {
        $uri += "&overwrite=true"
    }
    if ($SkipConnectionCheck) {
        $uri += "&skipConnectionCheck=true"
    }
    if ($BackgroundTask) {
        Assert-TSRestApiVersion -AtLeast 3.0
        $uri += "&asJob=true"
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_workbook = $tsRequest.AppendChild($xml.CreateElement("workbook"))
    $el_workbook.SetAttribute("name", $Name)
    if ($Description) {
        Assert-TSRestApiVersion -AtLeast 3.21
        $el_workbook.SetAttribute("description", $Description)
    }
    $el_workbook.SetAttribute("showTabs", $ShowTabs)
    if ($ThumbnailsUserId) {
        $el_workbook.SetAttribute("thumbnailsUserId", $ThumbnailsUserId)
    }
    if ($Credentials) {
        Add-TSCredentialsElement -Element $el_workbook -Credentials $Credentials
    }
    if ($Connections) {
        Assert-TSRestApiVersion -AtLeast 2.8
        Add-TSConnectionsElement -Element $el_workbook -Connections $Connections
    }
    if ($ProjectId) {
        $el_project = $el_workbook.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $ProjectId)
    }
    if ($HideViews) {
        $el_views = $el_workbook.AppendChild($xml.CreateElement("views"))
        $HideViews.GetEnumerator() | ForEach-Object {
            $el_view = $el_views.AppendChild($xml.CreateElement("view"))
            $el_view.SetAttribute("name", $_.Key)
            $el_view.SetAttribute("hidden", $_.Value)
        }
    }
    $boundaryString = (New-Guid).ToString("N")
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Write-Verbose "Using MultipartFormDataContent as -Body in Invoke-RestMethod (PS6.0+)"
        # see also https://get-powershellblog.blogspot.com/2017/09/multipartform-data-support-for-invoke.html
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        # first we need to replace the default content type, boundary quoting and multipart/form-data are not supported!
        # see also https://github.com/PowerShell/PowerShell/issues/9241 - remove boundary quoting
        $null = $multipartContent.Headers.Remove("Content-Type")
        $null = $multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, [System.Text.Encoding]::UTF8, [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/xml"))
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
        } else {
            $fileStream = New-Object System.IO.FileStream($fileItem.FullName, [System.IO.FileMode]::Open)
            try {
                $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
                $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
                $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
                $fileContent.Headers.ContentDisposition.Name = "tableau_workbook"
                $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
                $multipartContent.Add($fileContent)
                $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
            } finally {
                $fileStream.Dispose()
            }
        }
    } else {
        Write-Verbose "Using String as -Body in Invoke-RestMethod (PS5.x)"
        # https://stackoverflow.com/questions/68677742/multipart-form-data-file-upload-with-powershell
        # https://stackoverflow.com/questions/25075010/upload-multiple-files-from-powershell-script
        # other solution: saving the request body in a file and using -InFile parameter for Invoke-RestMethod
        # https://hochwald.net/upload-file-powershell-invoke-restmethod/
        $bodyLines = @(
            "--$boundaryString",
            "Content-Type: text/xml; charset=utf-8",
            "Content-Disposition: form-data; name=request_payload",
            "",
            $xml.OuterXml
        )
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
        } else {
            $bodyLines += @(
            "--$boundaryString",
            "Content-Type: application/octet-stream",
            "Content-Disposition: form-data; name=tableau_workbook; filename=`"$FileName`"",
            "",
            [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString([System.IO.File]::ReadAllBytes($fileItem.FullName)) # was: (Get-Content $InFile -Raw)
            )
        }
        $bodyLines += "--$boundaryString--"
        $multipartContent = $bodyLines -join "`r`n"
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post -ContentType "multipart/mixed; boundary=$boundaryString"
    }
    if ($BackgroundTask) {
        return $response.tsResponse.job
    } else {
        return $response.tsResponse.workbook
    }
}

function Update-TSWorkbook {
<#
.SYNOPSIS
Update Workbook

.DESCRIPTION
Updates the owner, project or other properties of the specified workbook.

.PARAMETER WorkbookId
The LUID of the workbook to update.

.PARAMETER Name
(Optional) The new name for the published workbook.

.PARAMETER Description
(Optional) The new description for the published workbook.

.PARAMETER NewProjectId
(Optional) The LUID of the project where the published workbook should be moved.

.PARAMETER NewOwnerId
(Optional) The LUID of the user who should own the workbook.

.PARAMETER ShowTabs
(Optional) Boolean, controls if the published workbook shows views in tabs.

.PARAMETER RecentlyViewed
(Optional) Boolean switch, if supplied, the updated workbook will show in the site's recently viewed list.

.PARAMETER EncryptExtracts
(Optional) Boolean switch, include to encrypt the embedded extracts.

.PARAMETER EnableDataAcceleration
(Optional) Boolean switch, include to enable data acceleration for the workbook.
Note: this feature is not supported anymore in API 3.16 and higher.

.PARAMETER AccelerateNow
(Optional) Boolean switch, when acceleration is enabled, start the pre-computation for acceleration immediately when the next backgrounder process becomes available.
Note: this feature is not supported anymore in API 3.16 and higher.

.EXAMPLE
$workbook = Update-TSWorkbook -WorkbookId $sampleWorkbookId -ShowTabs:$false

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter()][string] $Name,
    [Parameter()][string] $Description,
    [Parameter()][string] $NewProjectId,
    [Parameter()][string] $NewOwnerId,
    [Parameter()][switch] $ShowTabs,
    [Parameter()][switch] $RecentlyViewed,
    [Parameter()][switch] $EncryptExtracts,
    [Parameter()][switch] $EnableDataAcceleration,
    [Parameter()][switch] $AccelerateNow
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_workbook = $tsRequest.AppendChild($xml.CreateElement("workbook"))
    if ($Name) {
        $el_workbook.SetAttribute("name", $Name)
    }
    if ($Description) {
        Assert-TSRestApiVersion -AtLeast 3.21
        $el_workbook.SetAttribute("description", $Description)
    }
    if ($PSBoundParameters.ContainsKey('ShowTabs')) {
        $el_workbook.SetAttribute("showTabs", $ShowTabs)
    }
    if ($PSBoundParameters.ContainsKey('RecentlyViewed')) {
        $el_workbook.SetAttribute("recentlyViewed", $RecentlyViewed)
    }
    if ($PSBoundParameters.ContainsKey('EncryptExtracts')) {
        $el_workbook.SetAttribute("encryptExtracts", $EncryptExtracts)
    }
    if ($NewProjectId) {
        $el_project = $el_workbook.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $NewProjectId)
    }
    if ($NewOwnerId) {
        $el_owner = $el_workbook.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($PSBoundParameters.ContainsKey('EnableDataAcceleration')) {
        Assert-TSRestApiVersion -AtLeast 3.16
        $el_dataaccel = $el_workbook.AppendChild($xml.CreateElement("dataAccelerationConfig"))
        $el_dataaccel.SetAttribute("accelerationEnabled", $EnableDataAcceleration)
        if ($PSBoundParameters.ContainsKey('AccelerateNow')) {
            $el_dataaccel.SetAttribute("accelerateNow", $AccelerateNow)
        }
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    if ($PSCmdlet.ShouldProcess($WorkbookId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.workbook
    }
}

function Update-TSWorkbookConnection {
<#
.SYNOPSIS
Update Workbook Connection

.DESCRIPTION
Updates the server address, port, username, or password for the specified workbook connection.

.PARAMETER WorkbookId
The LUID of the workbook to update.

.PARAMETER ConnectionId
The LUID of the connection to update.

.PARAMETER ServerAddress
(Optional) The new server address of the connection.

.PARAMETER ServerPort
(Optional) The new server port of the connection.

.PARAMETER Username
(Optional) The new user name of the connection.

.PARAMETER SecurePassword
(Optional) The new password of the connection, should be supplied as SecurePassword.

.PARAMETER EmbedPassword
(Optional) Boolean switch, if supplied, the connection password is embedded.

.PARAMETER QueryTagging
(Optional) Boolean, true to enable query tagging for the connection.
https://help.tableau.com/current/pro/desktop/en-us/performance_tips.htm

.EXAMPLE
$workbookConnection = Update-TSWorkbookConnection -WorkbookId $sampleWorkbookId -ConnectionId $connectionId -ServerAddress myserver.com

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook_connection
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter(Mandatory)][string] $ConnectionId,
    [Parameter()][string] $ServerAddress,
    [Parameter()][string] $ServerPort,
    [Parameter()][string] $Username,
    [Parameter()][securestring] $SecurePassword,
    [Parameter()][switch] $EmbedPassword,
    [Parameter()][switch] $QueryTagging
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_connection = $tsRequest.AppendChild($xml.CreateElement("connection"))
    if ($ServerAddress) {
        $el_connection.SetAttribute("serverAddress", $ServerAddress)
    }
    if ($ServerPort) {
        $el_connection.SetAttribute("serverPort", $ServerPort)
    }
    if ($Username) {
        $el_connection.SetAttribute("userName", $Username)
    }
    if ($SecurePassword) {
        $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $SecurePassword)).Password
        $el_connection.SetAttribute("password", $private:PlainPassword)
    }
    if ($PSBoundParameters.ContainsKey('EmbedPassword')) {
        $el_connection.SetAttribute("embedPassword", $EmbedPassword)
    }
    if ($PSBoundParameters.ContainsKey('QueryTagging')) {
        Assert-TSRestApiVersion -AtLeast 3.13
        $el_connection.SetAttribute("queryTaggingEnabled", $QueryTagging)
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSWorkbook {
<#
.SYNOPSIS
Delete Workbook / Delete Workbook Revision

.DESCRIPTION
Deletes a published workbook. When a workbook is deleted, all of its assets and revisions are also deleted.
If a specific revision is deleted, the workbook is still available.
It's not possible to delete the latest revision of the workbook.

.PARAMETER WorkbookId
The LUID of the workbook to remove.

.PARAMETER Revision
(Delete Workbook Revision) The revision number of the workbook to delete.

.EXAMPLE
Remove-TSWorkbook -WorkbookId $sampleWorkbookId

.EXAMPLE
Remove-TSWorkbook -WorkbookId $sampleWorkbookId -Revision 2

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_workbook_revision
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter()][int] $Revision
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($Revision) { # Remove Workbook Revision
        # Assert-TSRestApiVersion -AtLeast 2.3
        if ($PSCmdlet.ShouldProcess("$WorkbookId, revision $Revision")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/revisions/$Revision) -Method Delete
        }
    } else { # Remove Workbook
        if ($PSCmdlet.ShouldProcess($WorkbookId)) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId) -Method Delete
        }
    }
}

function Get-TSWorkbookDowngradeInfo {
<#
.SYNOPSIS
Get Workbook Downgrade Info

.DESCRIPTION
Returns a list of the features that would be impacted, and the severity of the impact,
when a workbook is exported as a downgraded version (for instance, exporting a v2019.3 workbook to a v10.5 version).

.PARAMETER WorkbookId
The LUID of the workbook which would be downgraded.

.PARAMETER DowngradeVersion
The Tableau release version number the workbook would be downgraded to.

.EXAMPLE
$downgradeInfo = Get-TSWorkbookDowngradeInfo -WorkbookId $sampleWorkbookId -DowngradeVersion 2019.3

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_downgrade_info
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter(Mandatory)][version] $DowngradeVersion
)
    Assert-TSRestApiVersion -AtLeast 3.5
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/downGradeInfo?productVersion=$DowngradeVersion) -Method Get
    return $response.tsResponse.downgradeInfo
}

function Export-TSWorkbookToFormat {
<#
.SYNOPSIS
Download Workbook as PDF / PowerPoint / Image

.DESCRIPTION
Downloads a .pdf containing images of the sheets that the user has permission to view in a workbook
or
Downloads a PowerPoint (.pptx) file containing slides with images of the sheets that the user has permission to view in a workbook
or
Query Workbook Preview Image

.PARAMETER WorkbookId
The LUID of the workbook to use as the source.

.PARAMETER Format
The output format of the export: pdf, powerpoint or image.

.PARAMETER PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

.PARAMETER PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced. The value can be Portrait or Landscape.
Default is Portrait.

.PARAMETER MaxAge
(Optional) The maximum number of minutes a workbook export output will be cached before being refreshed.

.PARAMETER OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

.EXAMPLE
Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -PageOrientation Landscape -OutFile "export.pdf"

.EXAMPLE
Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "export.pptx"

.EXAMPLE
Export-TSWorkbookToFormat -WorkbookId $sampleWorkbookId -Format image -OutFile "export.png"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_pdf

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_powerpoint

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_preview_image
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter(Mandatory)][ValidateSet('pdf','powerpoint','image')][string] $Format,
    [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid','Unspecified')][string] $PageType = 'A4',
    [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = 'Portrait',
    [Parameter()][int] $MaxAge, # The maximum number of minutes a workbook preview will be cached before being refreshed
    [Parameter()][string] $OutFile
)
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    if ($Format -eq 'pdf') {
        Assert-TSRestApiVersion -AtLeast 3.4
        $uri += "/pdf?type=$PageType&orientation=$PageOrientation"
        if ($MaxAge) {
            $uri += "&maxAge=$MaxAge"
        }
        # $fileType = 'pdf'
    } elseif ($Format -eq 'powerpoint') {
        Assert-TSRestApiVersion -AtLeast 3.8
        $uri += "/powerpoint"
        if ($MaxAge) {
            $uri += "?maxAge=$MaxAge"
        }
        # $fileType = 'pptx'
    } elseif ($Format -eq 'image') {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri += "/previewImage"
        # $fileType = 'png'
    }
    Invoke-TSRestApiMethod -Uri $uri -Method Get -TimeoutSec 600 @OutFileParam
}

function Update-TSWorkbookNow {
<#
.SYNOPSIS
Update Workbook Now

.DESCRIPTION
Performs an immediate extract refresh for the specified workbook.

.PARAMETER WorkbookId
The LUID of the workbook to refresh.

.EXAMPLE
$job = Update-TSWorkbookNow -WorkbookId $workbook.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook_now
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $WorkbookId
)
    Assert-TSRestApiVersion -AtLeast 2.8
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/refresh
    if ($PSCmdlet.ShouldProcess($WorkbookId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body "<tsRequest />" -Method Post -ContentType "application/xml"
        return $response.tsResponse.job
    }
}

### Datasources methods
function Get-TSDatasource {
<#
.SYNOPSIS
Query Data Source / Query Data Sources / Get Data Source Revisions

.DESCRIPTION
Returns information about the specified data source or data sources.

.PARAMETER DatasourceId
(Query Data Source by Id) The LUID of the data source.

.PARAMETER Revisions
(Get Data Source Revisions) Boolean switch, if supplied, the data source revisions are returned.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#datasources

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#datasources

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_datasources

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$datasource = Get-TSDatasource -DatasourceId $datasourceId

.EXAMPLE
$dsRevisions = Get-TSDatasource -DatasourceId $datasourceId -Revisions

.EXAMPLE
$datasources = Get-TSDatasource -Filter "name:eq:$datasourceName" -Sort name:asc -Fields id,name

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_sources

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#get_data_source_revisions
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='DatasourceById')]
    [Parameter(Mandatory,ParameterSetName='DatasourceRevisions')]
    [string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='DatasourceRevisions')][Parameter()][switch] $Revisions,
    [Parameter(ParameterSetName='Datasources')][string[]] $Filter,
    [Parameter(ParameterSetName='Datasources')][string[]] $Sort,
    [Parameter(ParameterSetName='Datasources')][string[]] $Fields,
    [Parameter(ParameterSetName='Datasources')]
    [Parameter(ParameterSetName='DatasourceRevisions')]
    [ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($Revisions) { # Get Data Source Revisions
        # Assert-TSRestApiVersion -AtLeast 2.3
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/revisions
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.revisions.revision
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } elseif ($DatasourceId) { # Query Data Source
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId) -Method Get
        $response.tsResponse.datasource
    } else { # Query Data Sources
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Datasource
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.datasources.datasource
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSDatasourceConnection {
<#
.SYNOPSIS
Query Data Source Connections

.DESCRIPTION
Returns a list of data connections for the specific data source.

.PARAMETER DatasourceId
The LUID of the data source to return connection information about.

.EXAMPLE
$dsConnections = Get-TSDatasourceConnection -DatasourceId $datasourceId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source_connections
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSDatasource {
<#
.SYNOPSIS
Download Data Source / Download Data Source Revision

.DESCRIPTION
Downloads a data source or data source revision in .tds or .tdsx format.

.PARAMETER DatasourceId
The LUID of the data source to be downloaded.

.PARAMETER OutFile
(Optional) Filename where the data source is saved upon download.
If not provided, the downloaded content is piped to the output.

.PARAMETER ExcludeExtract
(Optional) Boolean switch, if supplied and the data source contains an extract, it is not included for the download.

.PARAMETER Revision
(Optional) If revision number is specified, this revision will be downloaded.

.EXAMPLE
Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Superstore_Data.tdsx" -ExcludeExtract

.EXAMPLE
Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Superstore_Data_1.tdsx" -Revision 1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#download_data_source

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#download_data_source_revision
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId,
    [Parameter()][string] $OutFile,
    [Parameter()][switch] $ExcludeExtract,
    [Parameter()][int] $Revision
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
    if ($Revision) {
        # Assert-TSRestApiVersion -AtLeast 2.3
        $lastRevision = Get-TSDatasource -DatasourceId $DatasourceId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
        # Note that the current revision of a datasource cannot be accessed by the /revisions endpoint; in this case we ignore the -Revision parameter
        if ($Revision -lt $lastRevision) {
            $uri += "/revisions/$Revision"
        }
    }
    $uri += "/content"
    if ($ExcludeExtract) {
        Assert-TSRestApiVersion -AtLeast 2.5
        $uri += "?includeExtract=false"
    }
    Invoke-TSRestApiMethod -Uri $uri -Method Get -TimeoutSec 600 @OutFileParam
}

function Publish-TSDatasource {
<#
.SYNOPSIS
Publish Data Source

.DESCRIPTION
Publishes supplied data source.

.PARAMETER InFile
The filename (incl. path) of the data source to upload and publish.

.PARAMETER Name
The name for the published data source.

.PARAMETER FileName
(Optional) The filename (without path) that is included into the request payload.
If omitted, the filename is derived from the InFile parameter.

.PARAMETER FileType
(Optional) The file type of the data source file.
If omitted, the file type is derived from the Filename parameter.

.PARAMETER Description
(Optional) The description for the published data source.

.PARAMETER ProjectId
(Optional) The LUID of the project to assign the data source to.
If the project is not specified, the data source will be published to the default project.

.PARAMETER Overwrite
(Optional) Boolean switch, if supplied, the data source will be overwritten (otherwise existing published data source with the same name is not overwritten).

.PARAMETER Append
(Optional) Boolean switch, if supplied, the data will be appended to the existin data source.
If the data source doesn't already exist, the operation will fail.
Append flag cannot be used together with the Overwrite flag.

.PARAMETER BackgroundTask
(Optional) Boolean switch, if supplied, the publishing process (its final stage) is run asynchronously.

.PARAMETER Chunked
(Optional) Boolean switch, if supplied, the publish process is forced to run as chunked.
By default, the payload is send in one request for files < 64MB size.
This can be helpful if timeouts occur during upload.

.PARAMETER UseRemoteQueryAgent
(Optional) When true, this flag will allow your Tableau Cloud site to use Tableau Bridge clients.
Bridge allows you to maintain data sources with live connections to supported on-premises data sources.

.PARAMETER Credentials
(Optional) Hashtable containing connection credentials (see online help).

.PARAMETER Connections
(Optional) Hashtable array containing connection attributes and credentials (see online help).

.EXAMPLE
$datasource = Publish-TSDatasource -Name $sampleDatasourceName -InFile "Superstore_2023.tdsx" -ProjectId $samplesProjectId -Overwrite

.EXAMPLE
$datasource = Publish-TSDatasource -Name "Datasource" -InFile "data.hyper" -ProjectId $samplesProjectId -Append -Chunked

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#publish_data_source
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $InFile,
    [Parameter(Mandatory)][string] $Name,
    [Parameter()][string] $FileName,
    [Parameter()][string] $FileType,
    [Parameter()][string] $Description,
    [Parameter()][string] $ProjectId,
    [Parameter()][switch] $Overwrite,
    [Parameter()][switch] $Append,
    [Parameter()][switch] $BackgroundTask,
    [Parameter()][switch] $Chunked,
    [Parameter()][switch] $UseRemoteQueryAgent,
    [Parameter()][hashtable] $Credentials,
    [Parameter()][hashtable[]] $Connections
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $fileItem = Get-Item -LiteralPath $InFile
    if (-Not $FileName) {
        $FileName = $fileItem.Name -replace '["`]','' # remove special chars
    }
    if (-Not $FileType) {
        $FileType = $fileItem.Extension.Substring(1)
    }
    if ($FileType -eq 'zip') {
        $FileType = 'tdsx'
        $FileName = $FileName -ireplace 'zip$','tdsx'
    } elseif ($FileType -eq 'xml') {
        $FileType = 'tds'
        $FileName = $FileName -ireplace 'xml$','tds'
    }
    if (-Not ($FileType -In @("tds", "tdsx", "tde", "hyper", "parquet"))) {
        throw "File type unsupported (supported types are: tds, tdsx, tde, hyper, parquet)"
    }
    if ($FileName -match '[^\x20-\x7e]') { # special non-ASCII characters in the filename cause issues on some API versions
        Write-Verbose "Filename $FileName contains special characters, replacing with tableau_datasource.$FileType"
        $FileName = "tableau_datasource.$FileType" # fallback to standard filename (doesn't matter for file upload)
    }
    if ($fileItem.Length -ge $script:TSRestApiFileSizeLimit) {
        $Chunked = $true
    }
    $uri = Get-TSRequestUri -Endpoint Datasource
    $uri += "?datasourceType=$FileType"
    if ($Append) {
        $uri += "&append=true"
    }
    if ($Overwrite) {
        $uri += "&overwrite=true"
    }
    if ($BackgroundTask) {
        Assert-TSRestApiVersion -AtLeast 3.0
        $uri += "&asJob=true"
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_datasource = $tsRequest.AppendChild($xml.CreateElement("datasource"))
    $el_datasource.SetAttribute("name", $Name)
    if ($Description) {
        $el_datasource.SetAttribute("description", $Description)
    }
    if ($UseRemoteQueryAgent) {
        $el_datasource.SetAttribute("useRemoteQueryAgent", "true")
    }
    if ($Connections -and $Credentials) {
        Write-Error "You cannot provide both Connections and Credentials inputs" -Category InvalidArgument -ErrorAction Stop
    }
    if ($Credentials) {
        Add-TSCredentialsElement -Element $el_datasource -Credentials $Credentials
    }
    if ($Connections) {
        Assert-TSRestApiVersion -AtLeast 2.8
        Add-TSConnectionsElement -Element $el_datasource -Connections $Connections
    }
    if ($ProjectId) {
        $el_project = $el_datasource.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $ProjectId)
    }
    $boundaryString = (New-Guid).ToString("N")
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Write-Verbose "Using MultipartFormDataContent as -Body in Invoke-RestMethod (PS6.0+)"
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        $null = $multipartContent.Headers.Remove("Content-Type")
        $null = $multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, [System.Text.Encoding]::UTF8, [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/xml"))
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
        } else {
            $fileStream = New-Object System.IO.FileStream($fileItem.FullName, [System.IO.FileMode]::Open)
            try {
                $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
                $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
                $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
                $fileContent.Headers.ContentDisposition.Name = "tableau_datasource"
                $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
                $multipartContent.Add($fileContent)
                $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
            } finally {
                $fileStream.Dispose()
            }
        }
    } else {
        Write-Verbose "Using String as -Body in Invoke-RestMethod (PS5.x)"
        $bodyLines = @(
            "--$boundaryString",
            "Content-Type: text/xml; charset=utf-8",
            "Content-Disposition: form-data; name=request_payload",
            "",
            $xml.OuterXml
        )
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
        } else {
            $bodyLines += @(
            "--$boundaryString",
            "Content-Type: application/octet-stream",
            "Content-Disposition: form-data; name=tableau_datasource; filename=`"$FileName`"",
            "",
            [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString([System.IO.File]::ReadAllBytes($fileItem.FullName))
            )
        }
        $bodyLines += "--$boundaryString--"
        $multipartContent = $bodyLines -join "`r`n"
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post -ContentType "multipart/mixed; boundary=$boundaryString"
    }
    if ($BackgroundTask) {
        return $response.tsResponse.job
    } else {
        return $response.tsResponse.datasource
    }
}

function Update-TSDatasource {
<#
.SYNOPSIS
Update Data Source

.DESCRIPTION
Updates the owner, project or certification status of the specified data source.

.PARAMETER DatasourceId
The LUID of the data source to update.

.PARAMETER Name
(Optional) The new name for the published data source.

.PARAMETER NewProjectId
(Optional) The LUID of the project where the published data source should be moved.

.PARAMETER NewOwnerId
(Optional) The LUID of the user who should own the data source.

.PARAMETER Certified
(Optional) Boolean switch, if supplied, updates whether the data source is certified.

.PARAMETER CertificationNote
(Optional) A note that provides more information on the certification of the data source, if applicable.

.PARAMETER EncryptExtracts
(Optional) Boolean switch, include to encrypt the embedded extract.

.PARAMETER EnableAskData
(Optional) Boolean switch, determines if a data source allows use of Ask Data.
Note: This attribute is removed in API 3.12 and later (Tableau Cloud September 2021 / Server 2021.3).

.EXAMPLE
$datasource = Update-TSDatasource -DatasourceId $sampleDatasourceId -Certified

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId,
    [Parameter()][string] $Name,
    [Parameter()][string] $NewProjectId,
    [Parameter()][string] $NewOwnerId,
    [Parameter()][switch] $Certified,
    [Parameter()][string] $CertificationNote,
    [Parameter()][switch] $EncryptExtracts,
    [Parameter()][switch] $EnableAskData
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_datasource = $tsRequest.AppendChild($xml.CreateElement("datasource"))
    if ($Name) {
        $el_datasource.SetAttribute("name", $Name)
    }
    if ($PSBoundParameters.ContainsKey('Certified')) {
        $el_datasource.SetAttribute("isCertified", $Certified)
    }
    if ($CertificationNote) {
        $el_datasource.SetAttribute("certificationNote", $CertificationNote)
    }
    if ($PSBoundParameters.ContainsKey('EncryptExtracts')) {
        $el_datasource.SetAttribute("encryptExtracts", $EncryptExtracts)
    }
    if ($NewProjectId) {
        $el_project = $el_datasource.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $NewProjectId)
    }
    if ($NewOwnerId) {
        $el_owner = $el_datasource.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($PSBoundParameters.ContainsKey('EnableAskData')) {
        Assert-TSRestApiVersion -LessThan 3.12
        $el_askdata = $el_datasource.AppendChild($xml.CreateElement("askData"))
        $el_askdata.SetAttribute("enablement", $EnableAskData)
    }
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
    if ($PSCmdlet.ShouldProcess($DatasourceId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.datasource
    }
}

function Update-TSDatasourceConnection {
<#
.SYNOPSIS
Update Data Source Connection

.DESCRIPTION
Updates the server address, port, username, or password for the specified data source connection.

.PARAMETER DatasourceId
The LUID of the data source to update.

.PARAMETER ConnectionId
The LUID of the connection to update.

.PARAMETER ServerAddress
(Optional) The new server address of the connection.

.PARAMETER ServerPort
(Optional) The new server port of the connection.

.PARAMETER Username
(Optional) The new user name of the connection.

.PARAMETER SecurePassword
(Optional) The new password of the connection, should be supplied as SecurePassword.

.PARAMETER EmbedPassword
(Optional) Boolean switch, if supplied, the connection password is embedded.

.PARAMETER QueryTagging
(Optional) Boolean, true to enable query tagging for the connection.
https://help.tableau.com/current/pro/desktop/en-us/performance_tips.htm

.EXAMPLE
$datasourceConnection = Update-TSDatasourceConnection -DatasourceId $sampleDatasourceId -ConnectionId $connectionId -ServerAddress myserver.com

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_connection
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId,
    [Parameter(Mandatory)][string] $ConnectionId,
    [Parameter()][string] $ServerAddress,
    [Parameter()][string] $ServerPort,
    [Parameter()][string] $Username,
    [Parameter()][securestring] $SecurePassword,
    [Parameter()][switch] $EmbedPassword,
    [Parameter()][switch] $QueryTagging
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_connection = $tsRequest.AppendChild($xml.CreateElement("connection"))
    if ($ServerAddress) {
        $el_connection.SetAttribute("serverAddress", $ServerAddress)
    }
    if ($ServerPort) {
        $el_connection.SetAttribute("serverPort", $ServerPort)
    }
    if ($Username) {
        $el_connection.SetAttribute("userName", $Username)
    }
    if ($SecurePassword) {
        $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $SecurePassword)).Password
        $el_connection.SetAttribute("password", $private:PlainPassword)
    }
    if ($PSBoundParameters.ContainsKey('EmbedPassword')) {
        $el_connection.SetAttribute("embedPassword", $EmbedPassword)
    }
    if ($PSBoundParameters.ContainsKey('QueryTagging')) {
        Assert-TSRestApiVersion -AtLeast 3.13
        $el_connection.SetAttribute("queryTaggingEnabled", $QueryTagging)
    }
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSDatasource {
<#
.SYNOPSIS
Delete Data Source / Delete Data Source Revision

.DESCRIPTION
Deletes a published data source.
Note: it's not possible to delete the latest revision of the data source.

.PARAMETER DatasourceId
The LUID of the data source to remove.

.PARAMETER Revision
(Delete Data Source Revision) The revision number of the data source to delete.

.EXAMPLE
Remove-TSDatasource -DatasourceId $sampleDatasourceId

.EXAMPLE
Remove-TSDatasource -DatasourceId $sampleDatasourceId -Revision 1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#delete_data_source

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_data_source_revision
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId,
    [Parameter()][int] $Revision
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($Revision) { # Remove Data Source Revision
        # Assert-TSRestApiVersion -AtLeast 2.3
        if ($PSCmdlet.ShouldProcess("$DatasourceId, revision $Revision")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/revisions/$Revision) -Method Delete
        }
    } else { # Remove Data Source
        if ($PSCmdlet.ShouldProcess($DatasourceId)) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId) -Method Delete
        }
    }
}

function Update-TSDatasourceNow {
<#
.SYNOPSIS
Update Data Source Now

.DESCRIPTION
Performs an immediate extract refresh for the specified data source.

.PARAMETER DatasourceId
The LUID of the data source to refresh.

.EXAMPLE
$job = Update-TSDatasourceNow -DatasourceId $datasource.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_now
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DatasourceId
)
    Assert-TSRestApiVersion -AtLeast 2.8
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/refresh
    if ($PSCmdlet.ShouldProcess($DatasourceId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body "<tsRequest />" -Method Post -ContentType "application/xml"
        return $response.tsResponse.job
    }
}

### Views methods
function Get-TSView {
<#
.SYNOPSIS
Get View / Query Views for Site / Query Views for Workbook

.DESCRIPTION
Returns all the views for the specified site or workbook, or gets the details of a specific view.

.PARAMETER ViewId
Get View: The LUID of the view whose details are requested.

.PARAMETER WorkbookId
Query Views for Workbook: The LUID of the workbook to get the views for.

.PARAMETER IncludeUsageStatistics
Query Views: include this boolean switch to return usage statistics with the views in response.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views
Also: Get View by Path - use Get-TSView with filter viewUrlName:eq:<url>

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_views_site

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$view = Get-TSView -ViewId $viewId

.EXAMPLE
$views = Get-TSView -Filter "name:eq:$viewName" -Sort name:asc -Fields id,name

.EXAMPLE
$viewsInWorkbook = Get-TSView -WorkbookId $workbookId -IncludeUsageStatistics

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_view

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_site

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_workbook
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='ViewById')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='ViewsInWorkbook')][string] $WorkbookId,
    [Parameter(ParameterSetName='ViewsInWorkbook')][switch] $IncludeUsageStatistics,
    [Parameter(ParameterSetName='Views')][string[]] $Filter,
    [Parameter(ParameterSetName='Views')][string[]] $Sort,
    [Parameter(ParameterSetName='Views')][string[]] $Fields,
    [Parameter(ParameterSetName='Views')][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($ViewId) { # Get View
        Assert-TSRestApiVersion -AtLeast 3.0
    }
    if ($ViewId) { # Get View
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId) -Method Get
        $response.tsResponse.view
    } elseif ($WorkbookId) { # Query Views for Workbook
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/views
        if ($IncludeUsageStatistics) {
            $uri += "?includeUsageStatistics=true"
        }
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $response.tsResponse.views.view
    } else { # Query Views for Site
        # Assert-TSRestApiVersion -AtLeast 2.2
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint View
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($IncludeUsageStatistics) {
                $uriParam.Add("includeUsageStatistics", "true")
            }
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.views.view
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Export-TSViewPreviewImage {
<#
.SYNOPSIS
Query View Preview Image

.DESCRIPTION
Returns the thumbnail image for the specified view.

.PARAMETER ViewId
The LUID of the view to return a thumbnail image for.

.PARAMETER WorkbookId
The LUID of the workbook that contains the view to return a thumbnail image for.

.PARAMETER OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

.EXAMPLE
Export-TSViewPreviewImage -ViewId $view.id -WorkbookId $workbookId -OutFile "preview.png"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_with_preview
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $ViewId,
    [Parameter(Mandatory)][string] $WorkbookId,
    [Parameter()][string] $OutFile
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/views/$ViewId/previewImage
    Invoke-TSRestApiMethod -Uri $uri -Method Get -TimeoutSec 600 @OutFileParam
}

function Export-TSViewToFormat {
<#
.SYNOPSIS
Query View PDF / Image / Data

.DESCRIPTION
Returns a specified view rendered as a .pdf file.
or
Returns an image of the specified view.
or
Returns a specified view rendered as data in comma-separated-value (CSV) format.

.PARAMETER ViewId
The LUID of the view to export.

.PARAMETER Format
The output format of the export: pdf, powerpoint or image.

.PARAMETER PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

.PARAMETER PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced. The value can be Portrait or Landscape.
Default is Portrait.

.PARAMETER MaxAge
(Optional) The maximum number of minutes a view export output will be cached before being refreshed.

.PARAMETER VizWidth
The width of the rendered pdf image in pixels, these parameter determine its resolution and aspect ratio.

.PARAMETER VizHeight
The height of the rendered pdf image in pixels, these parameter determine its resolution and aspect ratio.

.PARAMETER Resolution
The resolution of the image (high/standard). Image width and actual pixel density are determined by the display context of the image.
Aspect ratio is always preserved. Set the value to high to ensure maximum pixel density.

.PARAMETER OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

.PARAMETER ViewFilters
Filter expression to modify the view data returned. The expression uses fields in the underlying workbook data to define the filter.
To filter a view using a field, add one or more query parameters to your method call, structured as key=value pairs, prefaced by the constant 'vf_'
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#Filter-query-views

.EXAMPLE
Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "export.pdf" -ViewFilters @{Region="Europe"}

.EXAMPLE
Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "export.png" -Resolution high

.EXAMPLE
Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "export.csv" -ViewFilters @{"Ease of Business (clusters)"="Low"}

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_pdf

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_image

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_data
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ViewId,
    [Parameter(Mandatory)][ValidateSet('pdf','image','csv','excel')][string] $Format,
    [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid','Unspecified')][string] $PageType = 'A4',
    [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = 'Portrait',
    [Parameter()][int] $MaxAge,
    [Parameter()][int] $VizWidth,
    [Parameter()][int] $VizHeight,
    [Parameter()][ValidateSet('standard','high')][string] $Resolution = 'high',
    [Parameter()][string] $OutFile,
    [Parameter()][hashtable] $ViewFilters
)
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
    $uriParam = @{}
    if ($Format -eq 'pdf') {
        Assert-TSRestApiVersion -AtLeast 2.8
        $uri += "/pdf"
        $uriParam.Add('type', $PageType)
        $uriParam.Add('orientation', $PageOrientation)
        if ($VizWidth) {
            $uriParam.Add('vizWidth', $VizWidth)
        }
        if ($VizHeight) {
            $uriParam.Add('vizHeight', $VizHeight)
        }
        # $fileType = 'pdf'
    } elseif ($Format -eq 'image') {
        Assert-TSRestApiVersion -AtLeast 2.5
        $uri += "/image"
        if ($Resolution -eq "high") {
            $uriParam.Add('resolution', $Resolution)
        }
        # $fileType = 'png'
    } elseif ($Format -eq 'csv') {
        Assert-TSRestApiVersion -AtLeast 2.8
        $uri += "/data"
        # $fileType = 'csv'
    } elseif ($Format -eq 'excel') {
        Assert-TSRestApiVersion -AtLeast 3.9
        $uri += "/crosstab/excel"
        # $fileType = 'xlsx'
    }
    if ($MaxAge) {
        $uriParam.Add('maxAge', $MaxAge)
    }
    if ($ViewFilters) {
        $ViewFilters.GetEnumerator() | ForEach-Object {
            $uriParam.Add("vf_"+$_.Key, $_.Value)
        }
    }
    Invoke-TSRestApiMethod -Uri $uri -Body $uriParam -Method Get -TimeoutSec 600 @OutFileParam
}

function Get-TSViewRecommendation {
<#
.SYNOPSIS
Get Recommendations for Views

.DESCRIPTION
Gets a list of views that are recommended for a user.

.EXAMPLE
$recommendations = Get-TSViewRecommendation

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_view_recommendations
#>
[OutputType([PSCustomObject[]])]
Param()
    Assert-TSRestApiVersion -AtLeast 3.7
    $uri = Get-TSRequestUri -Endpoint Recommendation -Param "?type=view"
    $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
    return $response.tsResponse.recommendations.recommendation
}

function Hide-TSViewRecommendation {
<#
.SYNOPSIS
Hide a Recommendation for a View

.DESCRIPTION
Hides a view from being recommended by the server by adding it to a list of views that are dismissed for a user.

.PARAMETER ViewId
The LUID of the view to be added to the list of views hidden from recommendation for a user.

.EXAMPLE
Hide-TSViewRecommendation -ViewId $viewId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#hide_view_recommendation
#>
[OutputType([string])]
Param(
    [Parameter(Mandatory)][string] $ViewId
)
    Assert-TSRestApiVersion -AtLeast 3.7
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_rd = $tsRequest.AppendChild($xml.CreateElement("recommendationDismissal"))
    $el_view = $el_rd.AppendChild($xml.CreateElement("view"))
    $el_view.SetAttribute("id", $ViewId)
    $uri = Get-TSRequestUri -Endpoint Recommendation -Param dismissals
    Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
}

function Show-TSViewRecommendation {
<#
.SYNOPSIS
Unhide a Recommendation for a View

.DESCRIPTION
Unhides a view from being recommended by the server by removing it from the list of views that are dimissed for a user.

.PARAMETER ViewId
The LUID of the view to be removed from the list of views hidden from recommendation for a user.

.EXAMPLE
Show-TSViewRecommendation -ViewId $viewId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#unhide_view_recommendation
#>
[OutputType([string])]
Param(
    [Parameter(Mandatory)][string] $ViewId
)
    Assert-TSRestApiVersion -AtLeast 3.7
    $uri = Get-TSRequestUri -Endpoint Recommendation -Param "dismissals/?type=view&id=$ViewId"
    Invoke-TSRestApiMethod -Uri $uri -Method Delete
}

function Get-TSCustomView {
<#
.SYNOPSIS
Get Custom View / List Custom Views

.DESCRIPTION
Gets the details of a specified custom view, or a list of custom views on a site.

.PARAMETER CustomViewId
(Get Custom View) The LUID for the custom view.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views
Also: Get View by Path - use Get-TSView with filter viewUrlName:eq:<url>

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_views_site

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$customView = Get-TSCustomView -CustomViewId $id

.EXAMPLE
$views = Get-TSCustomView -Filter "name:eq:Overview"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_custom_views
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='CustomViewById')][string] $CustomViewId,
    [Parameter(ParameterSetName='CustomViews')][string[]] $Filter,
    [Parameter(ParameterSetName='CustomViews')][string[]] $Sort,
    [Parameter(ParameterSetName='CustomViews')][string[]] $Fields,
    [Parameter(ParameterSetName='CustomViews')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.18
    if ($CustomViewId) { # Get Custom View
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint CustomView -Param $CustomViewId) -Method Get
        $response.tsResponse.customView
    } else { # List Custom Views
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint CustomView
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.customViews.customView
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSCustomViewAsUserDefault {
<#
.SYNOPSIS
List Users with Custom View as Default

.DESCRIPTION
Gets the list of users whose default view is the specified custom view.

.PARAMETER CustomViewId
The LUID for the custom view.

.EXAMPLE
$users = Get-TSCustomViewAsUserDefault -CustomViewId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $CustomViewId
)
    Assert-TSRestApiVersion -AtLeast 3.21
    $uri = Get-TSRequestUri -Endpoint CustomView -Param "$CustomViewId/default/users"
    $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
    return $response.tsResponse.users.user
}

function Set-TSCustomViewAsUserDefault {
<#
.SYNOPSIS
Set Custom View as Default for Users

.DESCRIPTION
Sets the specified custom for as the default view for up to 100 specified users.

.PARAMETER CustomViewId
The LUID for the custom view.

.PARAMETER UserId
List of user LUIDs.

.EXAMPLE
$result = Set-TSCustomViewAsUserDefault -CustomViewId $id -UserId $user1,$user2

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#set_custom_view_as_default_for_users
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $CustomViewId,
    [Parameter(Mandatory)][string[]] $UserId
)
    Assert-TSRestApiVersion -AtLeast 3.21
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_users = $tsRequest.AppendChild($xml.CreateElement("users"))
    foreach ($id in $UserId) {
        $el_user = $el_users.AppendChild($xml.CreateElement("user"))
        $el_user.SetAttribute("id", $id)
    }
    $uri = Get-TSRequestUri -Endpoint CustomView -Param "$CustomViewId/default/users"
    if ($PSCmdlet.ShouldProcess("custom view: $CustomViewId, user: $UserId")) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post
        return $response.tsResponse.customViewAsUserDefaultResults.customViewAsUserDefaultViewResult
    }
}

function Export-TSCustomViewImage {
<#
.SYNOPSIS
Get Custom View Image

.DESCRIPTION
Downloads a .png format image file of a specified custom view.

.PARAMETER CustomViewId
The LUID of the custom view.

.PARAMETER MaxAge
(Optional) The maximum number of minutes a view export output will be cached before being refreshed.

.PARAMETER Resolution
The resolution of the image (high/standard). Image width and actual pixel density are determined by the display context of the image.
Aspect ratio is always preserved. Set the value to high to ensure maximum pixel density.

.PARAMETER OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

.PARAMETER ViewFilters
Filter expression to modify the view data returned. The expression uses fields in the underlying workbook data to define the filter.
To filter a view using a field, add one or more query parameters to your method call, structured as key=value pairs, prefaced by the constant 'vf_'
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#Filter-query-views

.EXAMPLE
Export-TSCustomViewImage -CustomViewId $id -OutFile "export.png" -Resolution high

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view_image
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $CustomViewId,
    [Parameter()][int] $MaxAge,
    [Parameter()][ValidateSet('standard','high')][string] $Resolution = "high",
    [Parameter()][string] $OutFile,
    [Parameter()][hashtable] $ViewFilters
)
    Assert-TSRestApiVersion -AtLeast 3.18
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint CustomView -Param $CustomViewId
    $uriParam = @{}
    $uri += "/image"
    if ($Resolution -eq "high") {
        $uriParam.Add('resolution', $Resolution)
    }
    if ($MaxAge) {
        $uriParam.Add('maxAge', $MaxAge)
    }
    if ($ViewFilters) {
        $ViewFilters.GetEnumerator() | ForEach-Object {
            $uriParam.Add("vf_"+$_.Key, $_.Value)
        }
    }
    Invoke-TSRestApiMethod -Uri $uri -Body $uriParam -Method Get -TimeoutSec 600 @OutFileParam
}

function Update-TSCustomView {
<#
.SYNOPSIS
Update Custom View

.DESCRIPTION
Changes the owner or name of an existing custom view.

.PARAMETER CustomViewId
The LUID for the custom view being updated.

.PARAMETER NewName
(Optional) The new name of the custom view that replaces the existing one.

.PARAMETER NewOwnerId
(Optional) The LUID of the new owner of custom view that replaces the existing one.

.EXAMPLE
$result = Update-TSCustomView -CustomViewId $id -Name "My Custom View"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_custom_view
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $CustomViewId,
    [Parameter()][string] $NewName,
    [Parameter()][string] $NewOwnerId
)
    Assert-TSRestApiVersion -AtLeast 3.18
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_cview = $tsRequest.AppendChild($xml.CreateElement("customView"))
    if ($NewName) {
        $el_cview.SetAttribute("name", $NewName)
    }
    if ($NewOwnerId) {
        $el_owner = $el_cview.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($PSCmdlet.ShouldProcess($CustomViewId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint CustomView -Param $CustomViewId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.customView
    }
}

function Remove-TSCustomView {
<#
.SYNOPSIS
Delete Custom View

.DESCRIPTION
Deletes the specified custom view.

.PARAMETER CustomViewId
The LUID for the custom view being removed.

.EXAMPLE
Remove-TSCustomView -CustomViewId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_custom_view
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $CustomViewId
)
    Assert-TSRestApiVersion -AtLeast 3.18
    if ($PSCmdlet.ShouldProcess($CustomViewId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint CustomView -Param $CustomViewId) -Method Delete
    }
}

function Get-TSViewUrl {
<#
.SYNOPSIS
Get View URL

.DESCRIPTION
Returns the full URL of the specified view.

.PARAMETER ViewId
The LUID of the specified view. Either ViewId or ContentUrl needs to be provided.

.PARAMETER ContentUrl
The content URL of the specified view. Either ViewId or ContentUrl needs to be provided.

.EXAMPLE
Get-TSViewUrl -ViewId $view.id
#>
[OutputType([string])]
Param(
    [Parameter(Mandatory,ParameterSetName='ViewId')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='ContentUrl')][string] $ContentUrl
)
    if ($ViewId) {
        $view = Get-TSView -ViewId $ViewId
        $ContentUrl = $view.contentUrl
    }
    $currentSite = Get-TSSite -Current
    $viewUrl = $script:TSServerUrl + "/#/"
    if ($currentSite.contentUrl) { # non-default site
        $viewUrl += "site/" + $currentSite.contentUrl
    }
    $viewUrl += "/views/" + $ContentUrl.Replace("/sheets/","/")
    return $viewUrl
}

### Flows methods
function Get-TSFlow {
<#
.SYNOPSIS
Query Flow / Query Flows / Query Flow Revisions

.DESCRIPTION
Returns information about the specified flow, or flows.

.PARAMETER FlowId
(Query Flow by Id) The LUID of the flow.

.PARAMETER Revisions
(Get Flow Revisions) Boolean switch, if supplied, the flow revisions are returned.
Note: reserved for future use, flow revisions are currently not supported via REST API

.PARAMETER OutputSteps
(Optional, Query Flow) Boolean switch, if supplied, the flow output steps are returned, instead of flow.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flows

.PARAMETER Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flows

.PARAMETER Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_flows

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$flow = Get-TSFlow -FlowId $flowId

.EXAMPLE
$outputSteps = Get-TSFlow -FlowId $flowId -OutputSteps

.EXAMPLE
$flows = Get-TSFlow -Filter "name:eq:$flowName"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_site
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='FlowById')]
    [Parameter(Mandatory,ParameterSetName='FlowRevisions')]
    [string] $FlowId,
    [Parameter(Mandatory,ParameterSetName='FlowRevisions')][switch] $Revisions, # Note: flow revisions currently not supported via REST API
    [Parameter(ParameterSetName='FlowById')][switch] $OutputSteps,
    [Parameter(ParameterSetName='Flows')][string[]] $Filter,
    [Parameter(ParameterSetName='Flows')][string[]] $Sort,
    [Parameter(ParameterSetName='Flows')][string[]] $Fields,
    [Parameter(ParameterSetName='Flows')]
    [Parameter(ParameterSetName='FlowRevisions')]
    [ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.3
    if ($Revisions) { # Get Flow Revisions
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/revisions
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.revisions.revision
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } elseif ($FlowId) { # Get Flow
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Method Get
        if ($OutputSteps) { # Get Flow, return output steps
            $response.tsResponse.flowOutputSteps.flowOutputStep
        } else { # Get Flow
            $response.tsResponse.flow
        }
    } else { # Query Flows on Site
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Flow
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.flows.flow
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSFlowsForUser {
<#
.SYNOPSIS
Query Flows for User

.DESCRIPTION
Returns the flows that the specified user owns or has read (view) permissions for.

.PARAMETER UserId
The LUID of the user to get flows for.

.PARAMETER IsOwner
(Optional) Boolean switch, if supplied, returns only flows that the specified user owns.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$flows = Get-TSFlowsForUser -UserId (Get-TSCurrentUserId)

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_user
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][switch] $IsOwner,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint User -Param $UserId/flows
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        if ($IsOwner) { $uri += "&ownedBy=true" }
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.flows.flow
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Get-TSFlowConnection {
<#
.SYNOPSIS
Query Flow Connections

.DESCRIPTION
Returns a list of data connections for the specific flow.

.PARAMETER FlowId
The LUID of the flow to return connection information about.

.EXAMPLE
$connections = Get-TSFlowConnection -FlowId $flowId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_connections
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $FlowId
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSFlow {
<#
.SYNOPSIS
Download Flow

.DESCRIPTION
Downloads a flow in .tfl or .tflx format.

.PARAMETER FlowId
The LUID of the flow to download.

.PARAMETER OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

.PARAMETER Revision
(Optional) If revision number is specified, this revision will be downloaded.
Note: reserved for future use, flow revisions are currently not supported via REST API

.EXAMPLE
Export-TSFlow -FlowId $sampleflowId -OutFile "Flow.tflx"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#download_flow
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowId,
    [Parameter()][string] $OutFile,
    [Parameter()][int] $Revision
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId
    if ($Revision) {
        $lastRevision = Get-TSFlow -FlowId $FlowId -Revisions | Sort-Object revisionNumber -Descending | Select-Object -First 1 -ExpandProperty revisionNumber
        # Note that the current revision of a flow cannot be accessed by the /revisions endpoint; in this case we ignore the -Revision parameter
        if ($Revision -lt $lastRevision) {
            $uri += "/revisions/$Revision"
        }
    }
    $uri += "/content"
    Invoke-TSRestApiMethod -Uri $uri -Method Get -TimeoutSec 600 @OutFileParam
}

function Publish-TSFlow {
<#
.SYNOPSIS
Publish Flow

.DESCRIPTION
Publishes a flow on the current site.

.PARAMETER InFile
The filename (incl. path) of the flow to upload and publish.

.PARAMETER Name
The name for the published flow.

.PARAMETER FileName
(Optional) The filename (without path) that is included into the request payload.
If omitted, the filename is derived from the InFile parameter.

.PARAMETER FileType
(Optional) The file type of the flow file.
If omitted, the file type is derived from the Filename parameter.

.PARAMETER ProjectId
(Optional) The LUID of the project to assign the flow to.
If the project is not specified, the flow will be published to the default project.

.PARAMETER Overwrite
(Optional) Boolean switch, if supplied, the flow will be overwritten (otherwise existing published flow with the same name is not overwritten).

.PARAMETER Chunked
(Optional) Boolean switch, if supplied, the publish process is forced to run as chunked.
By default, the payload is send in one request for files < 64MB size.
This can be helpful if timeouts occur during upload.

.PARAMETER Connections
(Optional) Hashtable array containing connection attributes and credentials (see online help).

.EXAMPLE
$flow = Publish-TSFlow -Name $sampleFlowName -InFile "Flow.tflx" -ProjectId $projectId -Overwrite

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#publish_flow
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $InFile,
    [Parameter(Mandatory)][string] $Name,
    [Parameter()][string] $FileName,
    [Parameter()][string] $FileType,
    [Parameter()][string] $ProjectId,
    [Parameter()][switch] $Overwrite,
    [Parameter()][switch] $Chunked,
    # [Parameter()][hashtable] $Credentials, # connectionCredentials is not supported in this API method
    [Parameter()][hashtable[]] $Connections
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $fileItem = Get-Item -LiteralPath $InFile
    if (-Not $FileName) {
        $FileName = $fileItem.Name -replace '["`]','' # remove special chars
    }
    if (-Not $FileType) {
        $FileType = $fileItem.Extension.Substring(1)
    }
    if ($FileType -eq 'zip') {
        $FileType = 'tflx'
        $FileName = $FileName -ireplace 'zip$','tflx'
    } elseif ($FileType -eq 'xml') {
        $FileType = 'tfl'
        $FileName = $FileName -ireplace 'xml$','tfl'
    }
    if (-Not ($FileType -In @("tfl", "tflx"))) {
        throw "File type unsupported (supported types are: tfl, tflx)"
    }
    if ($FileName -match '[^\x20-\x7e]') { # special non-ASCII characters in the filename cause issues on some API versions
        Write-Verbose "Filename $FileName contains special characters, replacing with tableau_flow.$FileType"
        $FileName = "tableau_flow.$FileType" # fallback to standard filename (doesn't matter for file upload)
    }
    if ($fileItem.Length -ge $script:TSRestApiFileSizeLimit) {
        $Chunked = $true
    }
    $uri = Get-TSRequestUri -Endpoint Flow
    $uri += "?flowType=$FileType"
    if ($Overwrite) {
        $uri += "&overwrite=true"
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_flow = $tsRequest.AppendChild($xml.CreateElement("flow"))
    $el_flow.SetAttribute("name", $Name)
    # if ($Credentials) {
    #     Add-TSCredentialsElement -Element $tsRequest -Credentials $Credentials
    # }
    if ($Connections) {
        Add-TSConnectionsElement -Element $tsRequest -Connections $Connections
    }
    if ($ProjectId) {
        $el_project = $el_flow.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $ProjectId)
    }
    $boundaryString = (New-Guid).ToString("N")
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Write-Verbose "Using MultipartFormDataContent as -Body in Invoke-RestMethod (PS6.0+)"
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        $null = $multipartContent.Headers.Remove("Content-Type")
        $null = $multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, [System.Text.Encoding]::UTF8, [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/xml"))
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
        } else {
            $fileStream = New-Object System.IO.FileStream($fileItem.FullName, [System.IO.FileMode]::Open)
            try {
                $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
                $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
                $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
                $fileContent.Headers.ContentDisposition.Name = "tableau_flow"
                $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
                $multipartContent.Add($fileContent)
                $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post
            } finally {
                $fileStream.Dispose()
            }
        }
    } else {
        Write-Verbose "Using String as -Body in Invoke-RestMethod (PS5.x)"
        $bodyLines = @(
            "--$boundaryString",
            "Content-Type: text/xml; charset=utf-8",
            "Content-Disposition: form-data; name=request_payload",
            "",
            $xml.OuterXml
        )
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName
            $uri += "&uploadSessionId=$uploadSessionId"
        } else {
            $bodyLines += @(
            "--$boundaryString",
            "Content-Type: application/octet-stream",
            "Content-Disposition: form-data; name=tableau_flow; filename=`"$FileName`"",
            "",
            [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString([System.IO.File]::ReadAllBytes($fileItem.FullName))
            )
        }
        $bodyLines += "--$boundaryString--"
        $multipartContent = $bodyLines -join "`r`n"
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $multipartContent -Method Post -ContentType "multipart/mixed; boundary=$boundaryString"
    }
    return $response.tsResponse.flow
}

function Update-TSFlow {
<#
.SYNOPSIS
Update Flow

.DESCRIPTION
Updates the owner, project, of the specified flow.

.PARAMETER FlowId
The LUID of the flow to update.

.PARAMETER NewProjectId
(Optional) The LUID of a project to add the flow to.

.PARAMETER NewOwnerId
(Optional) The LUID of a user to assign the flow to as owner.

.EXAMPLE
$flow = Update-TSFlow -FlowId $flow.id -NewProjectId $project.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#update_flow
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowId,
    [Parameter()][string] $NewProjectId,
    [Parameter()][string] $NewOwnerId
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_flow = $tsRequest.AppendChild($xml.CreateElement("flow"))
    if ($NewProjectId) {
        $el_project = $el_flow.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $NewProjectId)
    }
    if ($NewOwnerId) {
        $el_owner = $el_flow.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($PSCmdlet.ShouldProcess($FlowId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.flow
    }
}

function Update-TSFlowConnection {
<#
.SYNOPSIS
Update Flow Connection

.DESCRIPTION
Updates the server address, port, username, or password for the specified flow connection.

.PARAMETER FlowId
The LUID of the data source to update.

.PARAMETER ConnectionId
The LUID of the connection to update.

.PARAMETER ServerAddress
(Optional) The new server address of the connection.

.PARAMETER ServerPort
(Optional) The new server port of the connection.

.PARAMETER Username
(Optional) The new user name of the connection.

.PARAMETER SecurePassword
(Optional) The new password of the connection, should be supplied as SecurePassword.

.PARAMETER EmbedPassword
(Optional) Boolean switch, if supplied, the connection password is embedded.

.EXAMPLE
$flowConnection = Update-TSFlowConnection -FlowId $flow.id -ConnectionId $connectionId -ServerAddress myserver.com

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#update_flow_connection
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowId,
    [Parameter(Mandatory)][string] $ConnectionId,
    [Parameter()][string] $ServerAddress,
    [Parameter()][string] $ServerPort,
    [Parameter()][string] $Username,
    [Parameter()][securestring] $SecurePassword,
    [Parameter()][switch] $EmbedPassword
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_connection = $tsRequest.AppendChild($xml.CreateElement("connection"))
    if ($ServerAddress) {
        $el_connection.SetAttribute("serverAddress", $ServerAddress)
    }
    if ($ServerPort) {
        $el_connection.SetAttribute("serverPort", $ServerPort)
    }
    if ($Username) {
        $el_connection.SetAttribute("userName", $Username)
    }
    if ($SecurePassword) {
        $private:PlainPassword = (New-Object System.Net.NetworkCredential("", $SecurePassword)).Password
        $el_connection.SetAttribute("password", $private:PlainPassword)
    }
    if ($PSBoundParameters.ContainsKey('EmbedPassword')) {
        $el_connection.SetAttribute("embedPassword", $EmbedPassword)
    }
    $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSFlow {
<#
.SYNOPSIS
Delete Flow

.DESCRIPTION
Deletes a flow.
When a flow is deleted, its associated connections, the output and input steps, any associated scheduled tasks, and run history are also deleted.

.PARAMETER FlowId
The LUID of the flow to delete.

.PARAMETER Revision
(Optional) If revision number is specified, this revision will be removed.
Note: reserved for future use, flow revisions are currently not supported via REST API

.EXAMPLE
Remove-TSFlow -FlowId $sampleFlowId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowId,
    [Parameter()][int] $Revision # Note: flow revisions currently not supported via REST API
)
    Assert-TSRestApiVersion -AtLeast 3.3
    if ($Revision) { # Remove Flow Revision
        if ($PSCmdlet.ShouldProcess("$FlowId, revision $Revision")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $FlowId/revisions/$Revision) -Method Delete
        }
    } else { # Remove Flow
        if ($PSCmdlet.ShouldProcess($FlowId)) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Method Delete
        }
    }
}

function Start-TSFlowNow {
<#
.SYNOPSIS
Run Flow Now

.DESCRIPTION
Runs the specified flow (asynchronously).

.PARAMETER FlowId
The LUID of the flow to run.

.PARAMETER RunMode
(Optional) The mode to use for running this flow, either 'full' or 'incremental'. Default is 'full'.

.PARAMETER OutputStepId
(Optional) The LUID of the output steps you want to run.

.PARAMETER FlowParams
(Optional) The hashtable of the flow parameters, with flow parameter IDs and values.

.EXAMPLE
$job = Start-TSFlowNow -FlowId $flow.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_now
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowId,
    [Parameter()][ValidateSet('full','incremental')][string] $RunMode = 'full',
    [Parameter()][string] $OutputStepId,
    [Parameter()][hashtable] $FlowParams
)
    Assert-TSRestApiVersion -AtLeast 3.3
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_frs = $tsRequest.AppendChild($xml.CreateElement("flowRunSpec"))
    $el_frs.SetAttribute("flowId", $FlowId)
    $el_frs.SetAttribute("runMode", $RunMode)
    if ($OutputStepId) {
        $el_steps = $el_frs.AppendChild($xml.CreateElement("flowOutputSteps"))
        $el_step = $el_steps.AppendChild($xml.CreateElement("flowOutputStep"))
        $el_step.SetAttribute("id", $OutputStepId)
    }
    if ($FlowParams) {
        Assert-TSRestApiVersion -AtLeast 3.15
        $el_params = $el_frs.AppendChild($xml.CreateElement("flowParameterSpecs"))
        $FlowParams.GetEnumerator() | ForEach-Object {
            $el_param = $el_params.AppendChild($xml.CreateElement("flowParameterSpec"))
            $el_param.SetAttribute("parameterId", $_.Key)
            $el_param.SetAttribute("overrideValue", $_.Value)
        }
    }
    $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/run
    if ($PSCmdlet.ShouldProcess($FlowId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post
        return $response.tsResponse.job
    }
}

function Get-TSFlowRun {
<#
.SYNOPSIS
Get Flow Run / Get Flow Runs

.DESCRIPTION
Gets a specific flow run details, or flow runs.

.PARAMETER FlowRunId
(Get Flow Run by Id) The LUID of the flow run.

.PARAMETER Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flow-runs

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$run = Get-TSFlowRun -FlowRunId $id

.EXAMPLE
$runs = Get-TSFlowRun -Filter "flowId:eq:$($flowRun.flowId)"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_runs
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='FlowRunById')][string] $FlowRunId,
    [Parameter(ParameterSetName='FlowRuns')][string[]] $Filter,
    [Parameter(ParameterSetName='FlowRuns')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.10
    if ($FlowRunId) { # Get Flow Run
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param runs/$FlowRunId) -Method Get
        $response.tsResponse.flowRun
    } else { # Get Flow Runs
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Flow -Param runs
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.flowRuns.flowRuns
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Stop-TSFlowRun {
<#
.SYNOPSIS
Cancel Flow Run

.DESCRIPTION
Cancels a flow run that is in progress.
If the flow run was cancelled successfully, $null is returned, otherwise the response error is returned.

.PARAMETER FlowRunId
The LUID of the flow run.

.EXAMPLE
Stop-TSFlowRun -FlowRunId $run.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#cancel_flow_run
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $FlowRunId
)
    Assert-TSRestApiVersion -AtLeast 3.10
    if ($PSCmdlet.ShouldProcess($FlowRunId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param runs/$FlowRunId) -Method Put
        if ($response.tsResponse.error) {
            return $response.tsResponse.error
        } else {
            return $null # Flow run cancelled successfully
        }
    }
}

### Permissions methods
function Get-TSContentPermission {
<#
.SYNOPSIS
Query Workbook / Data Source / View / Project / Flow Permissions

.DESCRIPTION
Returns a list of permissions for the specific workbook (or data source / view / project / flow).

.PARAMETER WorkbookId
The LUID of the workbook to get permissions for.

.PARAMETER DatasourceId
The LUID of the data source to get permissions for.

.PARAMETER ViewId
The LUID of the view to get permissions for.

.PARAMETER ProjectId
The LUID of the project to get permissions for.

.PARAMETER FlowId
The LUID of the flow to get permissions for.

.EXAMPLE
$permissions = Get-TSContentPermission -WorkbookId $workbookId

.EXAMPLE
$permissions = Get-TSContentPermission -DatasourceId $datasourceId

.EXAMPLE
$permissions = Get-TSContentPermission -ProjectId $project.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($WorkbookId) {
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    } elseif ($DatasourceId) {
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
    } elseif ($ProjectId) {
        $uri = Get-TSRequestUri -Endpoint Project -Param $ProjectId
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId
    }
    $uri += "/permissions"
    $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
    return $response.tsResponse.permissions
}

function Add-TSContentPermission {
<#
.SYNOPSIS
Add Workbook / Data Source / View / Project / Flow Permissions

.DESCRIPTION
Adds permissions to the specified content for list of grantees (Tableau user or group).
You can specify multiple sets of permissions using one call.

.PARAMETER WorkbookId
The LUID of the workbook to add permissions for.

.PARAMETER DatasourceId
The LUID of the data source to add permissions for.

.PARAMETER ViewId
The LUID of the view to add permissions for.

.PARAMETER ProjectId
The LUID of the project to add permissions for.

.PARAMETER FlowId
The LUID of the flow to add permissions for.

.PARAMETER PermissionTable
A list of permissions (hashtable), each item must be structured as follows:
- granteeType: 'user' or 'group'
- granteeId: the LUID of the user or group
- capabilities: hashtable with all permissions to add, the key is capability name and the value is allow or deny
Note: existing capabilities are not removed.

.EXAMPLE
$permissions = Add-TSContentPermission -WorkbookId $workbook.id -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"}}

.EXAMPLE
$permissions = Add-TSContentPermission -FlowId $flow.id -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Execute="Allow"}}

.NOTES
This method uses the corresponding REST API method directly.
This implies that existing permissions which are conflicting with the permissions to be added, the response will be an error.
To fall back to override existing permissions, and to use permission templates, check Set-TSContentPermission.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId,
    [Parameter(Mandatory)][hashtable[]] $PermissionTable
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_pm = $tsRequest.AppendChild($xml.CreateElement("permissions"))
    if ($WorkbookId) {
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        # $el_pm.AppendChild($xml.CreateElement("workbook")).SetAttribute("id", $WorkbookId)
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        # $el_pm.AppendChild($xml.CreateElement("datasource")).SetAttribute("id", $DatasourceId)
        $shouldProcessItem = "datasource:$DatasourceId"
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
        # $el_pm.AppendChild($xml.CreateElement("view")).SetAttribute("id", $ViewId)
        $shouldProcessItem = "view:$ViewId"
    } elseif ($ProjectId) {
        $uri = Get-TSRequestUri -Endpoint Project -Param $ProjectId
        # $el_pm.AppendChild($xml.CreateElement("project")).SetAttribute("id", $ProjectId)
        $shouldProcessItem = "project:$ProjectId"
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId
        # $el_pm.AppendChild($xml.CreateElement("flow")).SetAttribute("id", $FlowId)
        $shouldProcessItem = "flow:$FlowId"
    }
    $uri += "/permissions"
    $permissionsCount = 0
    foreach ($permission in $PermissionTable) {
        $el_gc = $el_pm.AppendChild($xml.CreateElement("granteeCapabilities"))
        $el_gc.AppendChild($xml.CreateElement($permission.granteeType.ToLower())).SetAttribute("id", $permission.granteeId)
        $el_caps = $el_gc.AppendChild($xml.CreateElement("capabilities"))
        $permissionsCount += $permission.capabilities.Count
        $permission.capabilities.GetEnumerator() | ForEach-Object {
            $el_cap = $el_caps.AppendChild($xml.CreateElement("capability"))
            $el_cap.SetAttribute("name", $_.Key)
            $el_cap.SetAttribute("mode", $_.Value)
        }
    }
    $shouldProcessItem += ", grantees:{0}, permissions:{1}" -f $PermissionTable.Length, $permissionsCount
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.permissions
    }
}

function Set-TSContentPermission {
<#
.SYNOPSIS
Set Workbook / Data Source / View / Project / Flow Permissions

.DESCRIPTION
Sets permissions to the specified content for list of grantees (Tableau user or group).
This method is a wrapper for Set-TSContentPermission with support for overriding conflicting permissions and permission templates.
You can specify multiple sets of permissions using one call, and use permission templates (similar to Tableau Server UI).

.PARAMETER WorkbookId
The LUID of the workbook to set permissions for.

.PARAMETER DatasourceId
The LUID of the data source to set permissions for.

.PARAMETER ViewId
The LUID of the view to set permissions for.

.PARAMETER ProjectId
The LUID of the project to set permissions for.

.PARAMETER FlowId
The LUID of the flow to set permissions for.

.PARAMETER PermissionTable
A list of permissions (hashtable), each item must be structured as follows:
- granteeType: 'user' or 'group'
- granteeId: the LUID of the user or group
- capabilities: hashtable with all permissions to add, the key is capability name and the value is allow or deny
Note: existing capabilities are removed for the same capability names, but other capabilities are untouched.
- template: can be used instead of 'capabilities'. This corresponds to selecting "Template" in Tableau Server UI.
The following templates are supported: View, Explore, Publish, Administer, Denied, None
Note: existing capabilities are removed for the grantee, if template is used.

.EXAMPLE
$permissions = Set-TSContentPermission -ProjectId $projectId -PermissionTable @{granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"}}

.EXAMPLE
$permissions = Set-TSContentPermission -DatasourceId $datasourceId -PermissionTable @{granteeType="Group"; granteeId=$groupId; template='Publish'}

.NOTES
This method is similar to Add-TSContentPermission, but it can also override existing permissions, and supports permission templates.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId,
    [Parameter(Mandatory)][hashtable[]] $PermissionTable
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $MainParam = @{}
    if ($WorkbookId) {
        $shouldProcessItem = "workbook:$WorkbookId"
        $MainParam.Add("WorkbookId", $WorkbookId)
    } elseif ($DatasourceId) {
        $shouldProcessItem = "datasource:$DatasourceId"
        $MainParam.Add("DatasourceId", $DatasourceId)
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $shouldProcessItem = "view:$ViewId"
        $MainParam.Add("ViewId", $ViewId)
    } elseif ($ProjectId) {
        $shouldProcessItem = "project:$ProjectId"
        $MainParam.Add("ProjectId", $ProjectId)
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $shouldProcessItem = "flow:$FlowId"
        $MainParam.Add("FlowId", $FlowId)
    }
    $permissionsCount = 0
    $permissionOverrides = @()
    $currentPermissionTable = Get-TSContentPermission @MainParam | ConvertTo-TSPermissionTable
    $addPermissionTable = @()
    foreach ($permission in $PermissionTable) {
        if ($permission.capabilities) {
            $permissionsCount += $permission.capabilities.Count
            $currentPermissionTable | Where-Object -FilterScript {($_.granteeType -eq $permission.granteeType) -and ($_.granteeId -eq $permission.granteeId)} | ForEach-Object {
                $currentCapabilities = $_.capabilities
                $currentCapabilities.GetEnumerator() | ForEach-Object {
                    $capabilityName = $_.Key
                    $capabilityMode = $_.Value
                    if ($permission.capabilities.ContainsKey($capabilityName) -and $capabilityMode -ne $permission.capabilities[$capabilityName]) {
                        $permissionOverrides += @{granteeType=$permission.granteeType; granteeId=$permission.granteeId; capabilityName=$capabilityName; capabilityMode=$capabilityMode}
                    }
                }
            }
            $addPermissionTable += $permission
        } elseif ($permission.template) { # support for permission templates
            switch ($permission.template) {
                'View' {
                    if ($WorkbookId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData'
                    } elseif ($ViewId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData'
                    } elseif ($DatasourceId) {
                        $capabilities = 'Read','Connect'
                    } elseif ($FlowId) {
                        $capabilities = 'Read'
                    } elseif ($ProjectId) {
                        $capabilities = 'Read'
                    }
                }
                'Explore' {
                    if ($WorkbookId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData'
                    } elseif ($ViewId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring'
                    } elseif ($DatasourceId) {
                        $capabilities = 'Read','Connect','ExportXml'
                    } elseif ($FlowId) {
                        $capabilities = 'Read','ExportXml'
                    } elseif ($ProjectId) {
                        $capabilities = 'Read' # fallback to View
                    }
                }
                'Publish' {
                    if ($WorkbookId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics'
                    } elseif ($ViewId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring' # fallback to Explore
                    } elseif ($DatasourceId) {
                        $capabilities = 'Read','Connect','ExportXml','Write','SaveAs'
                    } elseif ($FlowId) {
                        $capabilities = 'Read','ExportXml','Execute','Write','WebAuthoringForFlows'
                    } elseif ($ProjectId) {
                        $capabilities = 'Read','Write'
                    }
                }
                {$_ -in 'Administer','Denied'} { # full capabilities for both cases
                    if ($WorkbookId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics','ChangeHierarchy','Delete','ChangePermissions'
                    } elseif ($ViewId) {
                        $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','Delete','ChangePermissions'
                    } elseif ($DatasourceId) {
                        $capabilities = 'Read','Connect','ExportXml','Write','SaveAs','ChangeHierarchy','Delete','ChangePermissions'
                    } elseif ($FlowId) {
                        $capabilities = 'Read','ExportXml','Execute','Write','WebAuthoringForFlows','ChangeHierarchy','Delete','ChangePermissions'
                    } elseif ($ProjectId) {
                        $capabilities = 'Read','Write'
                    }
                }
                default { # incl. None
                    $capabilities = @()
                }
            }
            $permissionsCount += $capabilities.Length
            $currentPermissionTable | Where-Object -FilterScript {($_.granteeType -eq $permission.granteeType) -and ($_.granteeId -eq $permission.granteeId)} | ForEach-Object {
                $currentCapabilities = $_.capabilities
                $currentCapabilities.GetEnumerator() | ForEach-Object {
                    $capabilityName = $_.Key
                    $capabilityMode = $_.Value
                    if ((-not ($capabilities -Contains $capabilityName)) -or (($permission.template -ne 'Denied' -and $capabilityMode -ne 'Allow') -or ($permission.template -eq 'Denied' -and $capabilityMode -ne 'Deny'))) {
                        $permissionOverrides += @{granteeType=$permission.granteeType; granteeId=$permission.granteeId; capabilityName=$capabilityName; capabilityMode=$capabilityMode}
                    }
                }
            }
            $capabilitiesHashtable = @{}
            foreach ($cap in $capabilities) {
                if ($permission.template -eq 'Denied') {
                    $mode = "Deny"
                } else {
                    $mode = "Allow"
                }
                $capabilitiesHashtable.Add($cap, $mode)
            }
            $addPermissionTable += @{granteeType=$permission.granteeType; granteeId=$permission.granteeId; capabilities=$capabilitiesHashtable}
        }
    }
    $shouldProcessItem += ", grantees:{0}, permissions:{1}, overrides:{2}" -f $PermissionTable.Length, $permissionsCount, $permissionOverrides.Length
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $permissionOverrides | ForEach-Object { # remove all existing incompatible permissions (or that are not included in the permission template)
            Remove-TSContentPermission @MainParam -GranteeType $_.granteeType -GranteeId $_.granteeId -CapabilityName $_.capabilityName -CapabilityMode $_.capabilityMode
        }
        Add-TSContentPermission @MainParam -PermissionTable $addPermissionTable
    }
}

function Remove-TSContentPermission {
<#
.SYNOPSIS
Delete Workbook / Data Source / View / Project / Flow Permission

.DESCRIPTION
Deletes the specified permission (or all permissions) from the specified content for a specific grantee or all grantees.

.PARAMETER WorkbookId
The LUID of the workbook to set permissions for.

.PARAMETER DatasourceId
The LUID of the data source to set permissions for.

.PARAMETER ViewId
The LUID of the view to set permissions for.

.PARAMETER ProjectId
The LUID of the project to set permissions for.

.PARAMETER FlowId
The LUID of the flow to set permissions for.

.PARAMETER GranteeType
Delete permission(s) for specific grantee: the grantee type (User or Group).

.PARAMETER GranteeId
Delete permission(s) for specific grantee: the LUID of the user or group.

.PARAMETER CapabilityName
Delete permission(s) for specific grantee: the name of the capability to remove.
If this parameter is not provided, all existing permissions for the grantee will be deleted.

.PARAMETER CapabilityMode
Delete permission(s) for specific grantee: the mode of the capability to remove (Allow or Deny).
If this parameter is not provided, all existing permissions for the grantee will be deleted.

.PARAMETER All
Explicit boolean switch, supply this to delete ALL permissions for ALL grantees.

.EXAMPLE
Remove-TSContentPermission -WorkbookId $sampleWorkbookId -All

.EXAMPLE
Remove-TSContentPermission -DatasourceId $datasource.id -GranteeType User -GranteeId (Get-TSCurrentUserId)

.EXAMPLE
Remove-TSContentPermission -FlowId $flow.id -GranteeType User -GranteeId (Get-TSCurrentUserId) -CapabilityName Execute -CapabilityMode Allow

.NOTES
This function always returns $null.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_workbook_permission

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_data_source_permission

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_view_permission

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_project_permission

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow_permission
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType()]
Param(
    [Parameter(Mandatory,ParameterSetName='WorkbookAll')]
    [Parameter(Mandatory,ParameterSetName='WorkbookAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='WorkbookOne')]
    [string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='DatasourceAll')]
    [Parameter(Mandatory,ParameterSetName='DatasourceAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='DatasourceOne')]
    [string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='ViewAll')]
    [Parameter(Mandatory,ParameterSetName='ViewAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ViewOne')]
    [string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='ProjectAll')]
    [Parameter(Mandatory,ParameterSetName='ProjectAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ProjectOne')]
    [string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='FlowAll')]
    [Parameter(Mandatory,ParameterSetName='FlowAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='FlowOne')]
    [string] $FlowId,
    [Parameter(Mandatory,ParameterSetName='WorkbookAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='WorkbookOne')]
    [Parameter(Mandatory,ParameterSetName='DatasourceAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='DatasourceOne')]
    [Parameter(Mandatory,ParameterSetName='ViewAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ViewOne')]
    [Parameter(Mandatory,ParameterSetName='ProjectAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ProjectOne')]
    [Parameter(Mandatory,ParameterSetName='FlowAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='FlowOne')]
    [ValidateSet('User','Group')][string] $GranteeType,
    [Parameter(Mandatory,ParameterSetName='WorkbookAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='WorkbookOne')]
    [Parameter(Mandatory,ParameterSetName='DatasourceAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='DatasourceOne')]
    [Parameter(Mandatory,ParameterSetName='ViewAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ViewOne')]
    [Parameter(Mandatory,ParameterSetName='ProjectAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='ProjectOne')]
    [Parameter(Mandatory,ParameterSetName='FlowAllGrantee')]
    [Parameter(Mandatory,ParameterSetName='FlowOne')]
    [string] $GranteeId,
    [Parameter(Mandatory,ParameterSetName='WorkbookOne')]
    [Parameter(Mandatory,ParameterSetName='DatasourceOne')]
    [Parameter(Mandatory,ParameterSetName='ViewOne')]
    [Parameter(Mandatory,ParameterSetName='ProjectOne')]
    [Parameter(Mandatory,ParameterSetName='FlowOne')]
    [ValidateSet('AddComment','ChangeHierarchy','ChangePermissions','Connect','Delete','Execute','WebAuthoringForFlows',
        'ExportData','ExportImage','ExportXml','Filter','ProjectLeader','Read','ShareView','ViewComments','ViewUnderlyingData',
        'WebAuthoring','Write','RunExplainData','CreateRefreshMetrics','SaveAs')][string] $CapabilityName,
    [Parameter(Mandatory,ParameterSetName='WorkbookOne')]
    [Parameter(Mandatory,ParameterSetName='DatasourceOne')]
    [Parameter(Mandatory,ParameterSetName='ViewOne')]
    [Parameter(Mandatory,ParameterSetName='ProjectOne')]
    [Parameter(Mandatory,ParameterSetName='FlowOne')]
    [ValidateSet('Allow','Deny')][string] $CapabilityMode,
    [Parameter(Mandatory,ParameterSetName='WorkbookAll')]
    [Parameter(Mandatory,ParameterSetName='DatasourceAll')]
    [Parameter(Mandatory,ParameterSetName='ViewAll')]
    [Parameter(Mandatory,ParameterSetName='ProjectAll')]
    [Parameter(Mandatory,ParameterSetName='FlowAll')]
    [switch] $All
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $MainParam = @{}
    if ($WorkbookId) {
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        $shouldProcessItem = "workbook:$WorkbookId"
        $MainParam.Add("WorkbookId", $WorkbookId)
    } elseif ($DatasourceId) {
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        $shouldProcessItem = "datasource:$DatasourceId"
        $MainParam.Add("DatasourceId", $DatasourceId)
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
        $shouldProcessItem = "view:$ViewId"
        $MainParam.Add("ViewId", $ViewId)
    } elseif ($ProjectId) {
        $uri = Get-TSRequestUri -Endpoint Project -Param $ProjectId
        $shouldProcessItem = "project:$ProjectId"
        $MainParam.Add("ProjectId", $ProjectId)
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId
        $shouldProcessItem = "flow:$FlowId"
        $MainParam.Add("FlowId", $FlowId)
    }
    $uri += "/permissions/"
    if ($CapabilityName -and $CapabilityMode) { # Remove one permission/capability
        $shouldProcessItem += ", {0}:{1}, {2}:{3}" -f $GranteeType, $GranteeId, $CapabilityName, $CapabilityMode
        $uriAdd = "{0}s/{1}/{2}/{3}" -f $GranteeType.ToLower(), $GranteeId, $CapabilityName, $CapabilityMode
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
        }
    } elseif ($GranteeType -and $GranteeId) { # Remove all permissions for one grantee
        $shouldProcessItem += ", all permissions for {0}:{1}" -f $GranteeType, $GranteeId
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $permissions = Get-TSContentPermission @MainParam
            if ($permissions.granteeCapabilities) {
                $permissions.granteeCapabilities | ForEach-Object {
                    if (($GranteeType -eq 'Group' -and $_.group -and $_.group.id -eq $GranteeId) -or ($GranteeType -eq 'User' -and $_.user -and $_.user.id -eq $GranteeId)) {
                        $_.capabilities.capability | ForEach-Object {
                            $uriAdd = "{0}s/{1}/{2}/{3}" -f $GranteeType.ToLower(), $GranteeId, $_.name, $_.mode
                            $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
                        }
                    }
                }
            }
        }
    } elseif ($All) { # Remove all permissions for all grantees
        $shouldProcessItem += ", ALL PERMISSIONS"
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $permissions = Get-TSContentPermission @MainParam
            if ($permissions.granteeCapabilities) {
                $permissions.granteeCapabilities | ForEach-Object {
                    if ($_.group) {
                        $grtType = 'group'
                        $grtId = $_.group.id
                    } elseif ($_.user) {
                        $grtType = 'user'
                        $grtId = $_.user.id
                    }
                    $_.capabilities.capability | ForEach-Object {
                        $uriAdd = "{0}s/{1}/{2}/{3}" -f $grtType, $grtId, $_.name, $_.mode
                        $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
                    }
                }
            }
        }
    }
}

function ConvertTo-TSPermissionTable {
<#
.SYNOPSIS
Convert permissions response into "PermissionTable"

.DESCRIPTION
Converts the response of permission methods into the list-hashtable which can be used as input (PermissionTable) for:
- Add-TSContentPermission
- Set-TSContentPermission

.PARAMETER Permissions
XmlElement with the input raw data.

.EXAMPLE
$currentPermissionTable = Get-TSContentPermission -WorkbookId $sampleWorkbookId | ConvertTo-TSPermissionTable

.NOTES
The following functions can be used as input for ConvertTo-TSPermissionTable:
- Get-TSContentPermission
- Add-TSContentPermission
- Set-TSContentPermission
#>
[OutputType([hashtable[]])]
Param(
    [Parameter(Mandatory,Position=0,ValueFromPipeline)][System.Xml.XmlElement] $Permissions
)
    begin {
        $permissionTable = @()
    }
    process {
        if ($Permissions.granteeCapabilities) {
            $Permissions.granteeCapabilities | ForEach-Object {
                if ($_.group -and $_.group.id) {
                    $granteeType = 'group'
                    $granteeId = $_.group.id
                } elseif ($_.user -and $_.user.id) {
                    $granteeType = 'user'
                    $granteeId = $_.user.id
                } else {
                    Write-Error "Invalid grantee in the input object" -Category InvalidData -ErrorAction Continue
                }
                $capabilitiesHashtable = @{}
                $_.capabilities.capability | ForEach-Object {
                    if ($_.name -and $_.mode) {
                        $capabilitiesHashtable.Add($_.name, $_.mode)
                    } else {
                        Write-Error "Invalid permission capability in the input object" -Category InvalidData -ErrorAction Continue
                    }
                }
                $permissionTable += @{granteeType=$granteeType; granteeId=$granteeId; capabilities=$capabilitiesHashtable}
            }
        }
    }
    end {
        return $permissionTable
    }
}

function Get-TSDefaultPermission {
<#
.SYNOPSIS
Query Default Permissions

.DESCRIPTION
Returns details of default permission rules granted to users and groups for
workbooks, data sources, flows, data roles, lenses, metrics, databases or tables resources in a specific project.
Return object is a list of hashtables (similar to the output of ConvertTo-TSPermissionTable)

.PARAMETER ProjectId
The LUID of the project to get default permissions for.

.PARAMETER ContentType
Specific content type to query default permission for.
If omitted, the default permissions for all supported content types are returned.

.EXAMPLE
$defProjectPermissions = Get-TSDefaultPermission -ProjectId $project.id
$wbPermissionTable = Get-TSDefaultPermission -ProjectId $project.id -ContentType workbooks

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_default_permissions
#>
[OutputType([hashtable[]])]
Param(
    [Parameter(Mandatory)][string] $ProjectId,
    [Parameter()][ValidateSet('Workbooks','Datasources','Flows','Dataroles','Lenses','Metrics','Databases','Tables')][string] $ContentType
)
    # Assert-TSRestApiVersion -AtLeast 2.1
    $permissionTable = @()
    $uri = Get-TSRequestUri -Endpoint Project -Param "$ProjectId/default-permissions/"
    foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') { #,'virtualconnections' not supported yet
        if ($ct -eq 'dataroles' -and (Get-TSRestApiVersion) -lt [version]3.13) {
            continue
        } elseif ($ct -eq 'lenses' -and ((Get-TSRestApiVersion) -lt [version]3.13 -or (Get-TSRestApiVersion) -ge [version]3.22)) {
            continue
        } elseif ($ct -in 'databases','tables' -and (Get-TSRestApiVersion) -lt [version]3.6) {
            continue
        }
        if ((-Not ($ContentType)) -or $ContentType -eq $ct) {
            $response = Invoke-TSRestApiMethod -Uri $uri$ct -Method Get
            if ($response.tsResponse.permissions.granteeCapabilities) {
                $response.tsResponse.permissions.granteeCapabilities | ForEach-Object {
                    if ($_.group -and $_.group.id) {
                        $granteeType = 'group'
                        $granteeId = $_.group.id
                    } elseif ($_.user -and $_.user.id) {
                        $granteeType = 'user'
                        $granteeId = $_.user.id
                    } else {
                        Write-Error "Invalid grantee in the response object" -Category InvalidData -ErrorAction Continue
                    }
                    $capabilitiesHashtable = @{}
                    $_.capabilities.capability | ForEach-Object {
                        if ($_.name -and $_.mode) {
                            $capabilitiesHashtable.Add($_.name, $_.mode)
                        } else {
                            Write-Error "Invalid permission capability in the input object" -Category InvalidData -ErrorAction Continue
                        }
                    }
                    $permissionTable += @{contentType=$ct; granteeType=$granteeType; granteeId=$granteeId; capabilities=$capabilitiesHashtable}
                }
            }
        }
    }
    return $permissionTable
}

function Set-TSDefaultPermission {
<#
.SYNOPSIS
Set (add) Default Permission(s)

.DESCRIPTION
Sets the default permission rules granted to users and groups for
workbooks, data sources, flows, data roles, lenses, metrics, databases or tables resources in a specific project.

.PARAMETER ProjectId
The LUID of the project to set default permissions for.

.PARAMETER PermissionTable
A list of permissions (hashtable), each item must be structured as follows:
- contentType: the specific content type to set the default permission for, e.g. 'workbooks' or 'datasources'
- granteeType: 'user' or 'group'
- granteeId: the LUID of the user or group
- capabilities: hashtable with all permissions to add, the key is capability name and the value is allow or deny
Note: existing capabilities are removed for the same capability names, but other capabilities are untouched.
- template: can be used instead of 'capabilities'. This corresponds to selecting "Template" in Tableau Server UI.
The following templates are supported: View, Explore, Publish, Administer, Denied, None
Note: existing capabilities are removed for the grantee, if template is used.

.EXAMPLE
$dpt = @{contentType="workbooks"; granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow"}}
$dpt += @{contentType="datasources"; granteeType="User"; granteeId=(Get-TSCurrentUserId); capabilities=@{Read="Allow";Connect="Allow"}}
$permissions = Set-TSDefaultPermission -ProjectId $testProjectId -PermissionTable $dpt

.NOTES
The PermissionTable parameter has similar structure as for Set-TSContentPermission, but has in addition to provide 'contentType' keys.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#add_default_permissions
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([System.Object[]])]
Param(
    [Parameter(Mandatory)][string] $ProjectId,
    [Parameter(Mandatory)][hashtable[]] $PermissionTable
)
    $uri = Get-TSRequestUri -Endpoint Project -Param "$ProjectId/default-permissions/"
    $outputPermissionTable = @()
    foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
        if ($ct -eq 'dataroles' -and (Get-TSRestApiVersion) -lt [version]3.13) {
            continue
        } elseif ($ct -eq 'lenses' -and ((Get-TSRestApiVersion) -lt [version]3.13 -or (Get-TSRestApiVersion) -ge [version]3.22)) {
            continue
        } elseif ($ct -in 'databases','tables' -and (Get-TSRestApiVersion) -lt [version]3.6) {
            continue
        }
        $shouldProcessItem = "project:$ProjectId"
        $contentTypePermissions = $PermissionTable | Where-Object contentType -eq $ct
        $currentPermissionTable = Get-TSDefaultPermission -ProjectId $ProjectId -ContentType $ct
        if ($contentTypePermissions.Length -gt 0) {
            $xml = New-Object System.Xml.XmlDocument
            $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
            $el_pm = $tsRequest.AppendChild($xml.CreateElement("permissions"))
            $permissionsCount = 0
            $permissionOverrides = @()
            foreach ($permission in $contentTypePermissions) {
                if ($permission.capabilities -and $permission.capabilities.Count -gt 0) {
                    $permissionsCount += $permission.capabilities.Count
                    $el_gc = $el_pm.AppendChild($xml.CreateElement("granteeCapabilities"))
                    $el_gc.AppendChild($xml.CreateElement($permission.granteeType.ToLower())).SetAttribute("id", $permission.granteeId)
                    $el_caps = $el_gc.AppendChild($xml.CreateElement("capabilities"))
                    $permission.capabilities.GetEnumerator() | ForEach-Object {
                        $el_cap = $el_caps.AppendChild($xml.CreateElement("capability"))
                        $el_cap.SetAttribute("name", $_.Key)
                        $el_cap.SetAttribute("mode", $_.Value)
                    }
                } elseif ($permission.template) { # support for permission templates
                    switch ($permission.template) {
                        'View' {
                            switch ($ct) {
                                'workbooks' {
                                    $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData'
                                }
                                'datasources' {
                                    $capabilities = 'Read','Connect'
                                }
                                {$_ -in 'flows','dataroles','metrics','lenses','databases','tables'} {
                                    $capabilities = 'Read'
                                }
                            }
                        }
                        'Explore' {
                            switch ($ct) {
                                'workbooks' {
                                    $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData'
                                }
                                'datasources' {
                                    $capabilities = 'Read','Connect','ExportXml'
                                }
                                'flows' {
                                    $capabilities = 'Read','ExportXml'
                                }
                                {$_ -in 'dataroles','metrics','lenses','databases','tables'} {
                                    $capabilities = 'Read'
                                }
                            }
                        }
                        'Publish' {
                            switch ($ct) {
                                'workbooks' {
                                    $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics'
                                }
                                'datasources' {
                                    $capabilities = 'Read','Connect','ExportXml','Write','SaveAs'
                                }
                                'flows' {
                                    $capabilities = 'Read','ExportXml','Execute','Write','WebAuthoringForFlows'
                                }
                                {$_ -in 'dataroles','metrics','lenses','databases','tables'} {
                                    $capabilities = 'Read','Write'
                                }
                            }
                        }
                        {$_ -in 'Administer','Denied'} { # full capabilities for both cases
                            switch ($ct) {
                                'workbooks' {
                                    $capabilities = 'Read','Filter','ViewComments','AddComment','ExportImage','ExportData','ShareView','ViewUnderlyingData','WebAuthoring','RunExplainData','ExportXml','Write','CreateRefreshMetrics','ChangeHierarchy','Delete','ChangePermissions'
                                }
                                'datasources' {
                                    $capabilities = 'Read','Connect','ExportXml','Write','SaveAs','ChangeHierarchy','Delete','ChangePermissions'
                                }
                                'flows' {
                                    $capabilities = 'Read','ExportXml','Execute','Write','WebAuthoringForFlows','ChangeHierarchy','Delete','ChangePermissions'
                                }
                                {$_ -in 'dataroles','metrics','lenses'} {
                                    $capabilities = 'Read','Write','ChangeHierarchy','Delete','ChangePermissions'
                                }
                                {$_ -in 'databases','tables'} {
                                    $capabilities = 'Read','Write','ChangeHierarchy','ChangePermissions'
                                }
                            }
                        }
                        default { # incl. None
                            $capabilities = @()
                        }
                    }
                    $permissionsCount += $capabilities.Length
                    $currentPermissionTable | Where-Object -FilterScript {($_.granteeType -eq $permission.granteeType) -and ($_.granteeId -eq $permission.granteeId)} | ForEach-Object {
                        $currentCapabilities = $_.capabilities
                        $currentCapabilities.GetEnumerator() | ForEach-Object {
                            $capabilityName = $_.Key
                            $capabilityMode = $_.Value
                            if ((-not ($capabilities -Contains $capabilityName)) -or (($permission.template -ne 'Denied' -and $capabilityMode -ne 'Allow') -or ($permission.template -eq 'Denied' -and $capabilityMode -ne 'Deny'))) {
                                $permissionOverrides += @{granteeType=$permission.granteeType; granteeId=$permission.granteeId; capabilityName=$capabilityName; capabilityMode=$capabilityMode}
                            }
                        }
                    }
                    if ($capabilities.Length -gt 0) { # only for non-empty capabilities (template=None doesn't add permissions)
                        $el_gc = $el_pm.AppendChild($xml.CreateElement("granteeCapabilities"))
                        $el_gc.AppendChild($xml.CreateElement($permission.granteeType.ToLower())).SetAttribute("id", $permission.granteeId)
                        $el_caps = $el_gc.AppendChild($xml.CreateElement("capabilities"))
                        foreach ($cap in $capabilities) {
                            $el_cap = $el_caps.AppendChild($xml.CreateElement("capability"))
                            if ($permission.template -eq 'Denied') {
                                $mode = "Deny"
                            } else {
                                $mode = "Allow"
                            }
                            $el_cap.SetAttribute("name", $cap)
                            $el_cap.SetAttribute("mode", $mode)
                        }
                    }
                }
            }
            $shouldProcessItem += ", {0}, grantees:{1}, permissions:{2}, overrides:{3}" -f $ct, $contentTypePermissions.Length, $permissionsCount, $permissionOverrides.Length
            if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
                $permissionOverrides | ForEach-Object { # remove all existing incompatible permissions (or that are not included in the permission template)
                    # note: it's also possible to remove all permissions for one grantee, one content type first, using the following method
                    Remove-TSDefaultPermission -ProjectId $ProjectId -ContentType $ct -GranteeType $_.granteeType -GranteeId $_.granteeId -CapabilityName $_.capabilityName -CapabilityMode $_.capabilityMode
                }
                if ($permissionsCount -gt 0) { # empty permissions element in xml is not allowed
                    $response = Invoke-TSRestApiMethod -Uri $uri$ct -Body $xml.OuterXml -Method Put
                    if ($response.tsResponse.permissions.granteeCapabilities) {
                        $response.tsResponse.permissions.granteeCapabilities | ForEach-Object {
                            if ($_.group -and $_.group.id) {
                                $granteeType = 'group'
                                $granteeId = $_.group.id
                            } elseif ($_.user -and $_.user.id) {
                                $granteeType = 'user'
                                $granteeId = $_.user.id
                            } else {
                                Write-Error "Invalid grantee in the response object" -Category InvalidData -ErrorAction Continue
                            }
                            $capabilitiesHashtable = @{}
                            $_.capabilities.capability | ForEach-Object {
                                if ($_.name -and $_.mode) {
                                    $capabilitiesHashtable.Add($_.name, $_.mode)
                                } else {
                                    Write-Error "Invalid permission capability in the input object" -Category InvalidData -ErrorAction Continue
                                }
                            }
                            $outputPermissionTable += @{contentType=$ct; granteeType=$granteeType; granteeId=$granteeId; capabilities=$capabilitiesHashtable}
                        }
                    }
                }
            }
        }
    }
    return $outputPermissionTable
}

function Remove-TSDefaultPermission {
<#
.SYNOPSIS
Delete Default Permission(s)

.DESCRIPTION
Removes the specific default permission rules granted to users and groups for
workbooks, data sources, flows, data roles, lenses, metrics, databases or tables resources in a specific project.

.PARAMETER ProjectId
The LUID of the project to delete default permissions for.

.PARAMETER GranteeType
Delete default permission(s) for specific grantee: the grantee type (User or Group).

.PARAMETER GranteeId
Delete default permission(s) for specific grantee: the LUID of the user or group.

.PARAMETER CapabilityName
Delete default permission(s) for specific grantee: the name of the capability to remove.
If this parameter is not provided, all existing permissions for the grantee will be deleted.

.PARAMETER CapabilityMode
Delete default permission(s) for specific grantee: the mode of the capability to remove (Allow or Deny).
If this parameter is not provided, all existing permissions for the grantee will be deleted.

.PARAMETER ContentType
Specific content type to delete default permission(s) for.
If omitted, default permissions for all content types are deleted (for specific grantees or all grantees).

.PARAMETER All
Explicit boolean switch, supply this to delete ALL permissions for ALL grantees and ALL content types.

.EXAMPLE
Remove-TSDefaultPermission -ProjectId $projectId -GranteeType User -GranteeId (Get-TSCurrentUserId)

.EXAMPLE
Remove-TSDefaultPermission -ProjectId $projectId -GranteeType Group -GranteeId $groupId -ContentType workbooks

.EXAMPLE
Remove-TSDefaultPermission -ProjectId $project.id -All

.NOTES
This function always returns $null.

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_default_permission
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType()]
Param(
    [Parameter(Mandatory)][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='OneGrantee')]
    [Parameter(Mandatory,ParameterSetName='OneGranteeForContentType')]
    [Parameter(Mandatory,ParameterSetName='OneCapability')]
    [ValidateSet('User','Group')][string] $GranteeType,
    [Parameter(Mandatory,ParameterSetName='OneGrantee')]
    [Parameter(Mandatory,ParameterSetName='OneGranteeForContentType')]
    [Parameter(Mandatory,ParameterSetName='OneCapability')]
    [string] $GranteeId,
    [Parameter(Mandatory,ParameterSetName='OneCapability')]
    [ValidateSet('AddComment','ChangeHierarchy','ChangePermissions','Connect','Delete','Execute','WebAuthoringForFlows',
        'ExportData','ExportImage','ExportXml','Filter','ProjectLeader','Read','ShareView','ViewComments','ViewUnderlyingData',
        'WebAuthoring','Write','RunExplainData','CreateRefreshMetrics','SaveAs')][string] $CapabilityName,
    [Parameter(Mandatory,ParameterSetName='OneCapability')]
    [ValidateSet('Allow','Deny')][string] $CapabilityMode,
    [Parameter(Mandatory,ParameterSetName='OneGranteeForContentType')]
    [Parameter(Mandatory,ParameterSetName='OneCapability')]
    [ValidateSet('Workbooks','Datasources','Flows','Dataroles','Lenses','Metrics','Databases','Tables')][string] $ContentType,
    [Parameter(Mandatory,ParameterSetName='AllPermissions')]
    [switch] $All
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $uri = Get-TSRequestUri -Endpoint Project -Param "$ProjectId/default-permissions/"
    $shouldProcessItem = "project:$ProjectId"
    if ($CapabilityName -and $CapabilityMode) { # Remove one default permission/capability
        $shouldProcessItem += ", default permission for {0}:{1}, {2}:{3}" -f $GranteeType, $GranteeId, $CapabilityName, $CapabilityMode
        $uriAdd = "{0}/{1}s/{2}/{3}/{4}" -f $ContentType, $GranteeType.ToLower(), $GranteeId, $CapabilityName, $CapabilityMode
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
        }
    } elseif ($GranteeType -and $GranteeId) { # Remove all permissions for one grantee
        $shouldProcessItem += ", all default permissions for {0}:{1}" -f $GranteeTyp, $GranteeId
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $allDefaultPermissions = Get-TSDefaultPermission -ProjectId $ProjectId
            foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                if ($ct -eq 'dataroles' -and (Get-TSRestApiVersion) -lt [version]3.13) {
                    continue
                } elseif ($ct -eq 'lenses' -and ((Get-TSRestApiVersion) -lt [version]3.13 -or (Get-TSRestApiVersion) -ge [version]3.22)) {
                    continue
                } elseif ($ct -in 'databases','tables' -and (Get-TSRestApiVersion) -lt [version]3.6) {
                    continue
                }
                if ((-Not ($ContentType)) -or $ContentType -eq $ct) {
                    $permissions = $allDefaultPermissions | Where-Object -FilterScript {
                        ($_.contentType -eq $ct) -and
                        ($_.granteeType -eq $GranteeType) -and
                        ($_.granteeId -eq $GranteeId)}
                    if ($permissions.Length -gt 0) {
                        foreach ($permission in $permissions) {
                            $permission.capabilities.GetEnumerator() | ForEach-Object {
                                $uriAdd = "{0}/{1}s/{2}/{3}/{4}" -f $ct, $GranteeType.ToLower(), $GranteeId, $_.Key, $_.Value
                                $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
                            }
                        }
                    }
                }
            }
        }
    } elseif ($All) {
        $shouldProcessItem += ", ALL DEFAULT PERMISSIONS"
        if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
            $allDefaultPermissions = Get-TSDefaultPermission -ProjectId $ProjectId
            foreach ($ct in 'workbooks','datasources','flows','dataroles','lenses','metrics','databases','tables') {
                if ($ct -eq 'dataroles' -and (Get-TSRestApiVersion) -lt [version]3.13) {
                    continue
                } elseif ($ct -eq 'lenses' -and ((Get-TSRestApiVersion) -lt [version]3.13 -or (Get-TSRestApiVersion) -ge [version]3.22)) {
                    continue
                } elseif ($ct -in 'databases','tables' -and (Get-TSRestApiVersion) -lt [version]3.6) {
                    continue
                }
                $contentTypePermissions = $allDefaultPermissions | Where-Object contentType -eq $ct
                if ($contentTypePermissions.Length -gt 0) {
                    foreach ($permission in $contentTypePermissions) {
                        $permission.capabilities.GetEnumerator() | ForEach-Object {
                            $uriAdd = "{0}/{1}s/{2}/{3}/{4}" -f $ct, $permission.granteeType.ToLower(), $permission.granteeId, $_.Key, $_.Value
                            $null = Invoke-TSRestApiMethod -Uri $uri$uriAdd -Method Delete
                        }
                    }
                }
            }
        }
    }
}

### Tags methods
function Add-TSTagsToContent {
<#
.SYNOPSIS
Add Tags to Workbook / Data Source / View / Flow

.DESCRIPTION
Adds one or more tags to the specified content.

.PARAMETER WorkbookId
The LUID of the workbook to add tags to.

.PARAMETER DatasourceId
The LUID of the data source to add tags to.

.PARAMETER ViewId
The LUID of the view to add tags to.

.PARAMETER FlowId
The LUID of the flow to add tags to.

.PARAMETER Tags
List of tags as strings.

.EXAMPLE
Add-TSTagsToContent -WorkbookId $sampleWorkbookId -Tags "active","test"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#add_tags_to_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#add_tags_to_data_source

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#add_tags_to_view
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId,
    [Parameter(Mandatory)][string[]] $Tags
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_tags = $tsRequest.AppendChild($xml.CreateElement("tags"))
    foreach ($tag in $Tags) {
        $el_tag = $el_tags.AppendChild($xml.CreateElement("tag"))
        $el_tag.SetAttribute("label", $tag)
    }
    if ($WorkbookId -and $PSCmdlet.ShouldProcess("workbook:$WorkbookId, tags:"+($Tags -join ' '))) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/tags) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.tags.tag
    } elseif ($DatasourceId -and $PSCmdlet.ShouldProcess("datasource:$DatasourceId, tags:"+($Tags -join ' '))) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/tags) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.tags.tag
    } elseif ($ViewId -and $PSCmdlet.ShouldProcess("view:$ViewId, tags:"+($Tags -join ' '))) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId/tags) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.tags.tag
    } elseif ($FlowId -and $PSCmdlet.ShouldProcess("flow:$FlowId, tags:"+($Tags -join ' '))) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/tags) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.tags.tag
    }
}

function Remove-TSTagFromContent {
<#
.SYNOPSIS
Delete Tag from Workbook / Data Source / View / Flow

.DESCRIPTION
Deletes a tag from the specified content.

.PARAMETER WorkbookId
The ID of the workbook to remove the tag from.

.PARAMETER DatasourceId
The ID of the data source to remove the tag from.

.PARAMETER ViewId
The ID of the view to remove the tag from.

.PARAMETER FlowId
The ID of the flow to remove the tag from.

.PARAMETER Tag
The name of the tag to remove from the content.

.EXAMPLE
Remove-TSTagFromContent -WorkbookId $sampleWorkbookId -Tag "test"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_tag_from_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#delete_tag_from_data_source

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_tag_from_view
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId,
    [Parameter(Mandatory)][string] $Tag
)
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($WorkbookId -and $PSCmdlet.ShouldProcess("workbook:$WorkbookId, tag:$Tag")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/tags/$Tag) -Method Delete
    } elseif ($DatasourceId -and $PSCmdlet.ShouldProcess("datasource:$DatasourceId, tag:$Tag")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/tags/$Tag) -Method Delete
    } elseif ($ViewId -and $PSCmdlet.ShouldProcess("view:$ViewId, tag:$Tag")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId/tags/$Tag) -Method Delete
    } elseif ($FlowId -and $PSCmdlet.ShouldProcess("flow:$FlowId, tag:$Tag")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/tags/$Tag) -Method Delete
    }
}

### Jobs, Tasks and Schedules methods
function Get-TSSchedule {
<#
.SYNOPSIS
Get Server Schedule / List Server Schedules

.DESCRIPTION
Returns detailed information about the specified server schedule, or list of schedules on Tableau Server.
Not available for Tableau Cloud.

.PARAMETER ScheduleId
(Get Server Schedule by Id) The LUID of the specific schedule.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$schedules = Get-TSSchedule

.EXAMPLE
$schedule = Get-TSSchedule -ScheduleId $testScheduleId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get-schedule

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_schedules
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='ScheduleById')][string] $ScheduleId,
    [Parameter(ParameterSetName='Schedules')][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    if ($ScheduleId) { # Get Server Schedule
        Assert-TSRestApiVersion -AtLeast 3.8
    }
    if ($ScheduleId) { # Get Server Schedule
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint ServerSchedule -Param $ScheduleId) -Method Get
        $response.tsResponse.schedule
    } else { # List Server Schedules
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint ServerSchedule
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.schedules.schedule
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Add-TSSchedule {
<#
.SYNOPSIS
Create Server Schedule

.DESCRIPTION
Creates a new server schedule on Tableau Server.
This method can be called only by Server Admins.

.PARAMETER Name
The name to give to the schedule.

.PARAMETER Type
The schedule typy, which is one of the following: Extract, Subscription, Flow, DataAcceleration.

.PARAMETER Priority
An integer value between 1 and 100 that determines the default priority of the schedule if multiple tasks are pending in the queue.
Default is 50.

.PARAMETER ExecutionOrder
Parallel to allow jobs associated with this schedule to run at the same time, or Serial to require the jobs to run one after the other.
Default is Parallel.

.PARAMETER Frequency
The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.

.PARAMETER StartTime
The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs.

.PARAMETER IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs. Valid values are 15 or 30.

.PARAMETER IntervalWeekdays
(Optional) For Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthday
(Optional) For Monthly: the day of the month when the schedule is run. For last month day, the value 0 should be supplied.

.EXAMPLE
$schedule = Add-TSSchedule -Name "Monthly on 3rd day of the month" -Type Extract -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#create_schedule
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][ValidateSet('Extract','Subscription','Flow','DataAcceleration')][string] $Type,
    [Parameter()][ValidateRange(1,100)][int] $Priority = 50,
    [Parameter()][ValidateSet('Parallel','Serial')][string] $ExecutionOrder = 'Parallel',
    [Parameter(Mandatory,ParameterSetName='HourlyHours')]
    [Parameter(Mandatory,ParameterSetName='HourlyMinutes')]
    [Parameter(Mandatory,ParameterSetName='Daily')]
    [Parameter(Mandatory,ParameterSetName='Weekly')]
    [Parameter(Mandatory,ParameterSetName='Monthly')]
    [ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency = 'Daily',
    [Parameter(Mandatory,ParameterSetName='HourlyHours')]
    [Parameter(Mandatory,ParameterSetName='HourlyMinutes')]
    [Parameter(Mandatory,ParameterSetName='Daily')]
    [Parameter(Mandatory,ParameterSetName='Weekly')]
    [Parameter(Mandatory,ParameterSetName='Monthly')]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime = '00:00:00',
    [Parameter(ParameterSetName='HourlyHours')]
    [Parameter(ParameterSetName='HourlyMinutes')]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter(Mandatory,ParameterSetName='HourlyHours')][ValidateSet(1,2,4,6,8,12)][int] $IntervalHours,
    [Parameter(Mandatory,ParameterSetName='HourlyMinutes')][ValidateSet(15,30)][int] $IntervalMinutes,
    [Parameter(Mandatory,ParameterSetName='Weekly')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter(Mandatory,ParameterSetName='Monthly')][ValidateRange(0,31)][int] $IntervalMonthday
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    if ($Type -eq 'DataAcceleration') {
        Assert-TSRestApiVersion -AtLeast 3.8 -LessThan 3.16
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
    $el_sched.SetAttribute("name", $Name)
    $el_sched.SetAttribute("type", $Type)
    $el_sched.SetAttribute("priority", $Priority)
    $el_sched.SetAttribute("executionOrder", $ExecutionOrder)
    $el_sched.SetAttribute("frequency", $Frequency)
    $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
    $el_freq.SetAttribute("start", $StartTime)
    if ($EndTime) {
        $el_freq.SetAttribute("end", $EndTime)
    }
    switch ($Frequency) {
        'Hourly' {
            $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
            $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
            if ($IntervalHours) {
                $el_int.SetAttribute("hours", $IntervalHours)
            } elseif ($IntervalMinutes) {
                $el_int.SetAttribute("minutes", $IntervalMinutes)
            }
        }
        'Weekly' {
            if ($IntervalWeekdays) {
                $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
                foreach ($weekday in $IntervalWeekdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                }
            }
        }
        'Monthly' {
            if ($IntervalMonthday -ge 0) {
                $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
                $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                if ($IntervalMonthday -eq 0) {
                    $el_int.SetAttribute("monthDay", "LastDay")
                } else {
                    $el_int.SetAttribute("monthDay", $IntervalMonthday)
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint ServerSchedule) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.schedule
    }
}

function Update-TSSchedule {
<#
.SYNOPSIS
Update Server Schedule

.DESCRIPTION
Modifies settings for the specified server schedule, including the name, priority, and frequency details on Tableau Server.
This method can only be called by Server Admins.

.PARAMETER ScheduleId
The LUID of the schedule to update.

.PARAMETER Name
(Optional) The new name to give to the schedule.

.PARAMETER State
(Optional) 'Active' to enable the schedule, or 'Suspended' to disable it.

.PARAMETER Priority
(Optional) An integer value between 1 and 100 that determines the default priority of the schedule if multiple tasks are pending in the queue.

.PARAMETER ExecutionOrder
(Optional) Parallel to allow jobs associated with this schedule to run at the same time, or Serial to require the jobs to run one after the other.

.PARAMETER Frequency
(Optional) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

.PARAMETER StartTime
(Optional) The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs.

.PARAMETER IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs. Valid values are 15 or 30.

.PARAMETER IntervalWeekdays
(Optional) For Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthday
(Optional) For Monthly: the day of the month when the schedule is run. For last month day, the value 0 should be supplied.

.EXAMPLE
$schedule = Update-TSSchedule -ScheduleId $oldScheduleId -State Suspended

.EXAMPLE
$schedule = Update-TSSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "16:00:00" -IntervalHours 1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#update_schedule
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ScheduleId,
    [Parameter()][string] $Name,
    [Parameter()][ValidateSet('Active','Suspended')][string] $State,
    [Parameter()][ValidateRange(1,100)][int] $Priority,
    [Parameter()][ValidateSet('Parallel','Serial')][string] $ExecutionOrder,
    [Parameter(ParameterSetName='HourlyHours')]
    [Parameter(ParameterSetName='HourlyMinutes')]
    [Parameter(ParameterSetName='Daily')]
    [Parameter(ParameterSetName='Weekly')]
    [Parameter(ParameterSetName='Monthly')]
    [ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency,
    [Parameter(ParameterSetName='HourlyHours')]
    [Parameter(ParameterSetName='HourlyMinutes')]
    [Parameter(ParameterSetName='Daily')]
    [Parameter(ParameterSetName='Weekly')]
    [Parameter(ParameterSetName='Monthly')]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime,
    [Parameter(ParameterSetName='HourlyHours')]
    [Parameter(ParameterSetName='HourlyMinutes')]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter(Mandatory,ParameterSetName='HourlyHours')][ValidateSet(1,2,4,6,8,12)][int] $IntervalHours,
    [Parameter(Mandatory,ParameterSetName='HourlyMinutes')][ValidateSet(15,30)][int] $IntervalMinutes,
    [Parameter(Mandatory,ParameterSetName='Weekly')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter(Mandatory,ParameterSetName='Monthly')][ValidateRange(0,31)][int] $IntervalMonthday # 0 for last day
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
    if ($Name) {
        $el_sched.SetAttribute("name", $Name)
    }
    if ($State) {
        $el_sched.SetAttribute("state", $State)
    }
    if ($Priority) {
        $el_sched.SetAttribute("priority", $Priority)
    }
    if ($ExecutionOrder) {
        $el_sched.SetAttribute("executionOrder", $ExecutionOrder)
    }
    if ($Frequency) {
        $el_sched.SetAttribute("frequency", $Frequency)
    }
    if ($Frequency -or $StartTime -or $EndTime) {
        $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
    }
    if ($StartTime) {
        $el_freq.SetAttribute("start", $StartTime)
    }
    if ($EndTime) {
        $el_freq.SetAttribute("end", $EndTime)
    }
    switch ($Frequency) {
        'Hourly' {
            $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
            $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
            if ($IntervalHours) {
                $el_int.SetAttribute("hours", $IntervalHours)
            } elseif ($IntervalMinutes) {
                $el_int.SetAttribute("minutes", $IntervalMinutes)
            }
        }
        'Weekly' {
            if ($IntervalWeekdays) {
                $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
                foreach ($weekday in $IntervalWeekdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                }
            }
        }
        'Monthly' { # note: updating monthly schedule via REST API doesn't seem to work
            if ($IntervalMonthday -ge 0) {
                $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
                $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                if ($IntervalMonthday -eq 0) {
                    $el_int.SetAttribute("monthDay", "LastDay")
                } else {
                    $el_int.SetAttribute("monthDay", $IntervalMonthday)
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($ScheduleId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint ServerSchedule -Param $ScheduleId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.schedule
    }
}

function Remove-TSSchedule {
<#
.SYNOPSIS
Delete Server Schedule

.DESCRIPTION
Deletes the specified schedule on Tableau Server.
This method can only be called by Server Admins.

.PARAMETER ScheduleId
The LUID of the schedule to delete.

.EXAMPLE
$response = Remove-TSSchedule -ScheduleId $oldScheduleId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#delete_schedule
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ScheduleId
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    if ($PSCmdlet.ShouldProcess($ScheduleId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint ServerSchedule -Param $ScheduleId) -Method Delete
    }
}

function Add-TSContentToSchedule {
<#
.SYNOPSIS
Add Workbook / Data Source / Flow Task to Server Schedule

.DESCRIPTION
Adds a task to refresh or accelerate a workbook to an existing schedule on Tableau Server.
Note: this is not supported on Tableau Cloud.
or
Adds a task to refresh a data source to an existing server schedule on Tableau Server.
Note: this is not supported on Tableau Cloud.
or
Adds a task to run a flow to an existing schedule.
Note: Tableau Prep Conductor is required to use this feature.

.PARAMETER ScheduleId
The LUID of the schedule that the task will be added into.

.PARAMETER WorkbookId
Add Workbook to Server Schedule: The LUID of the workbook to add to the schedule.

.PARAMETER DataAccelerationTask
Add Workbook to Server Schedule: Boolean switch, if supplied, the data acceleration task for the workbook will be added too.
Note: starting in Tableau version 2022.1 (API v3.16), the data acceleration feature is deprecated.

.PARAMETER DatasourceId
Add Data Source to Server Schedule: The LUID of the data source to add to the schedule.

.PARAMETER FlowId
Add Flow Task to Schedule: The LUID of the flow to add to the schedule.

.PARAMETER OutputStepId
Add Flow Task to Schedule: (Optional) The LUID of the specific output step, if only this step needs to be run in the scheduled task.

.PARAMETER FlowParams
Add Flow Task to Schedule: (Optional) The hashtable for the flow parameters. The keys are the parameter LUIDs and the values are the override values.

.EXAMPLE
$task = Add-TSContentToSchedule -ScheduleId $extractScheduleId -WorkbookId $workbook.id

.EXAMPLE
$task = Add-TSContentToSchedule -ScheduleId $runFlowScheduleId -FlowId $flowForTasks.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_workbook_to_schedule

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_data_source_to_schedule

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#add_flow_task_to_schedule
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $ScheduleId,
    [Parameter(ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(ParameterSetName='Workbook')][switch] $DataAccelerationTask,
    [Parameter(ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(ParameterSetName='Flow')][string] $FlowId,
    [Parameter(ParameterSetName='Flow')][string] $OutputStepId, # note: this input is ignored by the API, maybe will be supported later
    [Parameter(ParameterSetName='Flow')][hashtable] $FlowParams
)
    Assert-TSRestApiVersion -AtLeast 2.8
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_task = $tsRequest.AppendChild($xml.CreateElement("task"))
    if ($WorkbookId) {
        $el_extr = $el_task.AppendChild($xml.CreateElement("extractRefresh"))
        $el_workbook = $el_extr.AppendChild($xml.CreateElement("workbook"))
        $el_workbook.SetAttribute("id", $WorkbookId)
        $uri = Get-TSRequestUri -Endpoint Schedule -Param $ScheduleId/workbooks
        $shouldProcessItem = "schedule:$ScheduleId, workbook:$WorkbookId"
        if ($DataAccelerationTask) {
            Assert-TSRestApiVersion -AtLeast 3.8 -LessThan 3.16
            $el_da = $el_task.AppendChild($xml.CreateElement("dataAcceleration"))
            $el_workbook = $el_da.AppendChild($xml.CreateElement("workbook"))
            $el_workbook.SetAttribute("id", $WorkbookId)
            $shouldProcessItem += ", data acceleration"
        }
    } elseif ($DatasourceId) {
        $el_extr = $el_task.AppendChild($xml.CreateElement("extractRefresh"))
        $el_datasource = $el_extr.AppendChild($xml.CreateElement("datasource"))
        $el_datasource.SetAttribute("id", $DatasourceId)
        $uri = Get-TSRequestUri -Endpoint Schedule -Param $ScheduleId/datasources
        $shouldProcessItem = "schedule:$ScheduleId, datasource:$DatasourceId"
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $el_fr = $el_task.AppendChild($xml.CreateElement("flowRun"))
        $el_flow = $el_fr.AppendChild($xml.CreateElement("flow"))
        $el_flow.SetAttribute("id", $FlowId)
        $uri = Get-TSRequestUri -Endpoint Schedule -Param $ScheduleId/flows
        $shouldProcessItem = "schedule:$ScheduleId, flow:$FlowId"
        $el_frs = $el_fr.AppendChild($xml.CreateElement("flowRunSpec"))
        if ($OutputStepId) {
            $el_steps = $el_frs.AppendChild($xml.CreateElement("flowOutputSteps"))
            $el_step = $el_steps.AppendChild($xml.CreateElement("flowOutputStep"))
            $el_step.SetAttribute("id", $OutputStepId)
        }
        if ($FlowParams) {
            Assert-TSRestApiVersion -AtLeast 3.15
            $el_params = $el_frs.AppendChild($xml.CreateElement("flowParameterSpecs"))
            $FlowParams.GetEnumerator() | ForEach-Object {
                $el_param = $el_params.AppendChild($xml.CreateElement("flowParameterSpec"))
                $el_param.SetAttribute("parameterId", $_.Key)
                $el_param.SetAttribute("overrideValue", $_.Value)
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.task
    }
}

# note: return objects are different for two use cases
function Get-TSJob {
<#
.SYNOPSIS
Query Job / Query Jobs

.DESCRIPTION
Returns the details about a specific job, or a list of active jobs on the current site.

.PARAMETER JobId
Query Job: The LUID of the job to get status information for.

.PARAMETER Filter
(Optional, Query Jobs)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#jobs

.PARAMETER Sort
(Optional, Query Jobs)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

.PARAMETER Fields
(Optional, Query Jobs)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_jobs

.PARAMETER PageSize
(Optional, Query Jobs) Page size when paging through results.

.EXAMPLE
$jobStatus = Get-TSJob -JobId $job.id

.EXAMPLE
$extractJobs = Get-TSJob -Filter "jobType:eq:refresh_extracts"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_job

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_jobs
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='JobById')][string] $JobId,
    [Parameter(ParameterSetName='Jobs')][string[]] $Filter,
    [Parameter(ParameterSetName='Jobs')][string[]] $Sort,
    [Parameter(ParameterSetName='Jobs')][string[]] $Fields,
    [Parameter(ParameterSetName='Jobs')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.1
    if ($JobId) { # Query Job
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Job -Param $JobId) -Method Get
        $response.tsResponse.job
    } else { # Get Jobs
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Job
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.backgroundJobs.backgroundJob
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Stop-TSJob {
<#
.SYNOPSIS
Cancel Job

.DESCRIPTION
Cancels a specific job specified by job ID.
If the job was cancelled successfully, $null is returned, otherwise the response error is returned.

.PARAMETER JobId
The LUID of the job to cancel.

.EXAMPLE
Stop-TSJob -JobId $job.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#cancel_job
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $JobId
)
    Assert-TSRestApiVersion -AtLeast 3.1
    if ($PSCmdlet.ShouldProcess($JobId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Job -Param $JobId) -Method Put
        if ($response.tsResponse.error) {
            return $response.tsResponse.error
        } else {
            return $null # Job cancelled successfully
        }
    }
}

function Wait-TSJob {
<#
.SYNOPSIS
Wait For Job to complete

.DESCRIPTION
Wait until the job completion, while displaying the progress status.

.PARAMETER JobId
The LUID of the job process.

.PARAMETER Timeout
(Optional) Timeout in seconds. Default is 3600 (1 hour).
Set timeout to 0 to wait indefinitely long.

.PARAMETER Interval
(Optional) Poll interval in seconds. Default is 1.
Increase interval to reduce the frequency of refresh status requests.

.EXAMPLE
$finished = Wait-TSJob -JobId $job.id -Timeout 600

.NOTES
See also: wait_for_job() in TSC
#>
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $JobId,
    [Parameter()][int] $Timeout = 3600,
    [Parameter()][int] $Interval = 1
)
    do {
        Start-Sleep -s $Interval
        $Timeout--
        $jobUpdate = Get-TSJob -JobId $JobId
        if ($jobUpdate.progress) {
            Write-Progress -Activity "Running" -Status ("Job progress: {0}%" -f $jobUpdate.progress) -PercentComplete $jobUpdate.progress
        } else {
            Write-Progress -Activity "Waiting" -Status "Job not started yet" -PercentComplete 0
        }
    } until ($jobUpdate.completedAt -or $Timeout -eq 0)
    if ($jobUpdate.completedAt) {
        if ($jobUpdate.finishCode -eq 0) {
            $finishStatus = '(Success)'
        } elseif ($jobUpdate.finishCode -eq 1) {
            $finishStatus = '(FAILED)'
        } elseif ($jobUpdate.finishCode -eq 2) {
            $finishStatus = '(CANCELLED)'
        }
        Write-Progress -Activity "Finished" -Status ("Job progress: {0}% {1}" -f $jobUpdate.progress, $finishStatus) -PercentComplete $jobUpdate.progress
        Start-Sleep -s 1
        Write-Progress -Completed
    }
    return $jobUpdate
}

function Get-TSTask {
<#
.SYNOPSIS
Get Task / List Tasks on Site

.DESCRIPTION
Returns information about the specified extract refresh / run flow / run linked / data acceleration task, or a list of such tasks on the current site.
This function unifies the following API calls:
- Get Extract Refresh Task
- Get Flow Run Task
- Get Linked Task
- Get Data Acceleration Task
- List Extract Refresh Tasks in Site
- Get Flow Run Tasks
- Get Linked Tasks
- Get Data Acceleration Tasks in a Site

.PARAMETER Type
The type of the task, which corresponds to a specific API call.
Supported types are: ExtractRefresh, DataAcceleration, FlowRun, Linked

.PARAMETER TaskId
Get Task by Id: The LUID of the specific task.

.PARAMETER PageSize
(Optional, List Tasks) Page size when paging through results.

.EXAMPLE
$extractTasks = Get-TSTask -Type ExtractRefresh | Where-Object -FilterScript {$_.datasource.id -eq $datasourceForTasks.id}

.EXAMPLE
$flowTasks = Get-TSTask -Type FlowRun -TaskId $taskId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#get_extract_refresh_task

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#list_extract_refresh_tasks

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks1

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get_data_acceleration_tasks
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][ValidateSet('ExtractRefresh','FlowRun','Linked','DataAcceleration')][string] $Type,
    [Parameter(Mandatory,ParameterSetName='TaskById')][string] $TaskId,
    [Parameter(ParameterSetName='Tasks')][ValidateRange(1,100)][int] $PageSize = 100
)
    if ($TaskId) { # Get Flow Run Task / Get Extract Refresh Task / Get Linked Task / Get Data Acceleration Task
        switch ($Type) {
            'ExtractRefresh' {
                Assert-TSRestApiVersion -AtLeast 2.6
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes/$TaskId) -Method Get
                $response.tsResponse.task.extractRefresh
            }
            'FlowRun' {
                Assert-TSRestApiVersion -AtLeast 3.3
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param runFlow/$TaskId) -Method Get
                $response.tsResponse.task.flowRun
            }
            'Linked' {
                Assert-TSRestApiVersion -AtLeast 3.15
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param linked/$TaskId) -Method Get
                $response.tsResponse.linkedTask
            }
            'DataAcceleration' {
                Assert-TSRestApiVersion -AtLeast 3.8 -LessThan 3.16
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param dataAcceleration/$TaskId) -Method Get
                $response.tsResponse.task.dataAcceleration
            }
        }
    } else { # Get Flow Run Tasks / List Extract Refresh Tasks in Site / Get Linked Tasks / Get Data Acceleration Tasks in a Site
        $pageNumber = 0
        do {
            $pageNumber++
            switch ($Type) {
                'ExtractRefresh' {
                    # Assert-TSRestApiVersion -AtLeast 2.2
                    $uri = Get-TSRequestUri -Endpoint Task -Param extractRefreshes
                }
                'FlowRun' {
                    Assert-TSRestApiVersion -AtLeast 3.3
                    $uri = Get-TSRequestUri -Endpoint Task -Param runFlow
                }
                'Linked' {
                    Assert-TSRestApiVersion -AtLeast 3.15
                    $uri = Get-TSRequestUri -Endpoint Task -Param linked
                }
                'DataAcceleration' {
                    Assert-TSRestApiVersion -AtLeast 3.8 -LessThan 3.16
                    $uri = Get-TSRequestUri -Endpoint Task -Param dataAcceleration
                }
            }
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            switch ($Type) {
                'ExtractRefresh' {
                    $response.tsResponse.tasks.task.extractRefresh
                }
                'FlowRun' {
                    $response.tsResponse.tasks.task.flowRun
                }
                'Linked' {
                    $response.tsResponse.linkedTasks.linkedTasks
                }
                'DataAcceleration' {
                    $response.tsResponse.tasks.task.dataAcceleration
                }
            }
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Remove-TSTask {
<#
.SYNOPSIS
Delete Extract Refresh or Data Acceleration Task

.DESCRIPTION
Deletes the specified extract refresh task or data acceleration task.

.PARAMETER Type
The type of the task, which corresponds to a specific API call.
Supported types are: ExtractRefresh, DataAcceleration

.PARAMETER TaskId
The LUID of the task to remove.

.EXAMPLE
Remove-TSTask -Type ExtractRefresh -TaskId $extractTaskId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extract_refresh_task

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#delete_data_acceleration_task
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][ValidateSet('ExtractRefresh','DataAcceleration')][string] $Type, # 'FlowRun' not supported
    [Parameter(Mandatory)][string] $TaskId
)
    if ($PSCmdlet.ShouldProcess("$Type $TaskId")) {
        switch ($Type) {
            'ExtractRefresh' {
                Assert-TSRestApiVersion -AtLeast 3.6
                Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes/$TaskId) -Method Delete
            }
            'DataAcceleration' {
                Assert-TSRestApiVersion -AtLeast 3.8 -LessThan 3.16
                Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param dataAcceleration/$TaskId) -Method Delete
            }
        }
    }
}

function Start-TSTaskNow {
<#
.SYNOPSIS
Run Extract Refresh / Flow / Linked Task

.DESCRIPTION
Runs the specified extract refresh, flow run or linked task.

.PARAMETER TaskId
The LUID of the task to run.

.PARAMETER Type
The type of the task, which corresponds to a specific API call.
Supported types are: ExtractRefresh, FlowRun, Linked

.EXAMPLE
$job = Start-TSTaskNow -Type ExtractRefresh -TaskId $extractTaskId

.EXAMPLE
$job = Start-TSTaskNow -Type FlowRun -TaskId $flowTaskId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#run_extract_refresh_task

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_task

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_now1
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $TaskId,
    [Parameter(Mandatory)][ValidateSet('ExtractRefresh','FlowRun','Linked')][string] $Type
)
    if ($PSCmdlet.ShouldProcess("$Type $TaskId")) {
        switch ($Type) {
            'ExtractRefresh' { # Run Extract Refresh Task
                Assert-TSRestApiVersion -AtLeast 2.6
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes/$TaskId/runNow) -Body "<tsRequest />" -Method Post -ContentType "application/xml"
                return $response.tsResponse.job
            }
            'FlowRun' { # Run Flow Task
                Assert-TSRestApiVersion -AtLeast 3.3
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param runFlow/$TaskId/runNow) -Body "<tsRequest />" -Method Post -ContentType "application/xml"
                return $response.tsResponse.job
            }
            'Linked' { # Run Linked Task Now
                Assert-TSRestApiVersion -AtLeast 3.15
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param linked/$TaskId/runNow) -Body "<tsRequest />" -Method Post -ContentType "application/xml"
                return $response.tsResponse.linkedTaskJob
            }
        }
    }
}

### Extract and Encryption methods
function Get-TSExtractRefreshTasksInSchedule {
<#
.SYNOPSIS
List Extract Refresh Tasks in Server Schedule

.DESCRIPTION
Returns a list of the extract refresh tasks for a specified server schedule on the specified site on Tableau Server.
Not available for Tableau Cloud.

.PARAMETER ScheduleId
The LUID of the schedule to get extract information for.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$tasks = Get-TSExtractRefreshTasksInSchedule -ScheduleId $extractScheduleId

.NOTES
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#list_extract_refresh_tasks1
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $ScheduleId,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint Schedule -Param $ScheduleId/extracts
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.extracts.extract
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Add-TSExtractsInContent {
<#
.SYNOPSIS
Create an Extract for a Data Source / Create Extracts for Embedded Data Sources in a Workbook

.DESCRIPTION
Create/adds an extract for a data source or a workbook.

.PARAMETER WorkbookId
The LUID of the workbook.
Either workbook ID or data source ID needs to be provided.

.PARAMETER DatasourceId
The LUID of the data source.
Either workbook ID or data source ID needs to be provided.

.PARAMETER EncryptExtracts
(Optional) If true, then Tableau will attempt to encrypt the created extracts

.EXAMPLE
$job = Add-TSExtractsInContent -WorkbookId = $workbookId

.EXAMPLE
$job = Add-TSExtractsInContent -DatasourceId = $datasourceId -EncryptExtracts

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_extract_for_datasource

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_extracts_for_workbook
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter()][switch] $EncryptExtracts
)
    if ($WorkbookId) {
        Assert-TSRestApiVersion -AtLeast 3.5
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        Assert-TSRestApiVersion -AtLeast 3.5
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        $shouldProcessItem = "datasource:$DatasourceId"
    }
    $uri += "/createExtract"
    if ($EncryptExtracts) {
        $uri += "?encrypt=true"
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Post
        return $response.tsResponse.job
    }
}

function Remove-TSExtractsInContent {
<#
.SYNOPSIS
Delete the Extract from a Data Source / Delete Extracts of Embedded Data Sources from a Workbook

.DESCRIPTION
Deletes the extract(s) inside a published data source or workbook.

.PARAMETER WorkbookId
The LUID of the workbook whose extract(s) are to be deleted.
Either workbook ID or data source ID needs to be provided.

.PARAMETER DatasourceId
The LUID of the datasource whose extract is to be deleted.
Either workbook ID or data source ID needs to be provided.

.EXAMPLE
Remove-TSExtractsInContent -WorkbookId = $workbookId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extracts_from_workbook

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extract_from_datasource
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId
)
    Assert-TSRestApiVersion -AtLeast 3.5
    if ($WorkbookId) {
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        $shouldProcessItem = "datasource:$DatasourceId"
    }
    $uri += "/deleteExtract"
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        Invoke-TSRestApiMethod -Uri $uri -Method Post
    }
}

function Add-TSExtractsRefreshTask {
<#
.SYNOPSIS
Create Cloud Extract Refresh Task

.DESCRIPTION
Creates a custom schedule for an extract refresh on Tableau Cloud.

.PARAMETER WorkbookId
The LUID of the workbook that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

.PARAMETER DatasourceId
The LUID of the data source that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

.PARAMETER Type
The type of extract refresh being scheduled: FullRefresh or IncrementalRefresh

.PARAMETER Frequency
The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.

.PARAMETER StartTime
The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs. Valid value is 1.

.PARAMETER IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs. Valid value is 60.

.PARAMETER IntervalWeekdays
(Optional) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthdayNr
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

.PARAMETER IntervalMonthdayWeekday
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

.PARAMETER IntervalMonthdays
(Optional) For Monthly, describing specific days in a month, e.g. for 3rd and 5th days, the list of values 3 and 5 should be provided.

.EXAMPLE
$extractTaskResult = Add-TSExtractsRefreshTask -WorkbookId $workbook.id -Type FullRefresh -Frequency Daily -StartTime 12:00:00 -IntervalHours 24 -IntervalWeekdays 'Sunday','Monday'

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_cloud_extract_refresh_task
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter()][ValidateSet('FullRefresh','IncrementalRefresh')][string] $Type = 'FullRefresh',
    [Parameter()][ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency = 'Daily',
    [Parameter()][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime = '00:00:00',
    [Parameter()][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter()][ValidateSet(1,2,4,6,8,12,24)][int] $IntervalHours,
    [Parameter()][ValidateSet(15,30,60)][int] $IntervalMinutes,
    [Parameter()][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter()][ValidateRange(0,5)][int] $IntervalMonthdayNr,
    [Parameter()][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string] $IntervalMonthdayWeekday,
    [Parameter()][ValidateRange(1,31)][int[]] $IntervalMonthdays
)
    Assert-TSRestApiVersion -AtLeast 3.20
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_extr = $tsRequest.AppendChild($xml.CreateElement("extractRefresh"))
    $el_extr.SetAttribute("type", $Type)
    if ($WorkbookId) {
        $el_workbook = $el_extr.AppendChild($xml.CreateElement("workbook"))
        $el_workbook.SetAttribute("id", $WorkbookId)
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        $el_datasource = $el_extr.AppendChild($xml.CreateElement("datasource"))
        $el_datasource.SetAttribute("id", $DatasourceId)
        $shouldProcessItem = "datasource:$DatasourceId"
    }
    $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
    $el_sched.SetAttribute("frequency", $Frequency)
    $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
    $el_freq.SetAttribute("start", $StartTime)
    if ($EndTime) {
        $el_freq.SetAttribute("end", $EndTime)
    }
    $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
    switch ($Frequency) {
        'Hourly' {
            if ($IntervalHours) {
                $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
            }
            if ($IntervalMinutes) {
                $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("minutes", $IntervalMinutes)
            }
            if ($IntervalWeekdays) {
                foreach ($weekday in $IntervalWeekdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                }
            }
        }
        'Daily' {
            if ($IntervalHours) {
                $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
            }
            if ($IntervalWeekdays) {
                foreach ($weekday in $IntervalWeekdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                }
            }
        }
        'Weekly' {
            if ($IntervalWeekdays) {
                foreach ($weekday in $IntervalWeekdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                }
            }
        }
        'Monthly' {
            if ($IntervalMonthdayNr -ge 0 -and $IntervalMonthdayWeekday) {
                $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                switch ($IntervalMonthdayNr) {
                    0 { $el_int.SetAttribute("monthDay", "LastDay") }
                    1 { $el_int.SetAttribute("monthDay", "First") }
                    2 { $el_int.SetAttribute("monthDay", "Second") }
                    3 { $el_int.SetAttribute("monthDay", "Third") }
                    4 { $el_int.SetAttribute("monthDay", "Fourth") }
                    5 { $el_int.SetAttribute("monthDay", "Fifth") }
                }
                $el_int.SetAttribute("weekDay", $IntervalMonthdayWeekday)
            } elseif ($IntervalMonthdayNr -eq 0) { # last day of the month
                $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", "LastDay")
            } elseif ($IntervalMonthdays) {
                foreach ($monthday in $IntervalMonthdays) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", $monthday)
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes) -Body $xml.OuterXml -Method Post #-ContentType "application/xml"
        return $response.tsResponse
    }
}

function Update-TSExtractsRefreshTask {
<#
.SYNOPSIS
Update Cloud extract refresh task

.DESCRIPTION
Updates a custom schedule for an extract refresh task on Tableau Cloud.

.PARAMETER TaskId
The LUID of the extract refresh task.

.PARAMETER WorkbookId
The LUID of the workbook that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

.PARAMETER DatasourceId
The LUID of the data source that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

.PARAMETER Type
(Optional) The type of extract refresh being scheduled: FullRefresh or IncrementalRefresh

.PARAMETER Frequency
(Optional) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

.PARAMETER StartTime
(Optional) The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs. Valid value is 1.

.PARAMETER IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs. Valid value is 60.

.PARAMETER IntervalWeekdays
(Optional) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthdayNr
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

.PARAMETER IntervalMonthdayWeekday
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

.PARAMETER IntervalMonthdays
(Optional) For Monthly, describing specific days in a month, e.g. for 3rd and 5th days, the list of values 3 and 5 should be provided.

.EXAMPLE
$extractTaskResult = Update-TSExtractsRefreshTask -TaskId $taskId -DatasourceId $datasource.id -Type FullRefresh -Frequency Hourly -StartTime 08:00:00 -EndTime 20:00:00 -IntervalHours 6 -IntervalWeekdays 'Tuesday'

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#update_cloud_extract_refresh_task
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $TaskId,
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter()][ValidateSet('FullRefresh','IncrementalRefresh')][string] $Type,
    [Parameter()][ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency,
    [Parameter()][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime,
    [Parameter()][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter()][ValidateSet(1,2,4,6,8,12,24)][int] $IntervalHours,
    [Parameter()][ValidateSet(15,30,60)][int] $IntervalMinutes,
    [Parameter()][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter()][ValidateRange(0,5)][int] $IntervalMonthdayNr, # 0 for last day
    [Parameter()][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string] $IntervalMonthdayWeekday,
    [Parameter()][ValidateRange(1,31)][int[]] $IntervalMonthdays # specific month days
)
    Assert-TSRestApiVersion -AtLeast 3.20
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_extr = $tsRequest.AppendChild($xml.CreateElement("extractRefresh"))
    if ($Type) {
        $el_extr.SetAttribute("type", $Type)
    }
    if ($WorkbookId) {
        $el_workbook = $el_extr.AppendChild($xml.CreateElement("workbook"))
        $el_workbook.SetAttribute("id", $WorkbookId)
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        $el_datasource = $el_extr.AppendChild($xml.CreateElement("datasource"))
        $el_datasource.SetAttribute("id", $DatasourceId)
        $shouldProcessItem = "datasource:$DatasourceId"
    }
    if ($Frequency) {
        $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
        $el_sched.SetAttribute("frequency", $Frequency)
        $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
        $el_freq.SetAttribute("start", $StartTime)
        if ($EndTime) {
            $el_freq.SetAttribute("end", $EndTime)
        }
        $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
        switch ($Frequency) {
            'Hourly' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalMinutes) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("minutes", $IntervalMinutes)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Daily' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Weekly' {
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Monthly' {
                if ($IntervalMonthdayNr -ge 0 -and $IntervalMonthdayWeekday) {
                    $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                    switch ($IntervalMonthdayNr) {
                        0 { $el_int.SetAttribute("monthDay", "LastDay") }
                        1 { $el_int.SetAttribute("monthDay", "First") }
                        2 { $el_int.SetAttribute("monthDay", "Second") }
                        3 { $el_int.SetAttribute("monthDay", "Third") }
                        4 { $el_int.SetAttribute("monthDay", "Fourth") }
                        5 { $el_int.SetAttribute("monthDay", "Fifth") }
                    }
                    $el_int.SetAttribute("weekDay", $IntervalMonthdayWeekday)
                } elseif ($IntervalMonthdayNr -eq 0) { # last day of the month
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", "LastDay")
                } elseif ($IntervalMonthdays) {
                    foreach ($monthday in $IntervalMonthdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", $monthday)
                    }
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes/$TaskId) -Body $xml.OuterXml -Method Put #-ContentType "application/xml"
        return $response.tsResponse
    }
}

function Invoke-TSEncryption {
<#
.SYNOPSIS
Encrypt Extracts in a Site / Decrypt Extracts in a Site / Reencrypt Extracts in a Site

.DESCRIPTION
Encrypts, decrypts or re-encrypts all extracts with new encryption keys on the specified site.
Extract encryption at rest is a data security feature that allows you to encrypt .hyper extracts while they are stored on Tableau Server.
Note: Depending on the number and size of extracts, this operation may consume significant server resources.
Consider running this command outside of normal business hours.

.PARAMETER EncryptExtracts
Boolean switch, if supplied, the encryption of all extracts is triggered.

.PARAMETER DecryptExtracts
Boolean switch, if supplied, the decryption of all extracts is triggered.

.PARAMETER ReencryptExtracts
Boolean switch, if supplied, the re-encryption of all extracts is triggered.

.PARAMETER SiteId
Site LUID where the encryption process should be conducted. If omitted, the current site is used.

.EXAMPLE
Invoke-TSEncryption -EncryptExtracts

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#encrypt_extracts

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#decrypt_extracts

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#reencrypt_extracts
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory,ParameterSetName='Encrypt')][switch] $EncryptExtracts,
    [Parameter(Mandatory,ParameterSetName='Decrypt')][switch] $DecryptExtracts,
    [Parameter(Mandatory,ParameterSetName='Reencrypt')][switch] $ReencryptExtracts,
    [Parameter()][string] $SiteId
)
    if (-Not $SiteId) {
        $SiteId = $script:TSSiteId
    }
    if ($EncryptExtracts) {
        if ($PSCmdlet.ShouldProcess("encrypt extracts on site $SiteId")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param "$SiteId/encrypt-extracts") -Method Post
        }
    } elseif ($DecryptExtracts) {
        if ($PSCmdlet.ShouldProcess("decrypt extracts on site $SiteId")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param "$SiteId/decrypt-extracts") -Method Post
        }
    } elseif ($ReencryptExtracts) {
        if ($PSCmdlet.ShouldProcess("reencrypt extracts on site $SiteId")) {
            Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Site -Param "$SiteId/reencrypt-extracts") -Method Post
        }
    }
}

### Favorites methods
function Get-TSUserFavorite {
<#
.SYNOPSIS
Get Favorites for User

.DESCRIPTION
Returns a list of favorite projects, data sources, views, workbooks, and flows for a user.

.PARAMETER UserId
The LUID of the user for which you want to get a list favorites.

.PARAMETER PageSize
(Optional) Page size when paging through results.

.EXAMPLE
$favorites = Get-TSUserFavorite -UserId (Get-TSCurrentUserId)

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#get_favorites_for_user
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 2.5
    $pageNumber = 0
    do {
        $pageNumber++
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId
        $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
        $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
        $totalAvailable = $response.tsResponse.pagination.totalAvailable
        $response.tsResponse.favorites.favorite
    } until ($PageSize*$pageNumber -ge $totalAvailable)
}

function Add-TSUserFavorite {
<#
.SYNOPSIS
Add Workbook / Data Source / View / Project / Flow to Favorites

.DESCRIPTION
Adds the specified content to a user's favorites.

.PARAMETER UserId
The LUID of the user to add the favorite for.

.PARAMETER Label
(Optional) A label to assign to the favorite. This value is displayed when you search for favorites on the server.
Note: label has to be unique for the content type, if an existing label is supplied, an error is returned.
If label is omitted, the content ID is used.

.PARAMETER WorkbookId
The LUID of the workbook to add as a favorite.

.PARAMETER DatasourceId
The LUID of the data source to add as a favorite.

.PARAMETER ViewId
The LUID of the view to add as a favorite.

.PARAMETER ProjectId
The LUID of the project to add as a favorite.

.PARAMETER FlowId
The LUID of the flow to add as a favorite.

.EXAMPLE
Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $workbook.id -Label $workbook.name

.EXAMPLE
Add-TSUserFavorite -UserId (Get-TSCurrentUserId) -ProjectId $reportsProjectId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_workbook_to_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_data_source_to_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_view_to_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_project_to_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_flow_to_favorites
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter()][string] $Label,
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId
)
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_favorite = $tsRequest.AppendChild($xml.CreateElement("favorite"))
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $el_favorite.AppendChild($xml.CreateElement("workbook")).SetAttribute("id", $WorkbookId)
        if ($Label) {
            $el_favorite.SetAttribute("label", $Label)
        } else {
            $el_favorite.SetAttribute("label", $WorkbookId)
        }
        $shouldProcessItem = "user:$UserId, workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.3
        $el_favorite.AppendChild($xml.CreateElement("datasource")).SetAttribute("id", $DatasourceId)
        if ($Label) {
            $el_favorite.SetAttribute("label", $Label)
        } else {
            $el_favorite.SetAttribute("label", $DatasourceId)
        }
        $shouldProcessItem = "user:$UserId, datasource:$DatasourceId"
    } elseif ($ViewId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $el_favorite.AppendChild($xml.CreateElement("view")).SetAttribute("id", $ViewId)
        if ($Label) {
            $el_favorite.SetAttribute("label", $Label)
        } else {
            $el_favorite.SetAttribute("label", $ViewId)
        }
        $shouldProcessItem = "user:$UserId, view:$ViewId"
    } elseif ($ProjectId) {
        Assert-TSRestApiVersion -AtLeast 3.1
        $el_favorite.AppendChild($xml.CreateElement("project")).SetAttribute("id", $ProjectId)
        if ($Label) {
            $el_favorite.SetAttribute("label", $Label)
        } else {
            $el_favorite.SetAttribute("label", $ProjectId)
        }
        $shouldProcessItem = "user:$UserId, project:$ProjectId"
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $el_favorite.AppendChild($xml.CreateElement("flow")).SetAttribute("id", $FlowId)
        if ($Label) {
            $el_favorite.SetAttribute("label", $Label)
        } else {
            $el_favorite.SetAttribute("label", $FlowId)
        }
        $shouldProcessItem = "user:$UserId, flow:$FlowId"
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.favorites.favorite
    }
}

function Remove-TSUserFavorite {
<#
.SYNOPSIS
Delete Workbook / Data Source / View / Project / Flow from Favorites

.DESCRIPTION
Removes the specified content to a user's favorites.

.PARAMETER UserId
The LUID of the user to remove favorite for.

.PARAMETER WorkbookId
The LUID of the workbook to remove from favorite.

.PARAMETER DatasourceId
The LUID of the data source to remove from favorite.

.PARAMETER ViewId
The LUID of the view to remove from favorite.

.PARAMETER ProjectId
The LUID of the project to remove from favorite.

.PARAMETER FlowId
The LUID of the flow to remove from favorite.

.EXAMPLE
Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $workbook.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_workbook_from_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_data_source_from_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_view_from_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_project_from_favorites

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#ref_delete_flow_from_favorites
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
    [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
    [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId
)
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/workbooks/$WorkbookId
        $shouldProcessItem = "user:$UserId, workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.3
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/datasources/$DatasourceId
        $shouldProcessItem = "user:$UserId, datasource:$DatasourceId"
    } elseif ($ViewId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/views/$ViewId
        $shouldProcessItem = "user:$UserId, view:$ViewId"
    } elseif ($ProjectId) {
        Assert-TSRestApiVersion -AtLeast 3.1
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/projects/$ProjectId
        $shouldProcessItem = "user:$UserId, project:$ProjectId"
    } elseif ($FlowId) {
        Assert-TSRestApiVersion -AtLeast 3.3
        $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/flows/$FlowId
        $shouldProcessItem = "user:$UserId, flow:$FlowId"
    }
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        Invoke-TSRestApiMethod -Uri $uri -Method Delete
    }
}

function Move-TSUserFavorite {
<#
.SYNOPSIS
Organize Favorites

.DESCRIPTION
Move an item to organize a user's favorites list.

.PARAMETER UserId
The LUID of the user to arrange favorites for.

.PARAMETER FavoriteId
The LUID of the specific favorite item to arrange.

.PARAMETER FavoriteType
The type of the specific favorite item to arrange.
Valid types are Workbook, Datasource, View, Project, Flow.

.PARAMETER AfterFavoriteId
The LUID of a favorite item that should precede (insert the specific favorite after this item).

.PARAMETER AfterFavoriteType
The type of a favorite item that should precede (insert the specific favorite after this item).
Valid types are Workbook, Datasource, View, Project, Flow.

.EXAMPLE
Move-TSUserFavorite -UserId (Get-TSCurrentUserId) -FavoriteId $view.id -FavoriteType View -AfterFavoriteId $view2.id -AfterFavoriteType View

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#update_favorites
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $UserId,
    [Parameter(Mandatory)][string] $FavoriteId,
    [Parameter(Mandatory)][ValidateSet('Workbook','Datasource','View','Project','Flow')][string] $FavoriteType,
    [Parameter(Mandatory)][string] $AfterFavoriteId,
    [Parameter(Mandatory)][ValidateSet('Workbook','Datasource','View','Project','Flow')][string] $AfterFavoriteType
)
    Assert-TSRestApiVersion -AtLeast 3.8
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_fos = $tsRequest.AppendChild($xml.CreateElement("favoriteOrderings"))
    $el_fo = $el_fos.AppendChild($xml.CreateElement("favoriteOrdering"))
    $el_fo.SetAttribute("favoriteId", $FavoriteId)
    $el_fo.SetAttribute("favoriteType", $FavoriteType.ToLower()) # note: needs to be lowercase, otherwise TS will return error 400
    $el_fo.SetAttribute("favoriteIdMoveAfter", $AfterFavoriteId)
    $el_fo.SetAttribute("favoriteTypeMoveAfter", $AfterFavoriteType.ToLower()) # note: needs to be lowercase, otherwise TS will return error 400
    if ($PSCmdlet.ShouldProcess("user:$UserId, favorite($FavoriteType):$FavoriteId, after($AfterFavoriteType):$AfterFavoriteId")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint OrderFavorites -Param $UserId) -Body $xml.OuterXml -Method Put
    }
}

### Subscription methods
function Get-TSSubscription {
<#
.SYNOPSIS
Get Subscription / List Subscriptions

.DESCRIPTION
Returns information about the specified subscription, or a list of subscriptions.

.PARAMETER SubscriptionId
Get Subscription: The ID of the subscription to get information for.

.PARAMETER PageSize
(Optional, List Subscriptions) Page size when paging through results.

.EXAMPLE
$subscriptions = Get-TSSubscription

.EXAMPLE
$subscription = Get-TSSubscription -SubscriptionId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#get_subscription

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#list_subscriptions
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='SubscriptionById')][string] $SubscriptionId,
    [Parameter(ParameterSetName='Subscriptions')][ValidateRange(1,100)][int] $PageSize = 100
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    if ($SubscriptionId) { # Get Subscription
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Subscription -Param $SubscriptionId) -Method Get
        $response.tsResponse.subscription
    } else { # List Subscriptions
        $pageNumber = 0
        do {
            $pageNumber++
            $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Subscription) -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.subscriptions.subscription
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Add-TSSubscription {
<#
.SYNOPSIS
Create Subscription

.DESCRIPTION
Creates a new, unsuspended subscription to a view or workbook for a specific user on Tableau Server and Tableau Cloud.
When a user is subscribed to the content, Tableau sends the content to the user in email on the schedule that you define.

.PARAMETER Subject
A description, or subject for the subscription.
This subject is displayed when users list subscriptions for a site in the server environment.

.PARAMETER Message
The text body of the subscription email message.

.PARAMETER UserId
The LUID of the user to create the subscription for.

.PARAMETER ContentType
Workbook to create a subscription for a workbook, or View to create a subscription for a view.

.PARAMETER ContentId
The LUID of the workbook or view to subscribe to.

.PARAMETER SendIfViewEmpty
(Optional) Applies to views only. If true, an image is sent even if the view specified in a subscription is empty.
If false, nothing is sent if the view is empty. The default value is true.

.PARAMETER AttachImage
(Optional) Setting this true will cause the subscriber to receive mail with .png images of workbooks or views attached to it.

.PARAMETER AttachPdf
(Optional) Setting this true will cause the subscriber to receive mail with a .pdf file containing images of workbooks or views attached to it.

.PARAMETER PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

.PARAMETER PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced. The value can be Portrait or Landscape.
Default is Portrait.

.PARAMETER ScheduleId
(Optional) The ID of a schedule to associate the subscription with.
This needs to be provided only for Tableau Server Request, but not for Tableau Cloud.

.PARAMETER Frequency
(Optional, for Tableau Cloud) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

.PARAMETER StartTime
(Optional, for Tableau Cloud) The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional, for Tableau Cloud) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional, for Tableau Cloud) For Hourly: the interval in hours between schedule runs. Valid value is 1.

.PARAMETER IntervalMinutes
(Optional, for Tableau Cloud) For Hourly: the interval in minutes between schedule runs. Valid value is 60.

.PARAMETER IntervalWeekdays
(Optional, for Tableau Cloud) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthdayNr
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

.PARAMETER IntervalMonthdayWeekday
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

.PARAMETER IntervalMonthdays
(Optional, for Tableau Cloud) For Monthly, describing specific days in a month, e.g. for 3rd and 5th days, the list of values 3 and 5 should be provided.

.EXAMPLE
$subscription = Add-TSSubscription -ScheduleId $subscriptionScheduleId -ContentType Workbook -ContentId $workbook.id -Subject "test" -Message "Test subscription" -UserId (Get-TSCurrentUserId)

.EXAMPLE
$subscription = Add-TSSubscription -ContentType View -ContentId $view.id -Subject "test" -Message "Test subscription" -UserId (Get-TSCurrentUserId) -Frequency Weekly -StartTime 12:00:00 -IntervalWeekdays 'Sunday'

.NOTES
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#create_subscription
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Subject,
    [Parameter(Mandatory)][string] $Message,
    [Parameter(Mandatory)][string] $UserId,
    [Parameter(Mandatory)][ValidateSet('Workbook','View')][string] $ContentType,
    [Parameter(Mandatory)][string] $ContentId,
    [Parameter()][ValidateSet('true','false')][string] $SendIfViewEmpty = 'true',
    [Parameter()][ValidateSet('true','false')][string] $AttachImage = 'true',
    [Parameter()][ValidateSet('true','false')][string] $AttachPdf = 'false',
    [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid')][string] $PageType = 'A4',
    [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = 'Portrait',
    [Parameter(Mandatory,ParameterSetName='ServerSchedule')][string] $ScheduleId,
    [Parameter(Mandatory,ParameterSetName='CloudSchedule')][ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency = 'Daily',
    [Parameter(Mandatory,ParameterSetName='CloudSchedule')][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime = '00:00:00',
    [Parameter(ParameterSetName='CloudSchedule')][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet(1,2,4,6,8,12,24)][int] $IntervalHours,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet(15,30,60)][int] $IntervalMinutes,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateRange(0,5)][int] $IntervalMonthdayNr, # 0 for last day
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string] $IntervalMonthdayWeekday,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateRange(1,31)][int[]] $IntervalMonthdays # specific month days
)
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_subs = $tsRequest.AppendChild($xml.CreateElement("subscription"))
    $el_subs.SetAttribute("subject", $Subject)
    $el_subs.SetAttribute("message", $Message)
    $el_subs.SetAttribute("attachImage", $AttachImage)
    $el_subs.SetAttribute("attachPdf", $AttachPdf)
    if ($AttachPd -eq 'true') {
        $el_subs.SetAttribute("pageOrientation", $PageOrientation)
        $el_subs.SetAttribute("pageSizeOption", $PageType)
    }
    $el_content = $el_subs.AppendChild($xml.CreateElement("content"))
    $el_content.SetAttribute("id", $ContentId)
    $el_content.SetAttribute("type", $ContentType)
    if ($ContentType -eq 'View') {
        $el_content.SetAttribute("sendIfViewEmpty", $SendIfViewEmpty)
    }
    $el_user = $el_subs.AppendChild($xml.CreateElement("user"))
    $el_user.SetAttribute("id", $UserId)
    if ($ScheduleId) { # Create Subscription on Tableau Server
        # Assert-TSRestApiVersion -AtLeast 2.3
        $el_sched = $el_subs.AppendChild($xml.CreateElement("schedule"))
        $el_sched.SetAttribute("id", $ScheduleId)
    } elseif ($Frequency) { # Create Subscription on Tableau Cloud
        Assert-TSRestApiVersion -AtLeast 3.20
        $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
        $el_sched.SetAttribute("frequency", $Frequency)
        $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
        $el_freq.SetAttribute("start", $StartTime)
        if ($EndTime) {
            $el_freq.SetAttribute("end", $EndTime)
        }
        $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
        switch ($Frequency) {
            'Hourly' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalMinutes) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("minutes", $IntervalMinutes)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Daily' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Weekly' {
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Monthly' {
                if ($IntervalMonthdayNr -ge 0 -and $IntervalMonthdayWeekday) {
                    $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                    switch ($IntervalMonthdayNr) {
                        0 { $el_int.SetAttribute("monthDay", "LastDay") }
                        1 { $el_int.SetAttribute("monthDay", "First") }
                        2 { $el_int.SetAttribute("monthDay", "Second") }
                        3 { $el_int.SetAttribute("monthDay", "Third") }
                        4 { $el_int.SetAttribute("monthDay", "Fourth") }
                        5 { $el_int.SetAttribute("monthDay", "Fifth") }
                    }
                    $el_int.SetAttribute("weekDay", $IntervalMonthdayWeekday)
                } elseif ($IntervalMonthdayNr -eq 0) { # last day of the month
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", "LastDay")
                } elseif ($IntervalMonthdays) {
                    foreach ($monthday in $IntervalMonthdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", $monthday)
                    }
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($Subject)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Subscription) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.subscription
    }
}

function Update-TSSubscription {
<#
.SYNOPSIS
Update Subscription

.DESCRIPTION
Modifies an existing subscription on Tableau Server.
You can change the subject, server schedule, and suspension state for the subscription.

.PARAMETER SubscriptionId
The LUID of the subscription to update.

.PARAMETER Subject
(Optional) The new description, or subject for the subscription.

.PARAMETER Message
(Optional) The new text body of the subscription email message.

.PARAMETER UserId
(Optional) The LUID of the user to create the subscription for.

.PARAMETER ContentType
(Optional) Workbook to create a subscription for a workbook, or View to create a subscription for a view.

.PARAMETER ContentId
(Optional) The LUID of the workbook or view to subscribe to.

.PARAMETER SendIfViewEmpty
(Optional) Applies to views only. If true, an image is sent even if the view specified in a subscription is empty.
If false, nothing is sent if the view is empty. The default value is true.

.PARAMETER AttachImage
(Optional) Setting this true will cause the subscriber to receive mail with .png images of workbooks or views attached to it.

.PARAMETER AttachPdf
(Optional) Setting this true will cause the subscriber to receive mail with a .pdf file containing images of workbooks or views attached to it.

.PARAMETER PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

.PARAMETER PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced. The value can be Portrait or Landscape.
Default is Portrait.

.PARAMETER Suspended
(Optional) Supply 'true' to suspend the subscription, or 'false' to unsuspend it.

.PARAMETER ScheduleId
(Optional) The ID of a schedule to associate the subscription with.
This needs to be provided only for Tableau Server Request, but not for Tableau Cloud.

.PARAMETER Frequency
(Optional, for Tableau Cloud) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

.PARAMETER StartTime
(Optional, for Tableau Cloud) The starting daytime for scheduled jobs. For Hourly: the starting time of execution period (for example, 18:30:00).

.PARAMETER EndTime
(Optional, for Tableau Cloud) For Hourly: the ending time for execution period (for example, 21:00:00).

.PARAMETER IntervalHours
(Optional, for Tableau Cloud) For Hourly: the interval in hours between schedule runs. Valid value is 1.

.PARAMETER IntervalMinutes
(Optional, for Tableau Cloud) For Hourly: the interval in minutes between schedule runs. Valid value is 60.

.PARAMETER IntervalWeekdays
(Optional, for Tableau Cloud) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs. The week days are specified strings (weekday names in English).

.PARAMETER IntervalMonthdayNr
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

.PARAMETER IntervalMonthdayWeekday
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g. for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

.PARAMETER IntervalMonthdays
(Optional, for Tableau Cloud) For Monthly, describing specific days in a month, e.g. for 3rd and 5th days, the list of values 3 and 5 should be provided.

.EXAMPLE
$subscription = Update-TSSubscription -SubscriptionId $subscription.id -ScheduleId $subscriptionScheduleId -ContentType View -ContentId $view.id -Subject "Subscription test"

.EXAMPLE
$subscription = Update-TSSubscription -SubscriptionId $subscription.id -ContentType View -ContentId $view.id -Subject "test1" -Message "Test subscription1" -UserId (Get-TSCurrentUserId) -Frequency Monthly -StartTime 14:00:00 -IntervalMonthdays 5,10

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#update_subscription
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $SubscriptionId,
    [Parameter()][string] $Subject,
    [Parameter()][string] $Message,
    [Parameter()][string] $UserId,
    [Parameter()][ValidateSet('Workbook','View')][string] $ContentType,
    [Parameter()][string] $ContentId,
    [Parameter()][ValidateSet('true','false')][string] $SendIfViewEmpty,
    [Parameter()][ValidateSet('true','false')][string] $AttachImage,
    [Parameter()][ValidateSet('true','false')][string] $AttachPdf,
    [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid')][string] $PageType,
    [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation,
    [Parameter()][ValidateSet('true','false')][string] $Suspended,
    [Parameter(ParameterSetName='ServerSchedule')][string] $ScheduleId,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency,
    [Parameter(ParameterSetName='CloudSchedule')][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime,
    [Parameter(ParameterSetName='CloudSchedule')][ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet(1,2,4,6,8,12,24)][int] $IntervalHours,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet(15,30,60)][int] $IntervalMinutes,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateRange(0,5)][int] $IntervalMonthdayNr, # 0 for last day
    [Parameter(ParameterSetName='CloudSchedule')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string] $IntervalMonthdayWeekday,
    [Parameter(ParameterSetName='CloudSchedule')][ValidateRange(1,31)][int[]] $IntervalMonthdays # specific month days
)
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_subs = $tsRequest.AppendChild($xml.CreateElement("subscription"))
    if ($Subject) {
        $el_subs.SetAttribute("subject", $Subject)
    }
    if ($Message) {
        $el_subs.SetAttribute("message", $Message)
    }
    if ($AttachImage) {
        $el_subs.SetAttribute("attachImage", $AttachImage)
    }
    if ($AttachPdf) {
        $el_subs.SetAttribute("attachPdf", $AttachPdf)
    }
    if ($AttachPdf -eq 'true' -and $PageOrientation) {
        $el_subs.SetAttribute("pageOrientation", $PageOrientation)
    }
    if ($AttachPdf -eq 'true' -and $PageType) {
        $el_subs.SetAttribute("pageSizeOption", $PageType)
    }
    if ($Suspended) {
        $el_subs.SetAttribute("suspended", $Suspended)
    }
    if ($ContentId -or $SendIfViewEmpty) {
        $el_content = $el_subs.AppendChild($xml.CreateElement("content"))
        if ($ContentId) {
            $el_content.SetAttribute("id", $ContentId)
        }
        if ($ContentType) {
            $el_content.SetAttribute("type", $ContentType)
        }
        if ($SendIfViewEmpty) {
            $el_content.SetAttribute("sendIfViewEmpty", $SendIfViewEmpty)
        }
    }
    if ($UserId) {
        $el_user = $el_subs.AppendChild($xml.CreateElement("user"))
        $el_user.SetAttribute("id", $UserId)
    }
    if ($ScheduleId) { # Update Subscription on Tableau Server
        # Assert-TSRestApiVersion -AtLeast 2.3
        $el_sched = $el_subs.AppendChild($xml.CreateElement("schedule"))
        $el_sched.SetAttribute("id", $ScheduleId)
    } elseif ($Frequency) { # Update Subscription on Tableau Cloud
        Assert-TSRestApiVersion -AtLeast 3.20
        $el_sched = $tsRequest.AppendChild($xml.CreateElement("schedule"))
        $el_sched.SetAttribute("frequency", $Frequency)
        $el_freq = $el_sched.AppendChild($xml.CreateElement("frequencyDetails"))
        $el_freq.SetAttribute("start", $StartTime)
        if ($EndTime) {
            $el_freq.SetAttribute("end", $EndTime)
        }
        $el_ints = $el_freq.AppendChild($xml.CreateElement("intervals"))
        switch ($Frequency) {
            'Hourly' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalMinutes) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("minutes", $IntervalMinutes)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Daily' {
                if ($IntervalHours) {
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("hours", $IntervalHours)
                }
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Weekly' {
                if ($IntervalWeekdays) {
                    foreach ($weekday in $IntervalWeekdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("weekDay", $weekday)
                    }
                }
            }
            'Monthly' {
                if ($IntervalMonthdayNr -ge 0 -and $IntervalMonthdayWeekday) {
                    $el_int = $el_ints.AppendChild($xml.CreateElement("interval"))
                    switch ($IntervalMonthdayNr) {
                        0 { $el_int.SetAttribute("monthDay", "LastDay") }
                        1 { $el_int.SetAttribute("monthDay", "First") }
                        2 { $el_int.SetAttribute("monthDay", "Second") }
                        3 { $el_int.SetAttribute("monthDay", "Third") }
                        4 { $el_int.SetAttribute("monthDay", "Fourth") }
                        5 { $el_int.SetAttribute("monthDay", "Fifth") }
                    }
                    $el_int.SetAttribute("weekDay", $IntervalMonthdayWeekday)
                } elseif ($IntervalMonthdayNr -eq 0) { # last day of the month
                    $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", "LastDay")
                } elseif ($IntervalMonthdays) {
                    foreach ($monthday in $IntervalMonthdays) {
                        $el_ints.AppendChild($xml.CreateElement("interval")).SetAttribute("monthDay", $monthday)
                    }
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($SubscriptionId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Subscription -Param $SubscriptionId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.subscription
    }
}

function Remove-TSSubscription {
<#
.SYNOPSIS
Delete Subscription

.DESCRIPTION
Deletes the specified subscription on Tableau Server or Tableau Cloud.

.PARAMETER SubscriptionId
The ID of the subscription to delete.

.EXAMPLE
Remove-TSSubscription -SubscriptionId $subscriptionId

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#delete_subscription
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $SubscriptionId
)
    # Assert-TSRestApiVersion -AtLeast 2.3
    if ($PSCmdlet.ShouldProcess($SubscriptionId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Subscription -Param $SubscriptionId) -Method Delete
    }
}

### Notifications methods
function Get-TSDataAlert {
<#
.SYNOPSIS
Get Data-Driven Alert / List Data-Driven Alerts on Site

.DESCRIPTION
Returns details on a specified data-driven alert, or a list of data-driven alerts in use on the specified site

.PARAMETER DataAlertId
Get Data-Driven Alert: The LUID of the data-driven alert.

.PARAMETER Filter
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

.PARAMETER Sort
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

.PARAMETER Fields
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm

.PARAMETER PageSize
(Optional, List Data-Driven Alerts on Site) Page size when paging through results.

.EXAMPLE
$dataAlert = Get-TSDataAlert -DataAlertId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alert_details

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alerts
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='DataAlertById')][string] $DataAlertId,
    [Parameter(ParameterSetName='DataAlerts')][string[]] $Filter,
    [Parameter(ParameterSetName='DataAlerts')][string[]] $Sort,
    [Parameter(ParameterSetName='DataAlerts')][string[]] $Fields,
    [Parameter(ParameterSetName='DataAlerts')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.2
    if ($DataAlertId) { # Get Data-Driven Alert
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert -Param $DataAlertId) -Method Get
        $response.tsResponse.dataAlert
    } else { # List Data-Driven Alerts on Site
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint DataAlert
            $uriParam = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $uriParam.Add("pageSize", $PageSize)
            $uriParam.Add("pageNumber", $pageNumber)
            if ($Filter) {
                $uriParam.Add("filter", $Filter -join ',')
            }
            if ($Sort) {
                $uriParam.Add("sort", $Sort -join ',')
            }
            if ($Fields) {
                $uriParam.Add("fields", $Fields -join ',')
            }
            $uriRequest = [System.UriBuilder]$uri
            $uriRequest.Query = $uriParam.ToString()
            $response = Invoke-TSRestApiMethod -Uri $uriRequest.Uri.OriginalString -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.dataAlerts.dataAlert
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Add-TSDataAlert {
<#
.SYNOPSIS
Create Data Driven Alert

.DESCRIPTION
Create a data driven alert (DDA) for a view with a single data axis.

.PARAMETER Subject
The name of the data driven alert.

.PARAMETER Condition
The condition that triggers the DDA. Used in conjunction with the threshold to determine when to trigger an alert.
Valid values: above, above-equal, below, below-equal, equal

.PARAMETER Threshold
Numeric value for the alert threshold. A data alert is triggered when this threshold is crossed.

.PARAMETER Frequency
The time period between attempts by Tableau to assess whether the alert threshold has been crossed.
Valid values: once, freguently, hourly, daily, weekly.
Default is once.

.PARAMETER Visibility
Determines whether the alert can be seen by only its creator (private), or by any user with permissions to the worksheet where the alert resides (public).
Default is private.

.PARAMETER Device
(Optional) The type of device the alert is formatted for. If no device is provided then the default device setting of the underlying view is used.
Valid values: desktop, phone, tablet.

.PARAMETER WorksheetName
The name of the worksheet that the DDA will be created on.

.PARAMETER ViewId
The LUID of the view that contains the data that can trigger an alert.
Either the ViewId or CustomViewId needs to be provided.

.PARAMETER CustomViewId
The LUID of the custom view that contains the data that can trigger an alert.
Either the ViewId or CustomViewId needs to be provided.

.EXAMPLE
$dataAlert = Add-TSDataAlert -Subject "Data Driven Alert for Forecast" -Condition above -Threshold 14000 -WorksheetName "one_measure_no_dimension" -ViewId $view.id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_data_driven_alert
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $Subject,
    [Parameter(Mandatory)][ValidateSet('above','above-equal','below','below-equal','equal')][string] $Condition,
    [Parameter(Mandatory)][int] $Threshold,
    [Parameter()][ValidateSet('once','freguently','hourly','daily','weekly')][string] $Frequency = 'once',
    [Parameter()][ValidateSet('private','public')][string] $Visibility = 'private',
    [Parameter()][ValidateSet('desktop','phone','tablet')][string] $Device,
    [Parameter(Mandatory)][string] $WorksheetName,
    [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
    [Parameter(Mandatory,ParameterSetName='CustomView')][string] $CustomViewId
)
    Assert-TSRestApiVersion -AtLeast 3.20
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_alert = $tsRequest.AppendChild($xml.CreateElement("dataAlertCreateAlert"))
    $el_alert.SetAttribute("alertCondition", $Condition)
    $el_alert.SetAttribute("alertThreshold", $Threshold)
    $el_alert.SetAttribute("subject", $Subject)
    $el_alert.SetAttribute("frequency", $Frequency)
    $el_alert.SetAttribute("visibility", $Visibility)
    if ($Device) {
        $el_alert.SetAttribute("device", $Device)
    }
    $el_alert.SetAttribute("worksheetName", $WorksheetName)
    if ($ViewId) {
        $el_alert.SetAttribute("viewId", $ViewId)
    } elseif ($CustomViewId) {
        $el_alert.SetAttribute("customViewId", $CustomViewId)
    }
    if ($PSCmdlet.ShouldProcess($Name)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.dataAlertCreateAlert
    }
}

function Update-TSDataAlert {
<#
.SYNOPSIS
Update Data-Driven Alert

.DESCRIPTION
Update one or more settings for the specified data-driven alert; including the alert subject, frequency, and owner.

.PARAMETER DataAlertId
The LUID of the data-driven alert.

.PARAMETER OwnerUserId
(Optional) The LUID of the user to assign as owner of the data-driven alert.

.PARAMETER Subject
(Optional) The string to set as the new subject of the alert.

.PARAMETER Frequency
(Optional) The frequency of the data-driven alert: once, frequently, hourly, daily, or weekly.

.PARAMETER Public
(Optional) Determines the visibility of the data-driven alert.
If the flag is true, users with access to the view containing the alert can see the alert and add themselves as recipients.
If the flag is false, then the alert is only visible to the owner, site or server administrators, and specific users they add as recipients.

.EXAMPLE
$dataAlert = Update-TSDataAlert -DataAlertId $id -Subject "New Alert for Forecast"

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_data-driven_alert
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DataAlertId,
    [Parameter()][string] $OwnerUserId,
    [Parameter()][string] $Subject,
    [Parameter()][ValidateSet('once','freguently','hourly','daily','weekly')][string] $Frequency,
    [Parameter()][ValidateSet('true','false')][string] $Public
)
    Assert-TSRestApiVersion -AtLeast 3.2
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_alert = $tsRequest.AppendChild($xml.CreateElement("dataAlert"))
    if ($Subject) {
        $el_alert.SetAttribute("subject", $Subject)
    }
    if ($Frequency) {
        $el_alert.SetAttribute("frequency", $Frequency)
    }
    if ($Public) {
        $el_alert.SetAttribute("public", $Public)
    }
    if ($OwnerUserId) {
        $el_owner = $el_alert.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $OwnerUserId)
    }
    if ($PSCmdlet.ShouldProcess($DataAlertId)) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert -Param $DataAlertId) -Body $xml.OuterXml -Method Put
        return $response.tsResponse.dataAlert
    }
}

function Remove-TSDataAlert {
<#
.SYNOPSIS
Delete Data-Driven Alert

.DESCRIPTION
Deletes the specified data-driven alert.

.PARAMETER DataAlertId
Parameter description

.EXAMPLE
Remove-TSDataAlert -DataAlertId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#delete_data-driven_alert
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DataAlertId
)
    Assert-TSRestApiVersion -AtLeast 3.2
    if ($PSCmdlet.ShouldProcess($DataAlertId)) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert -Param $DataAlertId) -Method Delete
    }
}

function Add-TSUserToDataAlert {
<#
.SYNOPSIS
Add User to Data-Driven Alert

.DESCRIPTION
Adds a specified user to the recipients list for a data-driven alert.

.PARAMETER DataAlertId
The LUID of the data-driven alert.

.PARAMETER UserId
The LUID of the user to add to the data-driven alert.

.EXAMPLE
Add-TSUserToDataAlert -DataAlertId $id -UserId (Get-TSCurrentUserId)

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#add_user_to_data-driven_alert
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DataAlertId,
    [Parameter(Mandatory)][string] $UserId
)
    Assert-TSRestApiVersion -AtLeast 3.2
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_user = $tsRequest.AppendChild($xml.CreateElement("user"))
    $el_user.SetAttribute("id", $UserId)
    if ($PSCmdlet.ShouldProcess("user:$UserId, data alert:$DataAlertId")) {
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert -Param $DataAlertId/users) -Body $xml.OuterXml -Method Post
        return $response.tsResponse.user
    }
}

function Remove-TSUserFromDataAlert {
<#
.SYNOPSIS
Delete User from Data-Driven Alert

.DESCRIPTION
Removes a specified user from the recipients list for a data-driven alert.

.PARAMETER DataAlertId
The LUID of the data-driven alert.

.PARAMETER UserId
The LUID of the user to remove from the data-driven alert.

.EXAMPLE
Remove-TSUserFromDataAlert -DataAlertId $id -UserId (Get-TSCurrentUserId)

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#delete_user_from_data-driven_alert
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
Param(
    [Parameter(Mandatory)][string] $DataAlertId,
    [Parameter(Mandatory)][string] $UserId
)
    Assert-TSRestApiVersion -AtLeast 3.2
    if ($PSCmdlet.ShouldProcess("user:$UserId, data alert:$DataAlertId")) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint DataAlert -Param $DataAlertId/users/$UserId) -Method Delete
    }
}

### Metadata methods
function Get-TSDatabase {
<#
.SYNOPSIS
Query Database / Query Databases

.DESCRIPTION
Get information about a database asset, or a list of database assets.

.PARAMETER DatabaseId
Query Database: The LUID of the database.

.PARAMETER PageSize
(Optional, Query Databases) Page size when paging through results.

.EXAMPLE
$databases = Get-TSDatabase

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_database

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_databases
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='DatabaseById')][string] $DatabaseId,
    [Parameter(ParameterSetName='Databases')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.5
    if ($DatabaseId) { # Query Database
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Database -Param $DatabaseId) -Method Get
        $response.tsResponse.database
    } else { # Query Databases
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Database
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.databases.database
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSTable {
<#
.SYNOPSIS
Query Table / Query Tables

.DESCRIPTION
Get information about a table asset, or a list of table assets.

.PARAMETER TableId
Query Table: The LUID of the table.

.PARAMETER PageSize
(Optional, Query Tables) Page size when paging through results.

.EXAMPLE
$tables = Get-TSTable

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_table

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_tables
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory,ParameterSetName='TableById')][string] $TableId,
    [Parameter(ParameterSetName='Tables')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.5
    if ($TableId) { # Query Table
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Table -Param $TableId) -Method Get
        $response.tsResponse.table
    } else { # Query Tables
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Table
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.tables.table
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSTableColumn {
<#
.SYNOPSIS
Query Column in a Table / Query Columns in a Table

.DESCRIPTION
Get information about a column in a table asset, or a list of column assets.

.PARAMETER TableId
The LUID of the table.

.PARAMETER ColumnId
Query Column in a Table: The LUID of the column.

.PARAMETER PageSize
(Optional, Query Columns in a Table) Page size when paging through results.

.EXAMPLE
$columns = Get-TSTableColumn -TableId $id

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_column

.LINK
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_columns
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $TableId,
    [Parameter(Mandatory,ParameterSetName='ColumnById')][string] $ColumnId,
    [Parameter(ParameterSetName='Columns')][ValidateRange(1,100)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.5
    if ($ColumnId) { # Query Column in a Table
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Table -Param $TableId/columns/$ColumnId) -Method Get
        $response.tsResponse.column
    } else { # Query Columns in a Table
        $pageNumber = 0
        do {
            $pageNumber++
            $uri = Get-TSRequestUri -Endpoint Table -Param $TableId/columns
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.columns.column
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    }
}

function Get-TSMetadataGraphQL {
<#
.SYNOPSIS
Run Metadata GraphQL query

.DESCRIPTION
Runs the specified GraphQL query through the Tableau Metadata API, including paginating of results.

.PARAMETER Query
The GraphQL query

.PARAMETER PaginatedEntity
If this parameter is provided: modifies the query to implement paginating through results.
Pagination in Tableau Metadata API is supported on entities ending with "Connection" (edges), such as fieldsConnection, workbooksConnection, etc.

.PARAMETER PageSize
(Optional, Query Columns in a Table) Page size when paging through results.

.EXAMPLE
$results = Get-TSMetadataGraphQL -Query (Get-Content "workbooks.graphql" | Out-String)

.LINK
https://help.tableau.com/current/api/metadata_api/en-us/index.html
#>
[OutputType([PSCustomObject[]])]
Param(
    [Parameter(Mandatory)][string] $Query,
    [Parameter()][string] $PaginatedEntity,
    [Parameter()][ValidateRange(1,20000)][int] $PageSize = 100
)
    Assert-TSRestApiVersion -AtLeast 3.5
    $uri = Get-TSRequestUri -Endpoint GraphQL
    if ($PaginatedEntity) { # run paginated (modified) query
        # $pageNumber = 0
        $nodesCount = 0
        $endCursor = $null
        $hasNextPage = $true
        while ($hasNextPage) {
            if ($endCursor) {
                $queryPage = $Query -replace $PaginatedEntity, "$PaginatedEntity(first: $PageSize, after: ""$endCursor"")"
            } else {
                $queryPage = $Query -replace $PaginatedEntity, "$PaginatedEntity(first: $PageSize)"
            }
            $jsonQuery = @{
                query = $queryPage
                # TODO variables = $null
            } | ConvertTo-Json
            $response = Invoke-TSRestApiMethod -Uri $uri -Body $jsonQuery -Method Post -ContentType 'application/json'
            $endCursor = $response.data.$PaginatedEntity.pageInfo.endCursor
            $hasNextPage = $response.data.$PaginatedEntity.pageInfo.hasNextPage
            $totalCount = $response.data.$PaginatedEntity.totalCount
            $nodesCount += $response.data.$PaginatedEntity.nodes.length
            $response.data.$PaginatedEntity.nodes
            if ($totalCount -gt 0) {
                $percentCompleted = [Math]::Round($nodesCount / $totalCount * 100)
                Write-Progress -Activity "Fetching metadata" -Status "$nodesCount / $totalCount entities retrieved ($percentCompleted%)" -PercentComplete $percentCompleted
            }
        }
        Write-Progress -Activity "Fetching metadata completed" -Completed
        if ($totalCount -and $nodesCount -ne $totalCount) {
            throw "Nodes count ($nodesCount) is not equal to totalCount ($totalCount), fetched results are incomplete."
        }
    } else { # run non-paginated (unmodified) query
        $jsonQuery = @{
            query = $Query
            # TODO variables = $null
        } | ConvertTo-Json
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $jsonQuery -Method Post -ContentType 'application/json'
        $entity = $response.data.PSObject.Properties | Select-Object -First 1 -ExpandProperty Name
        $response.data.$entity
    }
}
