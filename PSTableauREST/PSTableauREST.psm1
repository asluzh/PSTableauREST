# Module variables
$TSRestApiVersion = '2.4' # minimum supported version
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
        return Invoke-RestMethod -Uri $script:TSServerUrl/api/$script:TSRestApiVersion/serverinfo -Method Get
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
        [Parameter(Mandatory)][validateset('Auth','Project')][string] $Endpoint,
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
        [Parameter()][string] $PersonalAccessTokenSecret,
        [Parameter()][string] $Site = "",
        [Parameter()][boolean] $UseServerVersion = $True
    )

    $script:TSServerUrl = $ServerUrl
    $response = Get-TSServerInfo
    if ($UseServerVersion) {
        $script:TSRestApiVersion = $response.tsResponse.serverInfo.restApiVersion
        $script:TSProductVersion = $response.tsResponse.serverInfo.productVersion.InnerText
        $script:TSProductVersionBuild = $response.tsResponse.serverInfo.productVersion.build
    # $response.tsResponse.serverInfo.productVersion.build
    # $response.tsResponse.serverInfo.productVersion.#text
    # $response.tsResponse.serverInfo.prepConductorVersion
    }

    $xml = New-Object System.Xml.XmlDocument

    if ($Username -and $SecurePassword) {
        $Password = [System.Net.NetworkCredential]::new("", $SecurePassword).Password
        $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
        $el_credentials = $tsRequest.AppendChild($xml.CreateElement("credentials"))
        $el_site = $el_credentials.AppendChild($xml.CreateElement("site"))
        $el_credentials.SetAttribute("name", $Username)
        $el_credentials.SetAttribute("password", $Password)
        $el_site.SetAttribute("contentUrl", $Site)
    } elseif ($PersonalAccessTokenName -and $PersonalAccessTokenSecret) {
        $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
        $el_credentials = $tsRequest.AppendChild($xml.CreateElement("credentials"))
        $el_site = $el_credentials.AppendChild($xml.CreateElement("site"))
        $el_credentials.SetAttribute("personalAccessTokenName", $PersonalAccessTokenName)
        $el_credentials.SetAttribute("personalAccessTokenSecret", $PersonalAccessTokenSecret)
        $el_site.SetAttribute("contentUrl", $Site)
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
        [Parameter(Mandatory)][string] $Site
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

function Get-TSProject {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $PageSize = 100
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Project
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.Projects.project
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
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Project) -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaderDict)
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
        [Parameter()][string] $ParentProjectId
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
            Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Project -Param $ProjectId) -Body $xml.OuterXml -Method Put -Headers (Get-TSRequestHeaderDict)
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

function Get-TSSite {
    [OutputType([PSCustomObject[]])]
    Param(
        [Parameter()][ValidateRange(1,100)][int] $PageSize = 100
    )
    try {
        $PageSize = 100
        $pageNumber = 0
        do {
            $pageNumber += 1
            $uri = Get-TSRequestUri -Endpoint Site
            $uri += "?pageSize=$PageSize" + "&pageNumber=$pageNumber"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers (Get-TSRequestHeaderDict)
            $totalAvailable = $response.tsResponse.pagination.totalAvailable
            $response.tsResponse.Sites.site
        } until ($PageSize*$pageNumber -gt $totalAvailable)
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
        [Parameter(Mandatory)][string] $SiteId
    )
    try {
        if ($PSCmdlet.ShouldProcess($SiteId)) {
            if ($SiteId -eq $script:TSSiteId) {
                Invoke-RestMethod -Uri (Get-TSRequestUri -Endpoint Site -Param $SiteId) -Method Delete -Headers (Get-TSRequestHeaderDict)
            } else {
                Write-Error -Exception "You can only remove the site for which you are currently authenticated."
            }
        }
    } catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Invoke-TSSignIn
Export-ModuleMember -Function Invoke-TSSignOut
Export-ModuleMember -Function Invoke-TSSwitchSite

Export-ModuleMember -Function Get-TSProject
Export-ModuleMember -Function New-TSProject
Export-ModuleMember -Function Update-TSProject
Export-ModuleMember -Function Remove-TSProject

Export-ModuleMember -Function Get-TSSite
Export-ModuleMember -Function New-TSSite
Export-ModuleMember -Function Update-TSSite
Export-ModuleMember -Function Remove-TSSite
