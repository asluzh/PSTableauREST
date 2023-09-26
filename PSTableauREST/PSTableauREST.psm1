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
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group','Workbook','Datasource','View','FileUpload','Database','Table','GraphQL')][string] $Endpoint,
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
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Project
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
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
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
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
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    # Assert-TSRestApiVersion -AtLeast 2.0
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Group
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
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
        if ($PSCmdlet.ShouldProcess("add user $UserId into group $GroupId")) {
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
        if ($PSCmdlet.ShouldProcess("remove user $UserId from group $GroupId")) {
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

### Workbooks, Views and Datasources methods
function Get-TSWorkbook {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $WorkbookId,
        [Parameter()][switch] $Revisions,
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
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
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
            if ($IsOwner) { $uri += "&isOwner=true" }
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
    $fileItem = Get-Item $InFile
    if (-Not $FileName) {
        $FileName = $fileItem.Name
    }
    if (-Not $FileType) {
        $FileType = $fileItem.Extension.Substring(1)
    }
    if ($FileType -eq 'zip') {
        $FileType = 'twbx'
    } elseif ($FileType -eq 'xml') {
        $FileType = 'twb'
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
            $fileContent = New-Object System.Net.Http.StreamContent(New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open))
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_workbook"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`"" # TODO check/escape filenames with special chars, e.g. using Uri.EscapeDataString()
            # $fn = [System.Net.WebUtility]::UrlEncode($FileName)
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)
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

function Get-TSDatasource {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $DatasourceId,
        [Parameter()][switch] $Revisions,
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
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
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
    $fileItem = Get-Item $InFile
    if (-Not $FileName) {
        $FileName = $fileItem.Name
    }
    if (-Not $FileType) {
        $FileType = $fileItem.Extension.Substring(1)
    }
    if ($FileType -eq 'zip') {
        $FileType = 'tdsx'
    } elseif ($FileType -eq 'xml') {
        $FileType = 'tds'
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
            $fileContent = New-Object System.Net.Http.StreamContent(New-Object System.IO.FileStream($InFile, [System.IO.FileMode]::Open))
            $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
            $fileContent.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
            $fileContent.Headers.ContentDisposition.Name = "tableau_datasource"
            $fileContent.Headers.ContentDisposition.FileName = "`"$FileName`"" # TODO check/escape filenames with special chars, e.g. using Uri.EscapeDataString()
            # $fn = [System.Net.WebUtility]::UrlEncode($FileName)
            $multipartContent.Add($fileContent)
            $response = Invoke-RestMethod -Uri $uri -Body $multipartContent -Method Post -Headers (Get-TSRequestHeaderDict)

            # alternative approach, doesn't work yet for binary files
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
            #     "",
            #     (Get-Content $InFile -Raw),
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

# Publishing methods
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
            if ($ShowProgress) {
                $uploadedSizeMb = [Math]::Round($bytesUploaded / 1048576)
                $percentCompleted = [Math]::Round($bytesUploaded / $fileItem.Length * 100)
                Write-Progress -Activity "Uploading file $FileName" -Status "$uploadedSizeMb / $totalSizeMb MB uploaded ($percentCompleted%)" -PercentComplete $percentCompleted
            }
        } until ($script:TSRestApiChunkSize*$chunkNumber -ge $fileItem.Length)
        if ($ShowProgress) {
            Write-Progress -Activity "Uploading file $FileName" -Status "$totalSizeMb MB uploaded" -Completed
        }
        return $uploadSessionId
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
                    $queryPage = $Query -Replace $PaginatedEntity, "$PaginatedEntity(first: $PageSize, after: ""$endCursor"")"
                } else {
                    $queryPage = $Query -Replace $PaginatedEntity, "$PaginatedEntity(first: $PageSize)"
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
# Delete Server Session
# Get Current Server Session
# List Server Active Directory Domains
# Update Server Active Directory Domain

### Site methods
Export-ModuleMember -Function Get-TSSite
Export-ModuleMember -Function Add-TSSite
Export-ModuleMember -Function Update-TSSite
Export-ModuleMember -Function Remove-TSSite
# Get Data Acceleration Report for a Site
# Get Embedding Settings for a Site
# Get Recently Viewed for Site
# Query Views for Site
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
# Import Users to Site from CSV
# Delete Users from Site with CSV

### Workbooks, Views and Datasources methods
Export-ModuleMember -Function Get-TSWorkbook
Export-ModuleMember -Function Get-TSWorkbooksForUser
Export-ModuleMember -Function Get-TSWorkbookConnection
Export-ModuleMember -Function Export-TSWorkbook
Export-ModuleMember -Function Publish-TSWorkbook
Export-ModuleMember -Function Update-TSWorkbook
Export-ModuleMember -Function Update-TSWorkbookConnection
Export-ModuleMember -Function Remove-TSWorkbook
Export-ModuleMember -Function Get-TSDatasource
Export-ModuleMember -Function Get-TSDatasourceConnection
Export-ModuleMember -Function Export-TSDatasource
Export-ModuleMember -Function Publish-TSDatasource
Export-ModuleMember -Function Update-TSDatasource
Export-ModuleMember -Function Update-TSDatasourceConnection
Export-ModuleMember -Function Remove-TSDatasource
# Download View Crosstab Excel
# Download Workbook PDF
# Download Workbook PowerPoint
# Get View
# Get View by Path
# Get Recommendations for Views
# Get Workbook Downgrade Info
# Hide a Recommendation for a View
# Query Workbook Preview Image
# Query Views for Site
# Query Views for Workbook
# Query View Data
# Query View Image
# Query View PDF
# Query View Preview Image
# Unhide a Recommendation for a View
# Update Workbook Now
# Update Data Source Now
# Update Data in Hyper Connection
# Update Data in Hyper Data Source
# List Custom Views
# Get Custom View
# Get Custom View Image
# Update Custom View
# Delete Custom View
# Add Tags to View
# Add Tags to Workbook
# Add Tags to Data Source
# Delete Tag from View
# Delete Tag from Workbook
# Delete Tag from Data Source

### Permissions methods
# Add Ask Data Lens Permissions
# Add Data Source Permissions
# Add Default Permissions
# Add Project Permissions
# Add View Permissions
# Add Workbook Permissions
# Add Workbook to Server Schedule
# Delete Ask Data Lens Permission
# Delete Data Source Permission
# Delete Default Permission
# Delete Project Permission
# Delete View Permission
# Delete Workbook Permission
# List Ask Data Lens Permissions
# Query Data Source Permissions
# Query Default Permissions
# Query Project Permissions
# Query View Permissions
# Query Workbook Permissions

### Publishing methods
Export-ModuleMember -Function Send-TSFileUpload
# Publish Flow

### Jobs, Tasks and Schedules methods
# Add Data Source to Server Schedule
# Add Workbook to Server Schedule
# Cancel Job
# Create Server Schedule
# Delete Data Acceleration Task
# Delete Server Schedule
# Get Data Acceleration Tasks in a Site
# Get Server Schedule
# Query Job
# Query Jobs
# List Server Schedules
# Update Server Schedule

### Extract and Encryption methods
# Create Cloud Extract Refresh Task
# Create Extracts for Embedded Data Sources in a Workbook
# Create an Extract for a Data Source
# Decrypt Extracts in a Site
# Delete Extracts of Embedded Data Sources from a Workbook
# Delete the Extract from a Data Source
# Delete Extract Refresh Task
# Encrypt Extracts in a Site
# Get Extract Refresh Task
# List Extract Refresh Tasks in Site
# List Extract Refresh Tasks in Server Schedule
# Reencrypt Extracts in a Site
# Run Extract Refresh Task
# Update Cloud extract refresh task

### Flow methods
# Add Flow Permissions
# Add Flow Task to Schedule
# Cancel Flow Run
# Delete Flow
# Delete Flow Permission
# Download Flow
# Get Flow Run
# Get Flow Runs
# Get Flow Run Task
# Get Flow Run Tasks
# Get Linked Task
# Get Linked Tasks
# Publish Flow
# Query Flow
# Query Flows for a Site
# Query Flows for User
# Query Flow Connections
# Query Flow Permissions
# Run Flow Now
# Run Flow Task
# Run Linked Task Now
# Update Flow
# Update Flow Connection

### Favorites methods
# Add Data Source to Favorites
# Add Flow to Favorites
# Add Metric to Favorites
# Add Project to Favorites
# Add View to Favorites
# Add Workbook to Favorites
# Delete Data Source from Favorites
# Delete Flow from Favorites
# Delete Project from Favorites
# Delete View from Favorites
# Delete Workbook from Favorites
# Get Favorites for User
# Organize Favorites

### Subscription methods
# Create Subscription
# Delete Subscription
# Get Subscription
# List Subscriptions
# Update Subscription

### Dashboard Extensions Settings methods
# Block dashboard extension on server
# Allow dashboard extension on site
# Unblock dashboard extension on server
# Get blocked dashboard extension on server
# List blocked dashboard extensions on server
# List allowed dashboard extensions on site
# List settings for dashboard extensions on server
# Update dashboard extensions settings of server
# Disallow dashboard extension on site
# Get allowed dashboard extension on site
# List dashboard extension settings of site
# Update settings for allowed dashboard extension on site
# Update dashboard extension settings of site

### Analytics Extensions Settings methods
# Add analytics extension connection to site
# Delete analytics extension connection from site
# Remove current analytics extension connection for workbook
# Get analytics extension details
# List analytics extension connections on site
# Get enabled state of analytics extensions on server
# Get enabled state of analytics extensions on site
# List analytics extension connections of workbook
# Get current analytics extension for workbook
# Update analytics extension connection of site
# Enable or disable analytics extensions on server
# Update enabled state of analytics extensions on site
# Update analytics extension for workbook

### Connected App methods
# Create Connected App
# Register EAS
# Create Connected App Secret
# Delete Connected App
# Delete EAS
# Delete Connected App Secret
# Get Connected App
# List Connected Apps
# List All Registered EAS
# List Registered EAS
# Get Connected App Secret
# Update Connected App
# Update EAS

### Notifications methods
# Add User to Data-Driven Alert
# Create Data Driven Alert
# Create a Webhook
# Delete Data-Driven Alert
# Delete User from Data-Driven Alert
# Delete a Webhook
# Get User Notification Preferences
# Get a Webhook
# List Webhooks
# List Data-Driven Alerts on Site
# Get Data-Driven Alert
# Test a Webhook
# Update Data-Driven Alert
# Update User Notification Preferences
# Update a Webhook

### Content Exploration methods
# Get content Suggestions
# Get content search results
# Get batch content usage statistics
# Get usage statistics for content item

### Ask Data Lens methods
# Create ask data lens
# Delete ask data lens
# Get ask data lens
# Import ask data lens
# List ask data lenses in site

### Metrics methods
# Delete Metric
# Get Metric
# Get Metric Data
# List Metrics for Site
# Update Metric

### Identity Pools methods
# Add User to Identity Pool
# Delete Authentication Configuration
# Remove User from Identity Pool
# Delete Identity Pool
# Delete Identity Store
# Get Identity Pool
# List Authentication Configurations
# List Identity Pools
# List Identity Stores
# Create Authentication Configuration
# Create Identity Pool
# Configure Identity Store
# Update Authentication Configuration
# Update Identity Pool

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