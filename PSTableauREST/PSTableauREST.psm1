# Legacy code
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

### Module variables and helper functions
$TSRestApiVersion = [version]'2.4' # minimum supported version
$TSRestApiMinVersion = [version]'2.4' # supported version for initial sign-in calls
$TSRestApiFileSizeLimit = 64*1048576 # 64MB
$TSRestApiChunkSize = 2*1048576 # 2MB or 5MB or 50MB

# set up headers IDictionary with auth token (and optionally other headers)
function Get-TSRequestHeaderDict {
    [OutputType([System.Collections.Generic.Dictionary[string,string]])]
    Param(
        [Parameter()][string] $ContentType
    )
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    if ($script:TSAuthToken) {
        $headers.Add("X-Tableau-Auth", $script:TSAuthToken)
    }
    if ($ContentType) {
        $headers.Add("Content-Type", $ContentType)
    }
    return $headers
}

function Get-TSRequestUri {
    [OutputType([string])]
    Param(
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group','Workbook','Datasource','View','Flow','FileUpload','Favorite','OrderFavorites','Database','Table','GraphQL')][string] $Endpoint,
        [Parameter()][string] $Param
    )
    $Uri = "$script:TSServerUrl/api/$script:TSRestApiVersion/"
    switch($Endpoint) {
        "Auth" { $Uri += "auth/$Param" }
        "GraphQL" {
            $Uri = "$script:TSServerUrl/api/metadata/graphql"
        }
        "Site" {
            $Uri += "sites"
            if ($Param) { $Uri += "/$Param" }
        }
        "FileUpload" {
            $Uri += "sites/$script:TSSiteId/fileUploads"
            if ($Param) { $Uri += "/$Param" }
        }
        "OrderFavorites" {
            $Uri += "sites/$script:TSSiteId/orderFavorites"
            if ($Param) { $Uri += "/$Param" }
        }
        default {
            $Uri += "sites/$script:TSSiteId/" + $Endpoint.ToLower() + "s" # User -> users, etc.
            if ($Param) { $Uri += "/$Param" }
        }
    }
    return $Uri
}

### Helper functions for generating XML requests
function Add-TSCredentialsElement {
    [OutputType()]
    Param(
        [Parameter(Mandatory)][xml] $Element,
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
    [OutputType()]
    Param(
        [Parameter(Mandatory)][xml] $Element,
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
        } elseif ($connection["username"] -and $connection["password"]) {
            Add-TSCredentialsElement -Element $el_connection -Credentials @{
                username = $connection["username"]
                password = $connection["password"]
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
        throw "Method or Parameter not supported, needs API version >= $AtLeast"
    }
    if ($LessThan -and $script:TSRestApiVersion -ge $LessThan) {
        throw "Method or Parameter not supported, needs API version < $LessThan"
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
    try {
        if (-Not $ServerUrl) {
            $ServerUrl = $script:TSServerUrl
        }
        $apiVersion = $script:TSRestApiMinVersion
        if ($script:TSRestApiVersion) {
            $apiVersion = $script:TSRestApiVersion
        }
        $response = Invoke-RestMethod -Uri $ServerUrl/api/$apiVersion/serverinfo -Method Get
        return $response.tsResponse.serverInfo
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
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
        # if ($ImpersonateUserId) { Assert-TSRestApiVersion -AtLeast 2.0 }
    } else {
        Write-Error "Sign-in parameters not provided (needs either username/password or PAT)."
        return $null
    }
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param signin) -Body $xml.OuterXml -Method Post
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response.tsResponse.credentials
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
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
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param switchSite) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response.tsResponse.credentials
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Close-TSSignOut {
    [OutputType([PSCustomObject])]
    Param()
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $response = $Null
        if ($Null -ne $script:TSServerUrl -and $Null -ne $script:TSAuthToken) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param signout) -Method Post -Headers (Get-TSRequestHeaderDict)
            $script:TSServerUrl = $Null
            $script:TSAuthToken = $Null
            $script:TSSiteId = $Null
            $script:TSUserId = $Null
            } else {
            Write-Warning "Currently not signed in."
        }
        return $response
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Revoke-TSServerAdminPAT {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param()
    Assert-TSRestApiVersion -AtLeast 3.10
    try {
        if ($PSCmdlet.ShouldProcess()) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param serverAdminAccessTokens) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
        [Parameter()][switch] $Current,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($Current) { # get single (current) site
            $uri = Get-TSRequestUri -Endpoint Site -Param $script:TSSiteId
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.site
        } else { # get all sites
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Site
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.sites.site
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
        Write-Error "You cannot set admin_mode to ContentOnly and also set a user quota."
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("name", $Name)
    $el_site.SetAttribute("contentUrl", $ContentUrl)
    foreach ($param in $SiteParams.Keys) {
        $el_site.SetAttribute($param, $SiteParams[$param])
    }
    try {
        if ($PSCmdlet.ShouldProcess($Name)) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Site) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.site
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
        Write-Error "You cannot set admin_mode to ContentOnly and also set a user quota."
    }
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    foreach ($param in $SiteParams.Keys) {
        $el_site.SetAttribute($param, $SiteParams[$param])
    }
    try {
        if ($PSCmdlet.ShouldProcess($SiteId)) {
            if ($SiteId -eq $script:TSSiteId) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.site
            } else {
                Write-Error "You can only update the site for which you are currently authenticated."
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($SiteId)) {
            if ($SiteId -eq $script:TSSiteId) {
                $uri = Get-TSRequestUri -Endpoint Site -Param $SiteId
                if ($BackgroundTask) {
                    Assert-TSRestApiVersion -AtLeast 3.18
                    $uri += "?asJob=true"
                }
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            } else {
                Write-Error "You can only remove the site for which you are currently authenticated."
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
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
            $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.projects.project
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Add-TSProject {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $Description,
        [Parameter()][ValidateSet('ManagedByOwner','LockedToProject','LockedToProjectWithoutNested')][string] $ContentPermissions,
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
    try {
        if ($PSCmdlet.ShouldProcess($Name)) {
            $uri = Get-TSRequestUri -Endpoint Project # -Param $ProjectId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.project
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($ProjectId)) {
            $uri = Get-TSRequestUri -Endpoint Project -Param $ProjectId
            if ($PublishSamples) {
                $uri += "?publishSamples=true"
            }
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.project
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Remove-TSProject {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $ProjectId
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($PSCmdlet.ShouldProcess($ProjectId)) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Project -Param $ProjectId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Users and Groups methods
function Get-TSUser {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $UserId,
        [Parameter()][string[]] $Filter,
        [Parameter()][string[]] $Sort,
        [Parameter()][string[]] $Fields,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($UserId) { # Query User On Site
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.user
        } else { # Get Users on Site
            $pageNumber = 0
            do {
                $pageNumber += 1
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
                $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.users.user
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($Name)) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.user
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($UserId)) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.user
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($UserId)) {
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId
            if ($MapAssetsToUserId) {
                $uri += "?mapAssetsTo=$MapAssetsToUserId"
            }
            Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
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
            $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.groups.group
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Add-TSGroup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $MinimumSiteRole,
        [Parameter()][string] $DomainName,
        [Parameter()][ValidateSet('onLogin','onSync')][string] $GrantLicenseMode,
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
    }
    try {
        if ($PSCmdlet.ShouldProcess($Name)) {
            $uri = Get-TSRequestUri -Endpoint Group
            if ($BackgroundTask) {
                $uri += "?asJob=true"
            }
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.group
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    }
    try {
        if ($PSCmdlet.ShouldProcess($UserId)) {
            $uri = Get-TSRequestUri -Endpoint Group -Param $GroupId
            if ($BackgroundTask) {
                $uri += "?asJob=true"
            }
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.group
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Remove-TSGroup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $GroupId
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($PSCmdlet.ShouldProcess($GroupId)) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess("user:$UserId, group:$GroupId")) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId/users) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.user
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess("user:$UserId, group:$GroupId")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId/users/$UserId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSUsersInGroup {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $GroupId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Group -Param $GroupId/users
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.users.user
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSGroupsForUser {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    Assert-TSRestApiVersion -AtLeast 3.7
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId/groups
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.groups.group
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Publishing methods
function Send-TSFileUpload {
    [OutputType([string])]
    Param(
        [Parameter(Mandatory)][string] $InFile,
        [Parameter()][string] $FileName = "file",
        [Parameter()][switch] $ShowProgress
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint FileUpload) -Method Post -Headers (Get-TSRequestHeaderDict)
        $uploadSessionId = $response.tsResponse.fileUpload.GetAttribute("uploadSessionId")
        $chunkNumber = 0
        $buffer = New-Object System.Byte[]($script:TSRestApiChunkSize)
        $fileStream = New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $byteReader = New-Object System.IO.BinaryReader($fileStream)
        # $totalChunks = [Math]::Ceiling($fileItem.Length / $script:TSRestApiChunkSize)
        $totalSizeMb = [Math]::Round($fileItem.Length / 1048576)
        $bytesUploaded = 0
        $startTime = Get-Date
        do {
            $chunkNumber += 1
            $boundaryString = (New-Guid).ToString("N")
            $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
            [void]$multipartContent.Headers.Remove("Content-Type")
            [void]$multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
            $stringContent = New-Object System.Net.Http.StringContent("", "text/xml")
            $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $stringContent.Headers.ContentDisposition.Name = "request_payload"
            $multipartContent.Add($stringContent)
            # read (next) chunk of the file into memory
            $bytesRead = $byteReader.Read($buffer, 0, $buffer.Length)
            $memoryStream = New-Object System.IO.MemoryStream($buffer, 0, $bytesRead)
            $fileContent = New-Object System.Net.Http.StreamContent($memoryStream)
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_file"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`"" # TODO check/escape filenames with special chars, e.g. using Uri.EscapeDataString()
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint FileUpload -Param $uploadSessionId) -Body $multipartContent -Method Put -Headers (Get-TSRequestHeaderDict)
            $bytesUploaded += $bytesRead
            $elapsedTime = $(Get-Date) - $startTime
            $remainingTime = $elapsedTime * ($fileItem.Length / $bytesUploaded - 1)
            if ($ShowProgress) {
                $uploadedSizeMb = [Math]::Round($bytesUploaded / 1048576)
                $percentCompleted = [Math]::Round($bytesUploaded / $fileItem.Length * 100)
                Write-Progress -Activity "Uploading file $FileName" -Status "$uploadedSizeMb / $totalSizeMb MB uploaded ($percentCompleted%)" -PercentComplete $percentCompleted -SecondsRemaining $remainingTime.TotalSeconds
            }
        } until ($script:TSRestApiChunkSize*$chunkNumber -ge $fileItem.Length)
        $fileStream.Close()
        if ($ShowProgress) {
            Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb / $totalSizeMb MB uploaded (100%)" -PercentComplete 100
			Start-Sleep -m 100
            Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb MB uploaded" -Completed
        }
        return $uploadSessionId
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Workbooks methods
function Get-TSWorkbook {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $WorkbookId,
        [Parameter()][switch] $Revisions,
        [Parameter()][string[]] $Filter,
        [Parameter()][string[]] $Sort,
        [Parameter()][string[]] $Fields,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($WorkbookId) {
            if ($Revisions) { # Get Workbook Revisions
                # Assert-TSRestApiVersion -AtLeast 2.3
                $pageNumber = 0
                do {
                    $pageNumber += 1
                    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/revisions
                    $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                    $totalAvailable = $response.tsResponse.pagination.totalAvailable
                    $response.tsResponse.revisions.revision
                } until ($PageSize*$pageNumber -ge $totalAvailable)
            } else { # Get Workbook
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId) -Method Get -Headers (Get-TSRequestHeaderDict)
                $response.tsResponse.workbook
            }
        } else { # Query Workbooks on Site
            $pageNumber = 0
            do {
                $pageNumber += 1
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
                $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.workbooks.workbook
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId/workbooks
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            if ($IsOwner) { $uri += "&ownedBy=true" }
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.workbooks.workbook
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSWorkbookConnection {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections) -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.connections.connection
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Export-TSWorkbook {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter()][string] $OutFile,
        [Parameter()][switch] $ExcludeExtract,
        [Parameter()][int] $Revision,
        [Parameter()][switch] $ShowProgress
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
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
}

function Publish-TSWorkbook {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $InFile,
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $FileName,
        [Parameter()][string] $FileType,
        # [Parameter()][string] $Description,
        [Parameter()][string] $ProjectId,
        [Parameter()][switch] $ShowTabs,
        [Parameter()][hashtable] $HideViews,
        [Parameter()][string] $ThumbnailsUserId,
        [Parameter()][switch] $Overwrite,
        [Parameter()][switch] $SkipConnectionCheck,
        [Parameter()][switch] $BackgroundTask,
        [Parameter()][switch] $Chunked,
        [Parameter()][hashtable] $Credentials,
        [Parameter()][hashtable[]] $Connections,
        # [Parameter()][switch] $EncryptExtracts,
        [Parameter()][switch] $ShowProgress
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    $boundaryString = (New-Guid).ToString("N")
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
    # if ($Description) {
    #     $el_workbook.SetAttribute("description", $Description)
    # }
    if ($ShowTabs) {
        $el_workbook.SetAttribute("showTabs", "true")
    }
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
    try {
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        [void]$multipartContent.Headers.Remove("Content-Type")
        [void]$multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, "text/xml")
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName -ShowProgress:$ShowProgress
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
        } else {
            $fileStream = New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_workbook"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
            $fileStream.Close()
        }
        return $response.tsResponse.workbook
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Update-TSWorkbook {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter()][string] $Name,
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
    if ($ShowTabs) {
        $el_workbook.SetAttribute("showTabs", "true")
    }
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
    try {
        if ($PSCmdlet.ShouldProcess($WorkbookId)) {
            $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.workbook
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
        $el_connection.SetAttribute("queryTaggingEnabled", "true")
    }
    try {
        if ($PSCmdlet.ShouldProcess($ConnectionId)) {
            $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/connections/$ConnectionId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.connection
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($Revision) { # Remove Workbook Revision
            # Assert-TSRestApiVersion -AtLeast 2.3
            if ($PSCmdlet.ShouldProcess("$WorkbookId, revision $Revision")) {
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/revisions/$Revision) -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } else { # Remove Workbook
            if ($PSCmdlet.ShouldProcess($WorkbookId)) {
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId) -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSWorkbookDowngradeInfo {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter(Mandatory)][version] $DowngradeVersion
    )
    Assert-TSRestApiVersion -AtLeast 3.5
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/downGradeInfo?productVersion=$DowngradeVersion) -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.downgradeInfo
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Export-TSWorkbookToFormat {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter(Mandatory)][ValidateSet('pdf','powerpoint','image')][string] $Format,
        [Parameter()][ValidateSet('A3','A4','A5','B4','B5','Executive','Folio','Ledger','Legal','Letter','Note','Quarto','Tabloid','Unspecified')][string] $PageType = "A4",
        [Parameter()][ValidateSet('Portrait','Landscape')][string] $PageOrientation = "Portrait",
        [Parameter()][int] $MaxAge, # The maximum number of minutes a workbook preview will be cached before being refreshed
        [Parameter()][string] $OutFile,
        [Parameter()][switch] $ShowProgress
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
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
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
    try {
        if ($PSCmdlet.ShouldProcess($WorkbookId)) {
            $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/refresh
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.job
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Datasources methods
function Get-TSDatasource {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $DatasourceId,
        [Parameter()][switch] $Revisions,
        [Parameter()][string[]] $Filter,
        [Parameter()][string[]] $Sort,
        [Parameter()][string[]] $Fields,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        if ($DatasourceId) {
            if ($Revisions) { # Get Data Source Revisions
                # Assert-TSRestApiVersion -AtLeast 2.3
                $pageNumber = 0
                do {
                    $pageNumber += 1
                    $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/revisions
                    $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                    $totalAvailable = $response.tsResponse.pagination.totalAvailable
                    $response.tsResponse.revisions.revision
                } until ($PageSize*$pageNumber -ge $totalAvailable)
            } else { # Query Data Source
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId) -Method Get -Headers (Get-TSRequestHeaderDict)
                $response.tsResponse.datasource
            }
        } else { # Query Data Sources
            $pageNumber = 0
            do {
                $pageNumber += 1
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
                $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.datasources.datasource
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSDatasourceConnection {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $DatasourceId
    )
    # Assert-TSRestApiVersion -AtLeast 2.3
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections) -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.connections.connection
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Export-TSDatasource {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $DatasourceId,
        [Parameter()][string] $OutFile,
        [Parameter()][switch] $ExcludeExtract,
        [Parameter()][int] $Revision,
        [Parameter()][switch] $ShowProgress
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
    # see also: https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
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
        [Parameter()][hashtable[]] $Connections,
        [Parameter()][switch] $ShowProgress
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    $boundaryString = (New-Guid).ToString("N")
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
    try {
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        [void]$multipartContent.Headers.Remove("Content-Type")
        [void]$multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, "text/xml")
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName -ShowProgress:$ShowProgress
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
            # write-error (new-object System.IO.StreamReader($multipartContent.ReadAsStream())).ReadToEnd()
        } else {
            $fileStream = New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_datasource"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
            $fileStream.Close()

            # alternative approach, to be tested for binary files
            # https://stackoverflow.com/questions/25075010/upload-multiple-files-from-powershell-script
            # possible solution: saving the request body in a file and using -InFile parameter for Invoke-RestMethod
            # https://hochwald.net/upload-file-powershell-invoke-restmethod/
            # $requestBody = (
            #     "--$boundaryString",
            #     "Content-Type: text/xml",
            #     "Content-Disposition: form-data; name=request_payload",
            #     "",
            #     $xml.OuterXml,
            #     "--$boundaryString",
            #     "Content-Type: application/octet-stream",
            #     "Content-Disposition: form-data; name=tableau_datasource; filename=""$FileName""",
            # should be: [System.Text.Encoding]::Default.GetString($buffer)
            #     "",
            #     (Get-Content $InFile -Raw),
            # should be: $FilenameUrlEncoded = [System.Net.WebUtility]::UrlEncode($FileName)
            #     "--$boundaryString--"
            # ) -join "`r`n"
            # Invoke-RestMethod -Uri $uri -Body $requestBody -Method Post -Headers (Get-TSRequestHeaderDict) -ContentType "multipart/mixed; boundary=$boundaryString"
        }
        return $response.tsResponse.datasource
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($DatasourceId)) {
            $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.datasource
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
        $el_connection.SetAttribute("queryTaggingEnabled", "true")
    }
    try {
        if ($PSCmdlet.ShouldProcess($ConnectionId)) {
            $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/connections/$ConnectionId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.connection
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($Revision) { # Remove Data Source Revision
            # Assert-TSRestApiVersion -AtLeast 2.3
            if ($PSCmdlet.ShouldProcess("$DatasourceId, revision $Revision")) {
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/revisions/$Revision) -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } else { # Remove Data Source
            if ($PSCmdlet.ShouldProcess($DatasourceId)) {
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId) -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($DatasourceId)) {
            $uri = Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/refresh
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.job
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Views methods
function Get-TSView {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $ViewId,
        [Parameter()][string] $WorkbookId,
        [Parameter()][switch] $IncludeUsageStatistics,
        [Parameter()][string[]] $Filter,
        [Parameter()][string[]] $Sort,
        [Parameter()][string[]] $Fields,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        if ($ViewId) { # Get View
            Assert-TSRestApiVersion -AtLeast 3.0
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.view
        } elseif ($WorkbookId) { # Query Views for Workbook
            # Assert-TSRestApiVersion -AtLeast 2.0
            $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/views
            if ($IncludeUsageStatistics) {
                $uri += "?includeUsageStatistics=true"
            }
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.views.view
        } else { # Query Views for Site
            # Assert-TSRestApiVersion -AtLeast 2.2
            $pageNumber = 0
            do {
                $pageNumber += 1
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
                $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.views.view
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Export-TSViewPreviewImage {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $ViewId,
        [Parameter(Mandatory)][string] $WorkbookId,
        [Parameter()][string] $OutFile,
        [Parameter()][switch] $ShowProgress
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/views/$ViewId/previewImage
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
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
        [Parameter()][hashtable] $ViewFilters,
        [Parameter()][switch] $ShowProgress
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
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Body $uriParam -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
}

### Flows methods
function Get-TSFlow {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $FlowId,
        # [Parameter()][switch] $Revisions, #TODO
        [Parameter()][switch] $OutputSteps,
        [Parameter()][string[]] $Filter,
        [Parameter()][string[]] $Sort,
        [Parameter()][string[]] $Fields,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    try {
        if ($FlowId) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Method Get -Headers (Get-TSRequestHeaderDict)
            if ($OutputSteps) { # Get Flow, return output steps
                $response.tsResponse.flowOutputSteps.flowOutputStep
            } else { # Get Flow
                $response.tsResponse.flow
            }
        } else { # Query Flows on Site
            $pageNumber = 0
            do {
                $pageNumber += 1
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
                $response = Invoke-RestMethod -Uri $uriRequest.Uri.OriginalString -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.flows.flow
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId/flows
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            if ($IsOwner) { $uri += "&ownedBy=true" }
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.flows.flow
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSFlowConnection {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $FlowId
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections) -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.connections.connection
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Export-TSFlow {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $FlowId,
        [Parameter()][string] $OutFile,
        # [Parameter()][int] $Revision #TODO
        [Parameter()][switch] $ShowProgress
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    $OutFileParam = @{}
    if ($OutFile) {
        $OutFileParam.Add("OutFile", $OutFile)
    }
    $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/content
    $prevProgressPreference = $global:ProgressPreference
    try {
        if ($ShowProgress) {
            $global:ProgressPreference = 'Continue'
        } else {
            $global:ProgressPreference = 'SilentlyContinue'
        }
        Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict) -TimeoutSec 600 @OutFileParam
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    } finally {
        $global:ProgressPreference = $prevProgressPreference
    }
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
        [Parameter()][hashtable] $Credentials,
        [Parameter()][hashtable[]] $Connections,
        [Parameter()][switch] $ShowProgress
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    $boundaryString = (New-Guid).ToString("N")
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
    if ($Credentials) {
        Add-TSCredentialsElement -Element $el_flow -Credentials $Credentials
    }
    if ($Connections) {
        Add-TSConnectionsElement -Element $el_flow -Connections $Connections
    }
    if ($ProjectId) {
        $el_project = $el_flow.AppendChild($xml.CreateElement("project"))
        $el_project.SetAttribute("id", $ProjectId)
    }
    try {
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent($boundaryString)
        [void]$multipartContent.Headers.Remove("Content-Type")
        [void]$multipartContent.Headers.TryAddWithoutValidation("Content-Type", "multipart/mixed; boundary=$boundaryString")
        $stringContent = New-Object System.Net.Http.StringContent($xml.OuterXml, "text/xml")
        $stringContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
        $stringContent.Headers.ContentDisposition.Name = "request_payload"
        $multipartContent.Add($stringContent)
        if ($Chunked) {
            $uploadSessionId = Send-TSFileUpload -InFile $InFile -FileName $FileName -ShowProgress:$ShowProgress
            $uri += "&uploadSessionId=$uploadSessionId"
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
        } else {
            $fileStream = New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_flow"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`""
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
            $fileStream.Close()
        }
        return $response.tsResponse.flow
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
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
    try {
        if ($PSCmdlet.ShouldProcess($FlowId)) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.flow
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess($ConnectionId)) {
            $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/connections/$ConnectionId
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.connection
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Remove-TSFlow {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $FlowId
        # [Parameter()][int] $Revision #TODO
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    try {
        if ($PSCmdlet.ShouldProcess($FlowId)) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Start-TSFlowNow {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)][string] $FlowId,
        [Parameter()][ValidateSet('full','incremental')][string] $RunMode = "full", # TODO test
        [Parameter()][string] $OutputStepId, # TODO test
        [Parameter()][hashtable] $FlowParams # TODO test
    )
    Assert-TSRestApiVersion -AtLeast 3.3
    $xml = New-Object System.Xml.XmlDocument
    $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_flow = $tsRequest.AppendChild($xml.CreateElement("flowRunSpec"))
    $el_flow.SetAttribute("flowId", $FlowId)
    $el_flow.SetAttribute("runMode", $RunMode)
    if ($OutputStepId) {
        $el_steps = $el_flow.AppendChild($xml.CreateElement("flowOutputSteps"))
        $el_step = $el_steps.AppendChild($xml.CreateElement("flowOutputStep"))
        $el_step.SetAttribute("id", $OutputStepId)
    }
    if ($FlowParams) {
        $el_params = $el_flow.AppendChild($xml.CreateElement("flowParameterSpecs"))
        $FlowParams.GetEnumerator() | ForEach-Object {
            $el_param = $el_params.AppendChild($xml.CreateElement("flowParameterSpec"))
            $el_param.SetAttribute("parameterId", $_.Key)
            $el_param.SetAttribute("overrideValue", $_.Value)
        }
    }
    try {
        if ($PSCmdlet.ShouldProcess($FlowId)) {
            $uri = Get-TSRequestUri -Endpoint Flow -Param $FlowId/run
            $response = Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.job
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($WorkbookId -and $PSCmdlet.ShouldProcess("workbook:$WorkbookId, tags:"+($Tags -join ' '))) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/tags) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.tags.tag
        } elseif ($DatasourceId -and $PSCmdlet.ShouldProcess("datasource:$DatasourceId, tags:"+($Tags -join ' '))) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/tags) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.tags.tag
        } elseif ($ViewId -and $PSCmdlet.ShouldProcess("view:$ViewId, tags:"+($Tags -join ' '))) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId/tags) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.tags.tag
        } elseif ($FlowId -and $PSCmdlet.ShouldProcess("flow:$FlowId, tags:"+($Tags -join ' '))) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/tags) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            return $response.tsResponse.tags.tag
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($WorkbookId -and $PSCmdlet.ShouldProcess("workbook:$WorkbookId, tag:$Tag")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId/tags/$Tag) -Method Delete -Headers (Get-TSRequestHeaderDict)
        } elseif ($DatasourceId -and $PSCmdlet.ShouldProcess("datasource:$DatasourceId, tag:$Tag")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId/tags/$Tag) -Method Delete -Headers (Get-TSRequestHeaderDict)
        } elseif ($ViewId -and $PSCmdlet.ShouldProcess("view:$ViewId, tag:$Tag")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint View -Param $ViewId/tags/$Tag) -Method Delete -Headers (Get-TSRequestHeaderDict)
        } elseif ($FlowId -and $PSCmdlet.ShouldProcess("flow:$FlowId, tag:$Tag")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Flow -Param $FlowId/tags/$Tag) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Favorites methods
function Get-TSUserFavorite {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        Assert-TSRestApiVersion -AtLeast 2.5
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.favorites.favorite
        } until ($PageSize*$pageNumber -ge $totalAvailable)
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
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
    try {
        if ($WorkbookId) {
            # Assert-TSRestApiVersion -AtLeast 2.0
            $el_favorite.AppendChild($xml.CreateElement("workbook")).SetAttribute("id", $WorkbookId)
            if ($Label) {
                $el_favorite.SetAttribute("label", $Label)
            } else {
                $el_favorite.SetAttribute("label", $WorkbookId)
            }
            if ($PSCmdlet.ShouldProcess("user:$UserId, workbook:$WorkbookId")) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.favorites.favorite
            }
        } elseif ($DatasourceId) {
            # Assert-TSRestApiVersion -AtLeast 2.3
            $el_favorite.AppendChild($xml.CreateElement("datasource")).SetAttribute("id", $DatasourceId)
            if ($Label) {
                $el_favorite.SetAttribute("label", $Label)
            } else {
                $el_favorite.SetAttribute("label", $DatasourceId)
            }
            if ($PSCmdlet.ShouldProcess("user:$UserId, datasource:$DatasourceId")) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.favorites.favorite
            }
        } elseif ($ViewId) {
            # Assert-TSRestApiVersion -AtLeast 2.0
            $el_favorite.AppendChild($xml.CreateElement("view")).SetAttribute("id", $ViewId)
            if ($Label) {
                $el_favorite.SetAttribute("label", $Label)
            } else {
                $el_favorite.SetAttribute("label", $ViewId)
            }
            if ($PSCmdlet.ShouldProcess("user:$UserId, view:$ViewId")) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.favorites.favorite
            }
        } elseif ($ProjectId) {
            Assert-TSRestApiVersion -AtLeast 3.1
            $el_favorite.AppendChild($xml.CreateElement("project")).SetAttribute("id", $ProjectId)
            if ($Label) {
                $el_favorite.SetAttribute("label", $Label)
            } else {
                $el_favorite.SetAttribute("label", $ProjectId)
            }
            if ($PSCmdlet.ShouldProcess("user:$UserId, project:$ProjectId")) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.favorites.favorite
            }
        } elseif ($FlowId) {
            Assert-TSRestApiVersion -AtLeast 3.3
            $el_favorite.AppendChild($xml.CreateElement("flow")).SetAttribute("id", $FlowId)
            if ($Label) {
                $el_favorite.SetAttribute("label", $Label)
            } else {
                $el_favorite.SetAttribute("label", $FlowId)
            }
            if ($PSCmdlet.ShouldProcess("user:$UserId, flow:$FlowId")) {
                $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Favorite -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
                return $response.tsResponse.favorites.favorite
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($WorkbookId) {
            # Assert-TSRestApiVersion -AtLeast 2.0
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/workbooks/$WorkbookId
            if ($PSCmdlet.ShouldProcess("user:$UserId, workbook:$WorkbookId")) {
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } elseif ($DatasourceId) {
            # Assert-TSRestApiVersion -AtLeast 2.3
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/datasources/$DatasourceId
            if ($PSCmdlet.ShouldProcess("user:$UserId, datasource:$DatasourceId")) {
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } elseif ($ViewId) {
            # Assert-TSRestApiVersion -AtLeast 2.0
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/views/$ViewId
            if ($PSCmdlet.ShouldProcess("user:$UserId, view:$ViewId")) {
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } elseif ($ProjectId) {
            Assert-TSRestApiVersion -AtLeast 3.1
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/projects/$ProjectId
            if ($PSCmdlet.ShouldProcess("user:$UserId, project:$ProjectId")) {
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        } elseif ($FlowId) {
            Assert-TSRestApiVersion -AtLeast 3.3
            $uri = Get-TSRequestUri -Endpoint Favorite -Param $UserId/flows/$FlowId
            if ($PSCmdlet.ShouldProcess("user:$UserId, flow:$FlowId")) {
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            }
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
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
    try {
        if ($PSCmdlet.ShouldProcess("user:$UserId, favorite($FavoriteType):$FavoriteId, after($AfterFavoriteType):$AfterFavoriteId")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint OrderFavorites -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

### Metadata methods
function Get-TSDatabase {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $DatabaseId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    Assert-TSRestApiVersion -AtLeast 3.5
    try {
        if ($DatabaseId) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Database -Param $DatabaseId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.database
        } else {
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Database
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.databases.database
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSTable {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $TableId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    Assert-TSRestApiVersion -AtLeast 3.5
    try {
        if ($TableId) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Table -Param $TableId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.table
        } else {
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Table
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.tables.table
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSTableColumn {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $TableId,
        [Parameter()][string] $ColumnId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    Assert-TSRestApiVersion -AtLeast 3.5
    try {
        if ($ColumnId) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Table -Param $TableId/columns/$ColumnId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.column
        } else {
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Table -Param $TableId/columns
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.columns.column
            } until ($PageSize*$pageNumber -ge $totalAvailable)
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

function Get-TSMetadataGraphQL {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $Query,
        [Parameter()][string] $PaginatedEntity,
        [Parameter()][ValidateRange(1,20000)][int] $PageSize = 100,
        [Parameter()][switch] $ShowProgress
    )
    Assert-TSRestApiVersion -AtLeast 3.5
    try {
        $uri = Get-TSRequestUri -Endpoint GraphQL
        if ($PaginatedEntity) {
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
                $response = Invoke-RestMethod -Uri $uri -Body $jsonQuery -Method Post -Headers (Get-TSRequestHeaderDict -ContentType 'application/json')
                $endCursor = $response.data.$PaginatedEntity.pageInfo.endCursor
                $hasNextPage = $response.data.$PaginatedEntity.pageInfo.hasNextPage
                $totalCount = $response.data.$PaginatedEntity.totalCount
                $nodesCount += $response.data.$PaginatedEntity.nodes.length
                $response.data.$PaginatedEntity.nodes
                if ($ShowProgress) {
                    $percentCompleted = [Math]::Round($nodesCount / $totalCount * 100)
                    Write-Progress -Activity "Fetching metadata" -Status "$nodesCount / $totalCount entities retrieved ($percentCompleted%)" -PercentComplete $percentCompleted
                }
            }
            if ($ShowProgress) {
                Write-Progress -Activity "Fetching metadata completed" -Completed
            }
            if ($nodesCount -ne $totalCount) {
                throw "Nodes count ($nodesCount) is not equal to totalCount ($totalCount), fetched results are incomplete."
            }
        } else {
            $jsonQuery = @{
                query = $Query
                # TODO variables = $null
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Body $jsonQuery -Method Post -Headers (Get-TSRequestHeaderDict -ContentType 'application/json')
            $entity = $response.data.PSObject.Properties | Select-Object -First 1 -ExpandProperty Name
            $response.data.$entity
        }
    } catch {
        Write-Error -Message ($_.Exception.Message + " " + $_.ErrorDetails.Message) -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
    }
}

# Export module members
### API version methods
Export-ModuleMember -Function Assert-TSRestApiVersion
Export-ModuleMember -Function Get-TSRestApiVersion
Export-ModuleMember -Function Set-TSRestApiVersion

### Authentication / Server methods
Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Open-TSSignIn
Export-ModuleMember -Function Switch-TSSite
Export-ModuleMember -Function Close-TSSignOut
Export-ModuleMember -Function Revoke-TSServerAdminPAT
Export-ModuleMember -Function Get-TSCurrentUserId
# Get Current Server Session
# Delete Server Session
# List Server Active Directory Domains
# Update Server Active Directory Domain

### Site methods
Export-ModuleMember -Function Get-TSSite
Export-ModuleMember -Function Add-TSSite
Export-ModuleMember -Function Update-TSSite
Export-ModuleMember -Function Remove-TSSite
# Get Recently Viewed for Site
# Get Data Acceleration Report for a Site
# Get Embedding Settings for a Site
# Update Embedding Settings for Site

### Projects methods
Export-ModuleMember -Function Get-TSProject
Export-ModuleMember -Function Add-TSProject
Export-ModuleMember -Function Update-TSProject
Export-ModuleMember -Function Remove-TSProject

### Users and Groups methods
Export-ModuleMember -Function Get-TSUser
Export-ModuleMember -Function Add-TSUser
Export-ModuleMember -Function Update-TSUser
Export-ModuleMember -Function Remove-TSUser
Export-ModuleMember -Function Get-TSGroup
Export-ModuleMember -Function Add-TSGroup
Export-ModuleMember -Function Update-TSGroup
Export-ModuleMember -Function Remove-TSGroup
Export-ModuleMember -Function Add-TSUserToGroup
Export-ModuleMember -Function Remove-TSUserFromGroup
Export-ModuleMember -Function Get-TSUsersInGroup
Export-ModuleMember -Function Get-TSGroupsForUser
# Import Users to Site from CSV - request body with multipart
# Delete Users from Site with CSV - request body with multipart

### Publishing methods
Export-ModuleMember -Function Send-TSFileUpload

### Workbooks methods
Export-ModuleMember -Function Get-TSWorkbook
Export-ModuleMember -Function Get-TSWorkbooksForUser
Export-ModuleMember -Function Get-TSWorkbookConnection
Export-ModuleMember -Function Export-TSWorkbook
Export-ModuleMember -Function Publish-TSWorkbook
Export-ModuleMember -Function Update-TSWorkbook
Export-ModuleMember -Function Update-TSWorkbookConnection
Export-ModuleMember -Function Remove-TSWorkbook
Export-ModuleMember -Function Get-TSWorkbookDowngradeInfo
Export-ModuleMember -Function Export-TSWorkbookToFormat
Export-ModuleMember -Function Update-TSWorkbookNow

### Datasources methods
Export-ModuleMember -Function Get-TSDatasource
Export-ModuleMember -Function Get-TSDatasourceConnection
Export-ModuleMember -Function Export-TSDatasource
Export-ModuleMember -Function Publish-TSDatasource
Export-ModuleMember -Function Update-TSDatasource
Export-ModuleMember -Function Update-TSDatasourceConnection
Export-ModuleMember -Function Remove-TSDatasource
Export-ModuleMember -Function Update-TSDatasourceNow
# Update Data in Hyper Connection - requires json body
# Update Data in Hyper Data Source - requires json body

### Views methods
Export-ModuleMember -Function Get-TSView
# Get View by Path - alias to using filter
Export-ModuleMember -Function Export-TSViewPreviewImage
Export-ModuleMember -Function Export-TSViewToFormat
# Get Recommendations for Views
# Hide a Recommendation for a View
# Unhide a Recommendation for a View
# List Custom Views
# Get Custom View
# Get Custom View Image
# Update Custom View
# Delete Custom View

### Flow methods
Export-ModuleMember -Function Get-TSFlow
Export-ModuleMember -Function Get-TSFlowsForUser
Export-ModuleMember -Function Get-TSFlowConnection
Export-ModuleMember -Function Export-TSFlow
Export-ModuleMember -Function Publish-TSFlow
Export-ModuleMember -Function Update-TSFlow
Export-ModuleMember -Function Update-TSFlowConnection
Export-ModuleMember -Function Remove-TSFlow
Export-ModuleMember -Function Start-TSFlowNow
# Get Flow Run Task
# Get Flow Run Tasks
# Get Flow Run
# Get Flow Runs
# Run Flow Task
# Get Linked Task
# Get Linked Tasks
# Run Linked Task Now
# Cancel Flow Run

### Permissions methods
# Query Default Permissions
# Query Workbook Permissions
# Query View Permissions
# Query Data Source Permissions
# Query Project Permissions
# Query Flow Permissions
# Add Default Permissions
# Add Workbook Permissions
# Add View Permissions
# Add Data Source Permissions
# Add Project Permissions
# Add Flow Permissions
# Delete Default Permission
# Delete Workbook Permission
# Delete View Permission
# Delete Data Source Permission
# Delete Project Permission
# Delete Flow Permission
# List Ask Data Lens Permissions
# Add Ask Data Lens Permissions
# Delete Ask Data Lens Permission

### Tags methods
Export-ModuleMember -Function Add-TSTagsToContent
Export-ModuleMember -Function Remove-TSTagFromContent

### Jobs, Tasks and Schedules methods
# List Server Schedules
# Get Server Schedule
# Create Server Schedule
# Update Server Schedule
# Delete Server Schedule
# Add Workbook to Server Schedule
# Add Data Source to Server Schedule
# Add Flow Task to Schedule
# Query Job
# Query Jobs
# Cancel Job
# Get Data Acceleration Tasks in a Site
# Delete Data Acceleration Task

### Extract and Encryption methods
# List Extract Refresh Tasks in Site
# List Extract Refresh Tasks in Server Schedule
# Get Extract Refresh Task
# Run Extract Refresh Task
# Delete Extract Refresh Task
# Encrypt Extracts in a Site
# Reencrypt Extracts in a Site
# Decrypt Extracts in a Site
# Create an Extract for a Data Source
# Delete the Extract from a Data Source
# Create Cloud Extract Refresh Task
# Update Cloud extract refresh task
# Create Extracts for Embedded Data Sources in a Workbook
# Delete Extracts of Embedded Data Sources from a Workbook

### Favorites methods
Export-ModuleMember -Function Get-TSUserFavorite
Export-ModuleMember -Function Add-TSUserFavorite
Export-ModuleMember -Function Remove-TSUserFavorite
Export-ModuleMember -Function Move-TSUserFavorite
# Add Metric to Favorites - Retired in API 3.22

### Subscription methods
# List Subscriptions
# Get Subscription
# Create Subscription
# Update Subscription
# Delete Subscription

### Dashboard Extensions Settings methods
# List settings for dashboard extensions on server
# List allowed dashboard extensions on site
# List blocked dashboard extensions on server
# List dashboard extension settings of site
# Update dashboard extensions settings of server
# Get allowed dashboard extension on site
# Get blocked dashboard extension on server
# Allow dashboard extension on site
# Disallow dashboard extension on site
# Block dashboard extension on server
# Unblock dashboard extension on server
# Update settings for allowed dashboard extension on site
# Update dashboard extension settings of site

### Analytics Extensions Settings methods
# List analytics extension connections on site
# Add analytics extension connection to site
# Update analytics extension connection of site
# Delete analytics extension connection from site
# Get enabled state of analytics extensions on site
# Update enabled state of analytics extensions on site
# Get enabled state of analytics extensions on server
# Enable or disable analytics extensions on server
# Get analytics extension details
# List analytics extension connections of workbook
# Get current analytics extension for workbook
# Update analytics extension for workbook
# Remove current analytics extension connection for workbook

### Connected App methods
# List Connected Apps
# Get Connected App
# Create Connected App
# Delete Connected App
# Update Connected App
# Get Connected App Secret
# Create Connected App Secret
# Delete Connected App Secret
# List All Registered EAS
# List Registered EAS
# Register EAS
# Update EAS
# Delete EAS

### Notifications methods
# List Webhooks
# Get a Webhook
# Create a Webhook
# Test a Webhook
# Update a Webhook
# Delete a Webhook
# List Data-Driven Alerts on Site
# Get Data-Driven Alert
# Create Data Driven Alert
# Update Data-Driven Alert
# Delete Data-Driven Alert
# Add User to Data-Driven Alert
# Delete User from Data-Driven Alert
# Get User Notification Preferences
# Update User Notification Preferences

### Content Exploration methods
# Get content Suggestions
# Get content search results
# Get batch content usage statistics
# Get usage statistics for content item

### Ask Data Lens methods
# List ask data lenses in site
# Get ask data lens
# Create ask data lens
# Import ask data lens
# Delete ask data lens

### Metrics methods
# List Metrics for Site
# Get Metric
# Get Metric Data
# Update Metric
# Delete Metric

### Identity Pools methods
# List Authentication Configurations
# Create Authentication Configuration
# Update Authentication Configuration
# Delete Authentication Configuration
# List Identity Pools
# Get Identity Pool
# Create Identity Pool
# Update Identity Pool
# Delete Identity Pool
# Add User to Identity Pool
# Remove User from Identity Pool
# List Identity Stores
# Configure Identity Store
# Delete Identity Store

### Virtual Connections methods
# List Virtual Connections
# List Virtual Connection Database Connections
# Update Virtual Connection Database Connections

### Metadata methods
Export-ModuleMember -Function Get-TSDatabase
Export-ModuleMember -Function Get-TSTable
Export-ModuleMember -Function Get-TSTableColumn
Export-ModuleMember -Function Get-TSMetadataGraphQL
# Query Data Quality Warning by ID
# Query Data Quality Warning by Content
# Query Data Quality Certification by ID
# Query Data Quality Certifications by Content
# Query Quality Warning Trigger
# Query All Quality Warning Triggers by Content
# Query Database Permissions
# Query Default Database Permissions
# Query Table Permissions
# Add Database Permissions
# Add Default Database Permissions
# Add Data Quality Warning
# Batch Add or Update Data Quality Warnings
# Batch Add or Update Data Quality Certifications
# Add (or Update) Quality Warning Trigger
# Add Table Permissions
# Add Tags to Column
# Add Tags to Database
# Add Tags to Table
# Batch Add Tags
# Create or Update labelValue
# Delete Database Permissions
# Delete Default Database Permissions
# Delete Data Quality Warning by ID
# Delete Data Quality Warning by Content
# Batch Delete Data Quality Warnings
# Delete Data Quality Certification by ID
# Delete Data Quality Certifications by Content
# Delete Quality Warning Trigger by ID
# Delete Quality Warning Triggers by Content
# Delete Label
# Delete Labels
# Delete labelValue
# Delete Table Permissions
# Delete Tag from Column
# Delete Tag from Database
# Delete Tag from Table
# Batch Delete Tags
# Get Label
# Get Labels
# Get labelValue
# Get Databases and Tables from Connection
# List labelValues on Site
# Move Database
# Move Table
# Remove Column
# Remove Database
# Remove Table
# Update Column
# Update Database
# Update Data Quality Warning
# Update Quality Warning Trigger
# Update Label
# Update Labels
# Update labelValue
# Update Table