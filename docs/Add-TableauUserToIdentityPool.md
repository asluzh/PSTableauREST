# Add-TableauUserToIdentityPool

## SYNOPSIS
Add User to Identity Pool

## SYNTAX

```
Add-TableauUserToIdentityPool [-UserId] <String> [-IdentityPoolId] <String> [[-Username] <String>]
 [[-SiteRole] <String>] [[-AuthConfigurationId] <String>] [[-IdentityId] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Add a user to a specified identity pool.
This enables the user to sign in to Tableau Server using the specified identity pool.
This method is not available for Tableau Cloud.
This method can only be called by server administrators.

## EXAMPLES

### EXAMPLE 1
```
$user = Add-TableauUserToIdentityPool -UserId $userId -IdentityPoolId $uuid
```

## PARAMETERS

### -UserId
The LUID of the user to add.

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

### -IdentityPoolId
The ID of the identity pool to add the user to.
You can get the identity pool ID by calling Get-TableauIdentityPool

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

### -Username
(Optional) The name of the user to add.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteRole
(Optional) Site role of the user.

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

### -AuthConfigurationId
(Optional) The authentication configuration instance configured for the identity pool you want to add the user to.
You can get the authentication configuration instance by calling Get-TableauAuthConfiguration

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityId
The identifier for the user you want to add.
Identifiers are only used for identity matching purposes.
For more information about identifiers, look for Usernames and Identifiers in Tableau in the Tableau Server Help.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#add_user_to_idpool](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#add_user_to_idpool)

