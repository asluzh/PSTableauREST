# New-TableauConnectedAppEAS

## SYNOPSIS
Register EAS

## SYNTAX

```
New-TableauConnectedAppEAS [-IssuerUrl] <String> [[-JwksUri] <String>] [[-Name] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a connected app with OAuth 2.0 trust by registering an external authorization server (EAS) to a site.
Tableau Cloud only, currently not supported for Tableau Server.

## EXAMPLES

### EXAMPLE 1
```
$eas = New-TableauConnectedAppEAS -IssuerUrl $url -Name "External Authorization Server"
```

## PARAMETERS

### -IssuerUrl
The entity id of your identity provider (IdP) or URL that uniquely identifies your IdP.

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

### -JwksUri
(Optional) The JSON Web Key (JKWS) of the EAS.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
(Optional) The name of the connected app.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#create_connectedapp_eas](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#create_connectedapp_eas)

