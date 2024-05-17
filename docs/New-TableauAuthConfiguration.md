# New-TableauAuthConfiguration

## SYNOPSIS
Create Authentication Configuration

## SYNTAX

```
New-TableauAuthConfiguration [-ClientId] <String> [-ClientSecret] <String> [-ConfigUrl] <String>
 [[-CustomScope] <String>] [[-IdClaim] <String>] [[-UsernameClaim] <String>] [[-ClientAuthentication] <String>]
 [[-IframedIdpEnabled] <String>] [[-EssentialAcrValues] <String>] [[-VoluntaryAcrValues] <String>]
 [[-Prompt] <String>] [[-ConnectionTimeout] <Int32>] [[-ReadTimeout] <Int32>] [[-IgnoreDomain] <String>]
 [[-IgnoreJwk] <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create an instance of OpenID Connect (OIDC) authentication.
This method can only be called by server administrators.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$oidc = New-TableauAuthConfiguration -ClientId $cid -ClientSecret $secret -ConfigUrl $url -IdClaim $claim -UsernameClaim $userclaim
```

## PARAMETERS

### -ClientId
Provider client ID that the IdP has assigned to Tableau Server.

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

### -ClientSecret
Provider client secret.
This is a token that is used by Tableau Server to verify the authenticity of the response from the IdP.
This value should be kept securely.

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

### -ConfigUrl
Provider configuration URL.
Specifies the location of the provider configuration discovery document that contains OpenID provider metadata.

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

### -CustomScope
(Optional) Custom scope user-related value to query the IdP.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdClaim
(Optional) Claim for retrieving user ID from the OIDC token.
Default value is 'sub'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Sub
Accept pipeline input: False
Accept wildcard characters: False
```

### -UsernameClaim
(Optional) Claim for retrieving username from the OIDC token.
Default value is 'email'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Email
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientAuthentication
(Optional) Token endpoint authentication method.
Default value is 'CLIENT_SECRET_BASIC'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: Client_secret_basic
Accept pipeline input: False
Accept wildcard characters: False
```

### -IframedIdpEnabled
(Optional) Boolean, allows the identity provider (IdP) to authenticate inside of an iFrame.
The IdP must disable clickjack protection to allow iFrame presentation.
Default value is 'false'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EssentialAcrValues
(Optional) List of essential Authentication Context Reference Class values used for authentication.

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

### -VoluntaryAcrValues
(Optional) List of voluntary Authentication Context Reference Class values used for authentication.

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

### -Prompt
(Optional) Prompts the user for reauthentication and consent.

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

### -ConnectionTimeout
(Optional) Integer, wait time (in seconds) for connecting to the IdP.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReadTimeout
(Optional) Integer, wait time (in seconds) for data from the IdP.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDomain
(Optional) Set value to 'true' only if the following are true: you are using email addresses as usernames in Tableau Server,
you have provisioned users in the IdP with multiple domains, and you want to ignore the domain name portion of the email claim from the IdP.
Default value is 'false'.

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

### -IgnoreJwk
(Optional) Set value to 'true' if the IdP does not support JWK validation.
Default value is 'false'.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#AuthnService_RegisterAuthConfiguration](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#AuthnService_RegisterAuthConfiguration)

