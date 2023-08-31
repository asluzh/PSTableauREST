$global:TableauRestApiVer = '3.6'
$global:TableauRestApiChunkSize = 2097152	   ## 2MB or 2048KB

function Get-TS-ServerInfo
{
 try
  {
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$TableauRestApiVer/serverinfo -Method Get
   $api_ver = $response.tsResponse.ServerInfo.restApiVersion
   $ProductVersion = $response.tsResponse.ServerInfo.ProductVersion.build
   "API Version: " + $api_ver
   "Tableau Version: " + $ProductVersion
   $global:TableauRestApiVer = $api_ver
  }
  catch
   {
     $global:TableauRestApiVer = '3.6'
   }
}

function Invoke-TS-SignIn
{

 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password,
 [validateset('http','https')][string[]] $protocol = 'http',
 [string[]] $siteID = ""
 )

 $global:server = $server
 $global:protocol = $protocol
 $global:username = $username
 $global:password = $password
 Invoke-TS-ServerInfo

 # generate body for sign in
 $signin_body = ('<tsRequest>
  <credentials name="' + $username + '" password="'+ $password + '" >
   <site contentUrl="' + $siteID +'"/>
  </credentials>
 </tsRequest>')

 try
  {
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$TableauRestApiVer/auth/signin -Body $signin_body -Method Post
   # get the auth token, site id and my user id
   $global:authToken = $response.tsResponse.credentials.token
   $global:siteID = $response.tsResponse.credentials.site.id
   $global:myUserID = $response.tsResponse.credentials.user.id

   # set up header fields with auth token
   $global:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
   # add X-Tableau-Auth header with our auth tokents-
   $headers.Add("X-Tableau-Auth", $authToken)
   "Signed In Successfully to Server: "  + ${protocol}+"://"+$server
  }

 catch {throw "Unable to Sign-In to Tableau Server: " + ${protocol}+"://"+$server}
}


function Invoke-TS-SignOut
{
 try
 {
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$TableauRestApiVer/auth/signout -Headers $headers -Method Post
  "Signed Out Successfully from: " + ${protocol}+ "://"+$server
  }
 catch
  {"Unable to Sign out from Tableau Server: " + ${protocol}+"://"+$server}
}

Export-ModuleMember -Function Get-TS-ServerInfo
Export-ModuleMember -Function Invoke-TS-SignIn
Export-ModuleMember -Function Invoke-TS-SignOut
