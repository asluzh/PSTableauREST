# Module variables
$TSRestApiVersion = '3.6'
#$TSRestApiChunkSize = 2097152	   ## 2MB or 2048KB

function Get-TSServerInfo {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory=$false)][string] $ServerUrl
    )
    try {
        if ($ServerUrl) {
            $script:TSServerUrl = $ServerUrl
        }
        return Invoke-RestMethod -Uri $script:TSServerUrl/api/$script:TSRestApiVersion/serverinfo -Method Get
    }
    catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

# set up headers IDictionary with auth token
function Get-TSRequestHeaders {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-Tableau-Auth", $script:TSAuthToken)
    return $headers
}

function Invoke-TSSignIn {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory=$true)][string] $ServerUrl,
        [Parameter(Mandatory=$false)][string] $Username,
        [Parameter(Mandatory=$false)][securestring] $SecurePassword,
        [Parameter(Mandatory=$false)][string] $PersonalAccessTokenName,
        [Parameter(Mandatory=$false)][string] $PersonalAccessTokenSecret,
        [Parameter(Mandatory=$false)][string] $Site = ""
    )

    $script:TSServerUrl = $ServerUrl
    $response = Get-TSServerInfo
    # $response.tsResponse.serverInfo.productVersion.build
    # $response.tsResponse.serverInfo.productVersion.#text
    # $response.tsResponse.serverInfo.prepConductorVersion
    # $script:TSRestApiVersion = $response.tsResponse.serverInfo.restApiVersion

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
        $response = Invoke-RestMethod -Uri "$script:TSServerUrl/api/$script:TSRestApiVersion/auth/signin" -Body $xml.OuterXml -Method Post
        # get the auth token, site id and my user id
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response
    }
    catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Invoke-TSSwitchSite {
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory=$true)][string] $Site
    )
    # generate xml request
    $xml = New-Object System.Xml.XmlDocument
    $tsRequest = $xml.AppendChild($xml.CreateElement("tsRequest"))
    $el_site = $tsRequest.AppendChild($xml.CreateElement("site"))
    $el_site.SetAttribute("contentUrl", $Site)

    try {
        $response = Invoke-RestMethod -Uri "$script:TSServerUrl/api/$script:TSRestApiVersion/auth/switchSite" -Body $xml.OuterXml -Method Post -Headers (Get-TSRequestHeaders)
        $script:TSAuthToken = $response.tsResponse.credentials.token
        $script:TSSiteId = $response.tsResponse.credentials.site.id
        $script:TSUserId = $response.tsResponse.credentials.user.id
        return $response
    }
    catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

function Invoke-TSSignOut {
    [OutputType([PSCustomObject])]
    Param()
    try {
        $response = $Null
        if ($Null -ne $script:TSServerUrl -and $Null -ne $script:TSAuthToken) {
            $response = Invoke-RestMethod -Uri "$script:TSServerUrl/api/$script:TSRestApiVersion/auth/signout" -Method Post -Headers (Get-TSRequestHeaders)
            $script:TSServerUrl = $Null
            $script:TSAuthToken = $Null
            $script:TSSiteId = $Null
            $script:TSUserId = $Null
            } else {
            Write-Warning "Currently not signed in."
        }
        return $response
    }
    catch {
        Write-Error -Exception ($_.Exception.Message + " " + $_.ErrorDetails.Message)
    }
}

Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Invoke-TSSignIn
Export-ModuleMember -Function Invoke-TSSignOut
Export-ModuleMember -Function Invoke-TSSwitchSite
