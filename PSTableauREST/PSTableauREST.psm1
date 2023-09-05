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
    param(
        [string] $Server,
        [string] $Username,
        [securestring] $SecurePassword,
        [string] $Site = ""
    )

    $global:Server = $Server
    $global:Username = $Username
    Get-TSServerInfo

    $PlainTextPassword = [System.Net.NetworkCredential]::new("", $SecurePassword).Password

    # generate body for sign in
    $signin_body = ('<tsRequest>
<credentials name="' + $Username + '" password="' + $PlainTextPassword + '" >
<site contentUrl="' + $Site + '"/>
</credentials>
</tsRequest>')

    try {
        $response = Invoke-RestMethod -Uri $server/api/$TableauRestApiVer/auth/signin -Body $signin_body -Method Post
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
