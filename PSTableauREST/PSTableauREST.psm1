### Module variables and helper functions
$TSRestApiVersion = [version]'2.4' # minimum supported version
$TSRestApiMinVersion = [version]'2.4' # supported version for initial sign-in calls
$TSRestApiFileSizeLimit = 64*1048576 # 64MB
$TSRestApiChunkSize = 2*1048576 # 2MB or 5MB or 50MB

# Proxy function to call Tableau Server REST API with Invoke-RestMethod
function Invoke-TSRestApiMethod {
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
    [OutputType([string])]
    Param(
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group','Workbook','Datasource','View','Flow','FileUpload',
            'Recommendation','CustomView','Favorite','OrderFavorites','Schedule','ServerSchedule','Job','Task',
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

# Helper function for generating XML element "connectionCredentials"
function Add-TSCredentialsElement {
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

# Helper function for generating XML element "connections"
function Add-TSConnectionsElement {
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
# version mapping: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_versions.htm
# what's new here: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_whats_new.htm
function Assert-TSRestApiVersion {
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
    [OutputType([version])]
    Param()
    return $script:TSRestApiVersion
}

function Set-TSRestApiVersion {
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
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $ServerUrl,
        [Parameter()][string] $Username,
        [Parameter()][securestring] $SecurePassword,
        [Parameter()][string] $PersonalAccessTokenName,
        [Parameter()][securestring] $PersonalAccessTokenSecret,
        [Parameter()][string] $Site = "",
        [Parameter()][string] $ImpersonateUserId,
        [Parameter()][boolean] $UseServerVersion = $True
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
    [OutputType([PSCustomObject])]
    Param(
        [Parameter()][string] $Site = ""
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
        } else {
        Write-Warning "Currently not signed in."
    }
    return $response
}

function Revoke-TSServerAdminPAT {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param()
    Assert-TSRestApiVersion -AtLeast 3.10
    if ($PSCmdlet.ShouldProcess()) {
        Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param serverAdminAccessTokens) -Method Delete
    }
}

function Get-TSCurrentUserId {
    [OutputType([string])]
    Param()
    return $script:TSUserId
}

### Sites methods
function Get-TSSite {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory,ParameterSetName='CurrentSite')][switch] $Current,
        # Note: it's also possible to use ?key=contentUrl to get site, but also works only with current site
        # Note: it's also possible to use ?key=name to get site, but also works only with current site
        # thus it doesn't make much sense to implement these options
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $ContentUrl,
        [Parameter()][hashtable] $SiteParams
        # supported params: adminMode, userQuota, storageQuota, disableSubscriptions, subscribeOthersEnabled
        # revisionLimit, dataAccelerationMode
        # set_versioned_flow_attributes(flows_all, flows_edit, flows_schedule, parent_srv, site_element, site_item)
        # allowSubscriptionAttachments, guestAccessEnabled, cacheWarmupEnabled, commentingEnabled, revisionHistoryEnabled
        # extractEncryptionMode, requestAccessEnabled, runNowEnabled, tierCreatorCapacity, tierExplorerCapacity, tierViewerCapacity
        # dataAlertsEnabled, commentingMentionsEnabled, catalogObfuscationEnabled, flowAutoSaveEnabled, webExtractionEnabled
        # metricsContentTypeEnabled, notifySiteAdminsOnThrottle, authoringEnabled, customSubscriptionEmailEnabled, customSubscriptionEmail
        # customSubscriptionFooterEnabled, customSubscriptionFooter, askDataMode, namedSharingEnabled, mobileBiometricsEnabled
        # sheetImageEnabled, catalogingEnabled, derivedPermissionsEnabled, userVisibilityMode, useDefaultTimeZone, timeZone
        # autoSuspendRefreshEnabled, autoSuspendRefreshInactivityWindow
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $SiteId,
        [Parameter()][hashtable] $SiteParams
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    if ($SiteParams.Keys -contains 'adminMode' -and $SiteParams.Keys -contains 'userQuota' -and $SiteParams["adminMode"] -eq "ContentOnly") {
        Write-Error "You cannot set admin_mode to ContentOnly and also set a user quota" -Category InvalidArgument -ErrorAction Stop
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
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

### Projects methods
function Get-TSProject {
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
    [OutputType([PSCustomObject[]])]
    Param()
    Get-TSProject -Filter "name:eq:Default","topLevelProject:eq:true"
}

### Users and Groups methods
function Get-TSUser {
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
        if ($EphemeralUsersEnabled) {
            Assert-TSRestApiVersion -AtLeast 3.21
            $el_group.SetAttribute("ephemeralUsersEnabled", "true")
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
        $fileStream.Close()
    }
    # final Write-Progress update
    Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb / $totalSizeMb MB uploaded (100%)" -PercentComplete 100
    Start-Sleep -m 100
    Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb MB uploaded" -Completed
    return $uploadSessionId
}

### Workbooks methods
function Get-TSWorkbook {
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
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSWorkbook {
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
                $fileStream.Close()
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
    $el_workbook.SetAttribute("showTabs", $ShowTabs)
    if ($RecentlyViewed) {
        $el_workbook.SetAttribute("recentlyViewed", "true")
    }
    if ($EncryptExtracts) {
        $el_workbook.SetAttribute("encryptExtracts", "true")
    }
    if ($NewProjectId) {
        $el_project = $el_workbook.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $NewProjectId)
    }
    if ($NewOwnerId) {
        $el_owner = $el_workbook.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($EnableDataAcceleration) {
        Assert-TSRestApiVersion -AtLeast 3.16
        $el_dataaccel = $el_workbook.AppendChild($xml.CreateElement("dataAccelerationConfig"))
        $el_dataaccel.SetAttribute("accelerationEnabled", "true")
        if ($AccelerateNow) {
            $el_dataaccel.SetAttribute("accelerateNow", "true")
        }
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    if ($PSCmdlet.ShouldProcess($WorkbookId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.workbook
    }
}

function Update-TSWorkbookConnection {
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
    if ($EmbedPassword) {
        $el_connection.SetAttribute("embedPassword", "true")
    }
    if ($QueryTagging) {
        Assert-TSRestApiVersion -AtLeast 3.13
        $el_connection.SetAttribute("queryTaggingEnabled", "true")
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSWorkbook {
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
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter(Mandatory)][ValidateSet('pdf','powerpoint','image')][string] $Format,
        [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid','Unspecified')][string] $PageType = "A4",
        [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = "Portrait",
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId
    )
    Assert-TSRestApiVersion -AtLeast 2.8
    $xml = New-Object System.Xml.XmlDocument
    $xml.AppendChild($xml.CreateElement("tsRequest"))
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/refresh
    if ($PSCmdlet.ShouldProcess($WorkbookId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post -ContentType "text/xml"
        return $response.tsResponse.job
    }
}

### Datasources methods
function Get-TSDatasource {
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
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $DatasourceId
    )
    # Assert-TSRestApiVersion -AtLeast 2.3
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSDatasource {
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
                $fileStream.Close()
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
    if ($Certified) {
        $el_datasource.SetAttribute("isCertified", "true")
    }
    if ($CertificationNote) {
        $el_datasource.SetAttribute("certificationNote", $CertificationNote)
    }
    if ($EncryptExtracts) {
        $el_datasource.SetAttribute("encryptExtracts", "true")
    }
    if ($NewProjectId) {
        $el_project = $el_datasource.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $NewProjectId)
    }
    if ($NewOwnerId) {
        $el_owner = $el_datasource.AppendChild($xml.CreateElement("owner"))
        $el_owner.SetAttribute("id", $NewOwnerId)
    }
    if ($EnableAskData) {
        Assert-TSRestApiVersion -LessThan 3.12
        $el_askdata = $el_datasource.AppendChild($xml.CreateElement("askData"))
        $el_askdata.SetAttribute("enablement", "true")
    }
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
    if ($PSCmdlet.ShouldProcess($DatasourceId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.datasource
    }
}

function Update-TSDatasourceConnection {
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
    if ($EmbedPassword) {
        $el_connection.SetAttribute("embedPassword", "true")
    }
    if ($QueryTagging) {
        Assert-TSRestApiVersion -AtLeast 3.13
        $el_connection.SetAttribute("queryTaggingEnabled", "true")
    }
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSDatasource {
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $DatasourceId
    )
    Assert-TSRestApiVersion -AtLeast 2.8
    $xml = New-Object System.Xml.XmlDocument
    $xml.AppendChild($xml.CreateElement("tsRequest"))
    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/refresh
    if ($PSCmdlet.ShouldProcess($DatasourceId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Post -ContentType "text/xml"
        return $response.tsResponse.job
    }
}

### Views methods
# Get View by Path - use Get-TSView with filter viewUrlName:eq:<url>
function Get-TSView {
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
    if ($ViewId) { # Get View
        Assert-TSRestApiVersion -AtLeast 3.0
    }
    if ($ViewId) { # Get View
        $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId) -Method Get
        $response.tsResponse.view
    } elseif ($WorkbookId) { # Query Views for Workbook
        # Assert-TSRestApiVersion -AtLeast 2.0
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
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $ViewId,
        [Parameter(Mandatory)][ValidateSet('pdf','image','csv','excel')][string] $Format,
        [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid','Unspecified')][string] $PageType = "A4",
        [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = "Portrait",
        [Parameter()][int] $MaxAge, # The maximum number of minutes a view pdf/image/data/crosstab will be cached before being refreshed
        # The height/width of the rendered pdf image in pixels; these parameter determine its resolution and aspect ratio
        [Parameter()][int] $VizWidth,
        [Parameter()][int] $VizHeight,
        # The resolution of the image. Image width and actual pixel density are determined by the display context of the image.
        # Aspect ratio is always preserved. Set the value to high to ensure maximum pixel density.
        [Parameter()][ValidateSet('standard','high')][string] $Resolution = "high",
        [Parameter()][string] $OutFile,
        # https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#Filter-query-views
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
    [OutputType([PSCustomObject[]])]
    Param()
    Assert-TSRestApiVersion -AtLeast 3.7
    $uri = Get-TSRequestUri -Endpoint Recommendation -Param "?type=view"
    $response = Invoke-TSRestApiMethod -Uri $uri -Method Get
    return $response.tsResponse.recommendations.recommendation
}

function Hide-TSViewRecommendation {
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
    [OutputType([string])]
    Param(
        [Parameter(Mandatory)][string] $ViewId
    )
    Assert-TSRestApiVersion -AtLeast 3.7
    $uri = Get-TSRequestUri -Endpoint Recommendation -Param "dismissals/?type=view&id=$ViewId"
    Invoke-TSRestApiMethod -Uri $uri -Method Delete
}

function Get-TSCustomView {
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
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $FlowId
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections) -Method Get
    return $response.tsResponse.connections.connection
}

function Export-TSFlow {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $FlowId,
        [Parameter()][string] $OutFile,
        [Parameter()][int] $Revision # Note: flow revisions currently not supported via REST API
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
                $fileStream.Close()
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
    if ($EmbedPassword) {
        $el_connection.SetAttribute("embedPassword", "true")
    }
    $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections/$ConnectionId
    if ($PSCmdlet.ShouldProcess($ConnectionId)) {
        $response = Invoke-TSRestApiMethod -Uri $uri -Body $xml.OuterXml -Method Put
        return $response.tsResponse.connection
    }
}

function Remove-TSFlow {
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $FlowId,
        [Parameter()][ValidateSet('full','incremental')][string] $RunMode = "full",
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
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
        [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId,
        [Parameter(Mandatory,ParameterSetName='View')][string] $ViewId,
        [Parameter(Mandatory,ParameterSetName='Project')][string] $ProjectId,
        [Parameter(Mandatory,ParameterSetName='Flow')][string] $FlowId
    )
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
    } elseif ($ProjectId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
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
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_pm = $tsRequest.AppendChild($xml.CreateElement("permissions"))
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        # $el_pm.AppendChild($xml.CreateElement("workbook")).SetAttribute("id", $WorkbookId)
        $shouldProcessItem = "workbook:$WorkbookId"
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        # $el_pm.AppendChild($xml.CreateElement("datasource")).SetAttribute("id", $DatasourceId)
        $shouldProcessItem = "datasource:$DatasourceId"
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
        # $el_pm.AppendChild($xml.CreateElement("view")).SetAttribute("id", $ViewId)
        $shouldProcessItem = "view:$ViewId"
    } elseif ($ProjectId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
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
    $MainParam = @{}
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $shouldProcessItem = "workbook:$WorkbookId"
        $MainParam.Add("WorkbookId", $WorkbookId)
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $shouldProcessItem = "datasource:$DatasourceId"
        $MainParam.Add("DatasourceId", $DatasourceId)
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $shouldProcessItem = "view:$ViewId"
        $MainParam.Add("ViewId", $ViewId)
    } elseif ($ProjectId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
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
        [switch] $All # explicit switch parameter to remove all permissions
    )
    $MainParam = @{}
    if ($WorkbookId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
        $shouldProcessItem = "workbook:$WorkbookId"
        $MainParam.Add("WorkbookId", $WorkbookId)
    } elseif ($DatasourceId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
        $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
        $shouldProcessItem = "datasource:$DatasourceId"
        $MainParam.Add("DatasourceId", $DatasourceId)
    } elseif ($ViewId) {
        Assert-TSRestApiVersion -AtLeast 3.2
        $uri = Get-TSRequestUri -Endpoint View -Param $ViewId
        $shouldProcessItem = "view:$ViewId"
        $MainParam.Add("ViewId", $ViewId)
    } elseif ($ProjectId) {
        # Assert-TSRestApiVersion -AtLeast 2.0
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
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
        [switch] $All # explicit switch parameter to remove all default permissions
    )
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
    } elseif ($All) { # Remove all default permissions for all grantees
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][ValidateSet('Extract','Subscription','Flow','DataAcceleration')][string] $Type,
        [Parameter()][ValidateRange(1,100)][int] $Priority = 50,
        [Parameter()][ValidateSet('Parallel','Serial')][string] $ExecutionOrder = "Parallel",
        [Parameter(Mandatory,ParameterSetName='HourlyHours')]
        [Parameter(Mandatory,ParameterSetName='HourlyMinutes')]
        [Parameter(Mandatory,ParameterSetName='Daily')]
        [Parameter(Mandatory,ParameterSetName='Weekly')]
        [Parameter(Mandatory,ParameterSetName='Monthly')]
        [ValidateSet('Hourly','Daily','Weekly','Monthly')][string] $Frequency = "Daily",
        [Parameter(Mandatory,ParameterSetName='HourlyHours')]
        [Parameter(Mandatory,ParameterSetName='HourlyMinutes')]
        [Parameter(Mandatory,ParameterSetName='Daily')]
        [Parameter(Mandatory,ParameterSetName='Weekly')]
        [Parameter(Mandatory,ParameterSetName='Monthly')]
        [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $StartTime = "00:00:00",
        [Parameter(ParameterSetName='HourlyHours')]
        [Parameter(ParameterSetName='HourlyMinutes')]
        [ValidatePattern('^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$')][string] $EndTime,
        [Parameter(Mandatory,ParameterSetName='HourlyHours')][ValidateSet(1,2,4,6,8,12)][int] $IntervalHours,
        [Parameter(Mandatory,ParameterSetName='HourlyMinutes')][ValidateSet(15,30)][int] $IntervalMinutes,
        [Parameter(Mandatory,ParameterSetName='Weekly')][ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string[]] $IntervalWeekdays,
        [Parameter(Mandatory,ParameterSetName='Monthly')][ValidateRange(0,31)][int] $IntervalMonthday # 0 for last day
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
        return $response.tsResponse.task.extractRefresh
    }
}

# note: return objects are different for two use cases
function Get-TSJob {
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

function Get-TSTask {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][ValidateSet('ExtractRefresh','FlowRun','Linked','DataAcceleration')][string] $Type,
        [Parameter(Mandatory,ParameterSetName='TaskById')][string] $TaskId,
        [Parameter(ParameterSetName='Tasks')][ValidateRange(1,100)][int] $PageSize = 100
    )
    if ($TaskId) { # Get Flow Run Task / Get Extract Refresh Task / Get Linked Task
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
    } else { # Get Flow Run Tasks / List Extract Refresh Tasks in Site / Get Linked Tasks
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
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param extractRefreshes/$TaskId/runNow) -Method Post
                return $response.tsResponse.job
            }
            'FlowRun' { # Run Flow Task
                Assert-TSRestApiVersion -AtLeast 3.3
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param flowRun/$TaskId/runNow) -Method Post
                return $response.tsResponse.job
            }
            'Linked' { # Run Linked Task Now
                Assert-TSRestApiVersion -AtLeast 3.15
                $response = Invoke-TSRestApiMethod -Uri (Get-TSRequestUri -Endpoint Task -Param linked/$TaskId/runNow) -Method Post
                return $response.tsResponse.linkedTaskJob
            }
        }
    }
}

### Extract and Encryption methods
function Get-TSExtractRefreshTasksInSchedule {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $ScheduleId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # List Extract Refresh Tasks in Server Schedule
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
# Create an Extract for a Data Source
# Delete the Extract from a Data Source
# Create Extracts for Embedded Data Sources in a Workbook
# Delete Extracts of Embedded Data Sources from a Workbook

function Add-TSExtractsInContent {
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
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory,ParameterSetName='Workbook')][string] $WorkbookId,
        [Parameter(Mandatory,ParameterSetName='Datasource')][string] $DatasourceId
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
    $uri += "/deleteExtract"
    if ($PSCmdlet.ShouldProcess($shouldProcessItem)) {
        Invoke-TSRestApiMethod -Uri $uri -Method Post
    }
}


### Favorites methods
function Get-TSUserFavorite {
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

### Metadata methods
function Get-TSDatabase {
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
            $percentCompleted = [Math]::Round($nodesCount / $totalCount * 100)
            Write-Progress -Activity "Fetching metadata" -Status "$nodesCount / $totalCount entities retrieved ($percentCompleted%)" -PercentComplete $percentCompleted
        }
        Write-Progress -Activity "Fetching metadata completed" -Completed
        if ($nodesCount -ne $totalCount) {
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
