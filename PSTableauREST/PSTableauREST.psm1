# Legacy code
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# $Source = @"
# using System.Net;
# public class ExtendedWebClient : WebClient
# {
# public int Timeout;
# public bool KeepAlive;
# protected override WebRequest GetWebRequest(System.Uri address)
# {
# HttpWebRequest request = (HttpWebRequest)base.GetWebRequest(address);
# if (request != null)
# {
# request.Timeout = Timeout;
# request.KeepAlive = KeepAlive;
# request.Proxy = null;
# }
# return request;
# }
# public ExtendedWebClient()
# {
# Timeout = 600000; // Timeout value by default
# KeepAlive = false;
# }
# }
# "@;
# Add-Type -TypeDefinition $Source -Language CSharp

### Module variables and helper functions
$TSRestApiVersion = '2.4' # minimum supported version
$TSRestApiMinVersion = '2.4' # supported version for initial sign-in calls
#$TSRestApiChunkSize = 2097152	   ## 2MB or 2048KB

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
    Param(
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group','Workbook','Datasource','View','Database','Table','GraphQL')][string] $Endpoint,
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
        "User" {
            $Uri += "sites/$script:TSSiteId/users"
            if ($Param) { $Uri += "/$Param" }
        }
        default {
            $Uri += "sites/$script:TSSiteId/" + $Endpoint.ToLower() + "s" # User -> users, etc.
            if ($Param) { $Uri += "/$Param" }
        }
    }
    return $Uri
}

### Authentication / Server methods
function Get-TSServerInfo {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter()][string] $ServerUrl
    )
    try {
        if ($ServerUrl) {
            $script:TSServerUrl = $ServerUrl
        }
        return Invoke-RestMethod -Uri $script:TSServerUrl/api/$script:TSRestApiMinVersion/serverinfo -Method Get
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Invoke-TSSignIn {
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

    $script:TSServerUrl = $ServerUrl
    $response = Get-TSServerInfo
    $script:TSProductVersion = $response.tsResponse.serverInfo.productVersion.InnerText
    $script:TSProductVersionBuild = $response.tsResponse.serverInfo.productVersion.build
    # $response.tsResponse.serverInfo.prepConductorVersion
    if ($UseServerVersion) {
        $script:TSRestApiVersion = $response.tsResponse.serverInfo.restApiVersion
    } else {
        $script:TSRestApiVersion = $script:TSRestApiMinVersion
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
        $private:PlainPassword = [System.Net.NetworkCredential]::new("", $SecurePassword).Password
        $el_credentials.SetAttribute("name", $Username)
        $el_credentials.SetAttribute("password", $private:PlainPassword)
    } elseif ($PersonalAccessTokenName -and $PersonalAccessTokenSecret) {
        $private:PlainSecret = [System.Net.NetworkCredential]::new("", $PersonalAccessTokenSecret).Password
        $el_credentials.SetAttribute("personalAccessTokenName", $PersonalAccessTokenName)
        $el_credentials.SetAttribute("personalAccessTokenSecret", $private:PlainSecret)
    } else {
        Write-Error -Exception "Sign-in parameters not provided (username/password or PAT)."
        return $null
    }

    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param signin) -Body $xml.OuterXml -Method Post
        # get the auth token, site id and my user id
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Invoke-TSSwitchSite {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter()][string] $Site = ""
    )
    # generate xml request
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("contentUrl", $Site)

    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param switchSite) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Invoke-TSSignOut {
    [OutputType([PSCustomObject])]
    Param()
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
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Revoke-TSServerAdminTokens {
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    try {
        if ($PSCmdlet.ShouldProcess()) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Auth -Param serverAdminAccessTokens) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSCurrentUserId {
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
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function New-TSSite {
    [CmdletBinding(SupportsShouldProcess)]
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
    if ($SiteParams.Keys -contains 'adminMode' -and $SiteParams.Keys -contains 'userQuota' -and $SiteParams["adminMode"] -eq "ContentOnly") {
        Write-Error -Exception "You cannot set admin_mode to ContentOnly and also set a user quota."
    }
    # generate xml request
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
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Site) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Update-TSSite {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $SiteId,
        [Parameter()][hashtable] $SiteParams
    )
    if ($SiteParams.Keys -contains 'adminMode' -and $SiteParams.Keys -contains 'userQuota' -and $SiteParams["adminMode"] -eq "ContentOnly") {
        Write-Error -Exception "You cannot set admin_mode to ContentOnly and also set a user quota."
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
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
            } else {
                Write-Error -Exception "You can only update the site for which you are currently authenticated."
            }
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Remove-TSSite {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $SiteId,
        [Parameter()][switch] $BackgroundTask
    )
    try {
        if ($PSCmdlet.ShouldProcess($SiteId)) {
            if ($SiteId -eq $script:TSSiteId) {
                $uri = Get-TSRequestUri -Endpoint Site -Param $SiteId
                if ($BackgroundTask) { # TODO check $script:TSRestApiVersion >= 3.18
                    $uri += "?asJob=true"
                }
                Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
            } else {
                Write-Error -Exception "You can only remove the site for which you are currently authenticated."
            }
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

### Projects methods
function Get-TSProject {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Project
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.projects.project
        } until ($PageSize*$pageNumber -gt $totalAvailable)
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function New-TSProject {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][string] $Description,
        [Parameter()][ValidateSet('ManagedByOwner','LockedToProject','LockedToProjectWithoutNested')][string] $ContentPermissions,
        [Parameter()][string] $ParentProjectId
    )
    # generate xml request
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
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Update-TSProject {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $ProjectId,
        [Parameter()][string] $Name,
        [Parameter()][string] $Description,
        [Parameter()][ValidateSet('ManagedByOwner','LockedToProject','LockedToProjectWithoutNested')][string] $ContentPermissions,
        [Parameter()][string] $ParentProjectId,
        [Parameter()][switch] $PublishSamples
    )
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
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Remove-TSProject {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $ProjectId
    )
    try {
        if ($PSCmdlet.ShouldProcess($ProjectId)) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Project -Param $ProjectId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

### Users and Groups methods
function Get-TSUser {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $UserId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
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
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function New-TSUser {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $SiteRole,
        [Parameter()][string] $AuthSetting
        )
    # generate xml request
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
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Update-TSUser {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][string] $FullName,
        [Parameter()][string] $Email,
        [Parameter()][securestring] $SecurePassword,
        [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $SiteRole,
        [Parameter()][string] $AuthSetting
    )
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
        $private:PlainPassword = [System.Net.NetworkCredential]::new("", $SecurePassword).Password
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
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Remove-TSUser {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][string] $MapAssetsToUserId
    )
    try {
        if ($PSCmdlet.ShouldProcess($UserId)) {
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId
            if ($PublishSMapAssetsToUserIdamples) {
                $uri += "?mapAssetsTo=$PublishSMapAssetsToUserIdamples"
            }
            Invoke-RestMethod -Uri $uri -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSGroup {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Group
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.groups.group
        } until ($PageSize*$pageNumber -gt $totalAvailable)
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function New-TSGroup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $MinimumSiteRole,
        [Parameter()][string] $DomainName,
        [Parameter()][ValidateSet('onLogin','onSync')][string] $GrantLicenseMode,
        [Parameter()][switch] $BackgroundTask
    )
    # generate xml request
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
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Update-TSGroup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $GroupId,
        [Parameter()][string] $Name,
        [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $MinimumSiteRole,
        [Parameter()][string] $DomainName,
        [Parameter()][ValidateSet('onLogin','onSync')][string] $GrantLicenseMode,
        [Parameter()][switch] $BackgroundTask
    )
    # generate xml request
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
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Remove-TSGroup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $GroupId
    )
    try {
        if ($PSCmdlet.ShouldProcess($GroupId)) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param $GroupId) -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Add-TSUserToGroup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter(Mandatory)][string] $GroupId
    )
    # generate xml request
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_user = $tsRequest.AppendChild($xml.CreateElement("user"))
    $el_user.SetAttribute("id", $UserId)
    try {
        if ($PSCmdlet.ShouldProcess("add user $UserId into group $GroupId")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param "$GroupId/users") -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Remove-TSUserFromGroup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter(Mandatory)][string] $GroupId
    )
    try {
        if ($PSCmdlet.ShouldProcess("remove user $UserId from group $GroupId")) {
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Group -Param "$GroupId/users/$UserId") -Method Delete -Headers (Get-TSRequestHeaderDict)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSUsersInGroup {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $GroupId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Group -Param "$GroupId/users"
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.users.user
        } until ($PageSize*$pageNumber -gt $totalAvailable)
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSGroupsForUser {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint User -Param "$UserId/groups"
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.groups.group
        } until ($PageSize*$pageNumber -gt $totalAvailable)
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

### Workbooks, Views and Datasources methods
function Get-TSWorkbook {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $WorkbookId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        if ($WorkbookId) { # Get Workbook
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param $WorkbookId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.workbook
        } else { # Query Workbooks on Site
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Workbook
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.workbooks.workbook
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSWorkbooksForUser {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $UserId,
        [Parameter()][switch] $IsOwner,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint User -Param "$UserId/workbooks"
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            if ($IsOwner) { $uri += "&isOwner=true" }
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.workbooks.workbook
        } until ($PageSize*$pageNumber -gt $totalAvailable)
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSWorkbookConnection {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $WorkbookId
    )
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Workbook -Param "$WorkbookId/connections") -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.connections.connection
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSDatasource {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $DatasourceId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        if ($DatasourceId) { # Query Data Source
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param $DatasourceId) -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.datasource
        } else { # Query Data Sources
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Datasource
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.datasources.datasource
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSDatasourceConnection {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $DatasourceId
    )
    try {
        $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Datasource -Param "$DatasourceId/connections") -Method Get -Headers (Get-TSRequestHeaderDict)
        $response.tsResponse.connections.connection
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

### Metadata methods
function Get-TSDatabase {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $DatabaseId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
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
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSTable {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][string] $TableId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
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
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSTableColumn {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $TableId,
        [Parameter()][string] $ColumnId,
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        if ($ColumnId) {
            $response = Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Table -Param "$TableId/columns/$ColumnId") -Method Get -Headers (Get-TSRequestHeaderDict)
            $response.tsResponse.column
        } else {
            $pageNumber = 0
            do {
                $pageNumber += 1
                $uri = Get-TSRequestUri -Endpoint Table -Param "$TableId/columns"
                $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
                $totalAvailable = $response.tsResponse.pagination.totalAvailable
                $response.tsResponse.columns.column
            } until ($PageSize*$pageNumber -gt $totalAvailable)
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Get-TSGraphQL {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter(Mandatory)][string] $Query,
        [Parameter()][string] $PaginatedEntity,
        [Parameter()][ValidateRange(1,20000)][int] $PageSize = 100
    )
    try {
        $uri = Get-TSRequestUri -Endpoint GraphQL
        if ($PaginatedEntity) {
            # $pageNumber = 0
            $nodesCount = 0
            $endCursor = $null
            $hasNextPage = $true
            while ($hasNextPage) {
                # $pageNumber += 1
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
                $response.data.$PaginatedEntity.nodes
                $nodesCount += $response.data.$PaginatedEntity.nodes.length
                # TODO add progress indicator
            }
            if ($nodesCount -ne $totalCount) {
                throw "Nodes count ($nodesCount) is not equal to totalCount ($totalCount)"
            }
        } else {
            $jsonQuery = @{
                query = $Query
                # TODO variables = $null
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Body $jsonQuery -Method Post -Headers (Get-TSRequestHeaderDict -ContentType 'application/json')
            $response.data
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

# Export module members
### Authentication / Server methods
Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Invoke-TSSignIn
Export-ModuleMember -Function Invoke-TSSwitchSite
Export-ModuleMember -Function Invoke-TSSignOut
Export-ModuleMember -Function Revoke-TSServerAdminTokens
Export-ModuleMember -Function Get-TSCurrentUserId
# Delete Server Session
# Get Current Server Session
# List Server Active Directory Domains
# Update Server Active Directory Domain

### Site methods
Export-ModuleMember -Function Get-TSSite
Export-ModuleMember -Function New-TSSite
Export-ModuleMember -Function Update-TSSite
Export-ModuleMember -Function Remove-TSSite
# Get Data Acceleration Report for a Site
# Get Embedding Settings for a Site
# Get Recently Viewed for Site
# Query Views for Site
# Update Embedding Settings for Site

### Projects methods
Export-ModuleMember -Function Get-TSProject
Export-ModuleMember -Function New-TSProject
Export-ModuleMember -Function Update-TSProject
Export-ModuleMember -Function Remove-TSProject

### Users and Groups methods
Export-ModuleMember -Function Get-TSUser
Export-ModuleMember -Function New-TSUser
Export-ModuleMember -Function Update-TSUser
Export-ModuleMember -Function Remove-TSUser
Export-ModuleMember -Function Get-TSGroup
Export-ModuleMember -Function New-TSGroup
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
Export-ModuleMember -Function Get-TSDatasource
Export-ModuleMember -Function Get-TSDatasourcesForUser
Export-ModuleMember -Function Get-TSDatasourceConnection
# Delete Workbook
# Delete Data Source
# Download View Crosstab Excel
# Download Workbook
# Download Data Source
# Download Workbook PDF
# Download Workbook PowerPoint
# Get View
# Get View by Path
# Get Recommendations for Views
# Get Workbook Downgrade Info
# Hide a Recommendation for a View
# Publish Workbook
# Publish Data Source
# Query Workbook Preview Image
# Query Views for Site
# Query Views for Workbook
# Query View Data
# Query View Image
# Query View PDF
# Query View Preview Image
# Unhide a Recommendation for a View
# Update Workbook
# Update Data Source
# Update Workbook Connection
# Update Data Source Connection
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

### Revision methods
# Get Workbook Revisions
# Get Data Source Revisions
# Download Workbook Revision
# Download Data Source Revision
# Remove Workbook Revision
# Remove Data Source Revision

### Publishing methods
# Append to File Upload
# Initiate File Upload
# Publish Data Source
# Publish Flow
# Publish Workbook

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
Export-ModuleMember -Function Get-TSGraphQL
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