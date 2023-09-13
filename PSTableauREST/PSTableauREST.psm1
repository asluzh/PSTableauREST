$global:TableauRestApiVer = '3.6'
$global:TableauRestApiChunkSize = 2097152	   ## 2MB or 2048KB

function Get-TSServerInfo {
    try {
        $response = Invoke-RestMethod -Uri $server/api/$TableauRestApiVer/serverinfo -Method Get
        $api_ver = $response.tsResponse.ServerInfo.restApiVersion
        $ProductVersion = $response.tsResponse.ServerInfo.ProductVersion.build
        #  "API Version: " + $api_ver
        #  "Tableau Version: " + $ProductVersion
        $global:TableauRestApiVer = $api_ver
    }
    catch {
        $global:TableauRestApiVer = '3.6'
    }
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
        $global:AuthToken = $response.tsResponse.credentials.token
        $global:Site = $response.tsResponse.credentials.site.id
        $global:UserID = $response.tsResponse.credentials.user.id

        # set up header fields with auth token
        $global:Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        # add X-Tableau-Auth header with our auth tokents-
        $Headers.Add("X-Tableau-Auth", $AuthToken)
        "Signed In Successfully"
    }

    catch { throw "Unable to Sign-In to Tableau Server: " + $Server }
}

function Invoke-TSSignOut
{
    try {
        $response = Invoke-RestMethod -Uri $Server/api/$TableauRestApiVer/auth/signout -Headers $Headers -Method Post
        "Signed Out Successfully from: " + $Server
    }
    catch
    { throw "Unable to Sign out from Tableau Server: " + $Server }
}

Export-ModuleMember -Function Get-TSServerInfo
Export-ModuleMember -Function Invoke-TSSignIn
Export-ModuleMember -Function Invoke-TSSignOut
