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

# Module variables
$TSRestApiVersion = '2.4' # minimum supported version
$TSRestApiMinVersion = '2.4' # supported version for initial sign-in calls
#$TSRestApiChunkSize = 2097152	   ## 2MB or 2048KB

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
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group','Database','Table','GraphQL')][string] $Endpoint,
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
                    # variables = $null
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
                # variables = $null
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $uri -Body $jsonQuery -Method Post -Headers (Get-TSRequestHeaderDict -ContentType 'application/json')
            $response.data
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Invoke-TSSignIn
Export-ModuleMember -Function Invoke-TSSignOut
Export-ModuleMember -Function Invoke-TSSwitchSite

Export-ModuleMember -Function Get-TSSite
Export-ModuleMember -Function New-TSSite
Export-ModuleMember -Function Update-TSSite
Export-ModuleMember -Function Remove-TSSite
# Get Data Acceleration Report for a Site
# Get Embedding Settings for a Site
# Get Recently Viewed for Site
# Query Views for Site
# Update Embedding Settings for Site

Export-ModuleMember -Function Get-TSProject
Export-ModuleMember -Function New-TSProject
Export-ModuleMember -Function Update-TSProject
Export-ModuleMember -Function Remove-TSProject

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