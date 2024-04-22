# Set-TableauOIDConnectConfig

## SYNOPSIS
Create OpenID Connect Configuration
or
Update OpenID Connect Configuration

## SYNTAX

```
Set-TableauOIDConnectConfig [-Enabled] <String> [-ClientId] <String> [-ClientSecret] <String>
 [-AuthorizationEndpoint] <String> [-TokenEndpoint] <String> [-UserinfoEndpoint] <String> [-JwksUri] <String>
 [[-EndSessionEndpoint] <String>] [[-AllowEmbeddedAuthentication] <String>] [[-Prompt] <String>]
 [[-CustomScope] <String>] [[-ClientAuthentication] <String>] [[-EssentialAcrValues] <String>]
 [[-VoluntaryAcrValues] <String>] [[-EmailMapping] <String>] [[-FirstNameMapping] <String>]
 [[-LastNameMapping] <String>] [[-FullNameMapping] <String>] [[-UseFullName] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create the Tableau Cloud site's OpenID Connect (OIDC) configuration.
or
Update the Tableau Cloud site's OpenID Connect (OIDC) configuration.
(uses the same API endpoint)
Tableau site admins privileges are required to call this method.

## EXAMPLES

### EXAMPLE 1
```
$config = Set-TableauOIDConnectConfig -Enabled true -ClientId '0oa111usf1gpUkVUt0h1' -ClientSecret 'abcde' -AuthorizationEndpoint 'https://myidp.com/oauth2/v1/authorize' -TokenEndpoint 'https://myidp.com/oauth2/v1/token' -UserinfoEndpoint 'https://myidp.com/oauth2/v1/userinfo' -JwksUri 'https://myidp.com/oauth2/v1/keys'
```

## PARAMETERS

### -Enabled
Controls whether the configuration is enabled or not.
Value can be "true" or "false".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
The client ID from your IdP.
For example, "0oa111usf1gpUkVUt0h1".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
The client secret from your IdP.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizationEndpoint
Use the authorization endpoint from your IdP.
To find the value, enter the configuration URL in a browser and obtain the user information endpoint
(authorization_endpoint) from the details that are returned.
For example, "https://myidp.com/oauth2/v1/authorize".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TokenEndpoint
Use the token endpoint from your IdP.
To find the value, enter the configuration URL in a browser and obtain the token endpoint (token_endpoint)
from the details that are returned.
For example, "https://myidp.com/oauth2/v1/token".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserinfoEndpoint
Use the user information endpoint from your IdP.
To find the value, enter the configuration URL in a browser and obtain the user information endpoint
(userinfo_endpoint) from the details that are returned.
For example, "https://myidp.com/oauth2/v1/userinfo".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -JwksUri
Use the JWK set URI from your IdP.
To find the value, enter the configuration URL in a browser and obtain the JWK set URI endpoint (jwks_uri)
from the details that are returned.
For example, "https://myidp.com/oauth2/v1/keys".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndSessionEndpoint
(Optional) If single logout (SLO) is enabled for the site, which is done through Tableau Cloud site UI, you can specify the configuration URL
or the end session endpoint from your IdP.
For example, "https://myidp.com/oauth2/v1/logout".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowEmbeddedAuthentication
(Optional) Controls how users authenticate when accessing embedded views.
Value can be "true" or "false".
Default value is "false", which authenticates users in a separate pop-up window.
When set to "true",
users authenticate using an inline frame (IFrame), which is less secure.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Prompt
(Optional) Specifies whether the user is prompted for re-authentication and consent.
For example, "login, consent".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomScope
(Optional) Specifies a custom scope user-related value that you can use to query the IdP.
For example, "openid, email, profile".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientAuthentication
(Optional) Token endpoint authentication method.
Value can be "client_secret_basic" or "client_secret_post".
Default value is "client_secret_basic".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EssentialAcrValues
(Optional) List of essential Authentication Context Reference Class values used for authentication.
For example, "phr".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VoluntaryAcrValues
(Optional) List of voluntary Authentication Context Reference Class values used for authentication.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailMapping
(Optional) Claim for retrieving email from the OIDC token.
Default value is "email".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FirstNameMapping
(Optional) Claim for retrieving first name from the OIDC token.
Default value is "given_name".
You can use this attribute to retrieve the user's display name when useFullName attribute is set to "false".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastNameMapping
(Optional) Claim for retrieving last name from the OIDC token.
Default value is "family_name".
You can use this attribute to retrieve the user's display name when useFullName attribute is set to "false".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullNameMapping
(Optional) Claim for retrieving name from the OIDC token.
Default value is "name".
You can use this attribute to retrieve the user's display name when useFullName attribute is set to "true".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseFullName
(Optional) Controls what is used as the display name.
Value can be "true" or "false".
Default value is "false", which uses first name (firstNameMapping attribute) and last name (lastNameMapping attribute) as the user display name.
When set to "true", full name (fullNameMapping attribute) is used as the user display name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#create_openid_connect_configuration](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#create_openid_connect_configuration)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#update_openid_connect_configuration](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#update_openid_connect_configuration)

