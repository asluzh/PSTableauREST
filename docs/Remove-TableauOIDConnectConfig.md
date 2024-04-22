# Remove-TableauOIDConnectConfig

## SYNOPSIS
Remove OpenID Connect Configuration

## SYNTAX

```
Remove-TableauOIDConnectConfig [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Disable and clear the Tableau Cloud site's OpenID Connect (OIDC) configuration.
Tableau site admins privileges are required to call this method.
Important: Before removing the OIDC configuration,
make sure that users who are set to authenticate with OIDC are set to use a different authentication type.
Users who are not set with a different authentication type before removing the OIDC configuration will not be able to sign in to Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$result = Remove-TableauOIDConnectConfig
```

## PARAMETERS

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#remove_openid_connect_configuration](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_openid_connect.htm#remove_openid_connect_configuration)

