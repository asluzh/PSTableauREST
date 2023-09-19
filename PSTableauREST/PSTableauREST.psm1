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
        [Parameter(Mandatory)][ValidateSet('Auth','Site','Project','User','Group')][string] $Endpoint,
        [Parameter()][string] $Param
    )
    $Uri = "$script:TSServerUrl/api/$script:TSRestApiVersion/"
    switch($Endpoint) {
        "Auth" { $Uri += "auth/$Param" }
        "Site" {
            $Uri += "sites"
            if ($Param) { $Uri += "/$Param" }
        }
        "Project" {
            $Uri += "sites/$script:TSSiteId/projects"
            if ($Param) { $Uri += "/$Param" }
        }
        "User" {
            $Uri += "sites/$script:TSSiteId/users"
            if ($Param) { $Uri += "/$Param" }
        }
        "Group" {
            $Uri += "sites/$script:TSSiteId/groups"
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
        [Parameter()][string] $ParentProjectId,
        [Parameter()][boolean] $PublishSamples
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
            # FIXME POST request with this uri returns 400 Bad RequestDeserialization problem: Content is not allowed in prolog.
            # if ($PublishSamples) {
            #     $uri += "?publishSamples=true"
            # }
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
        [Parameter()][boolean] $PublishSamples
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
            $uri = Get-TSRequestUri -Endpoint User
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
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
        [Parameter()][ValidateSet('Creator','Explorer','ExplorerCanPublish','ServerAdministrator','SiteAdministratorExplorer','SiteAdministratorCreator','Viewer','Unlicensed')][string] $SiteRole,
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
            $uri = Get-TSRequestUri -Endpoint User -Param $UserId
            Invoke-RestMethod -Uri $uri -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
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
            if ($PublishSMapAssetsToUserIdamples) {
                $uri += "?mapAssetsTo=$PublishSMapAssetsToUserIdamples"
            }
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint User -Param $UserId) -Method Delete -Headers (Get-TSRequestHeaderDict)
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
