# Set-TableauConnectedApp

## SYNOPSIS
Update Connected App

## SYNTAX

```
Set-TableauConnectedApp [-ClientId] <String> [-Name] <String> [[-Enabled] <String>] [[-ProjectId] <String[]>]
 [[-DomainSafeList] <String[]>] [[-UnrestrictedEmbedding] <String>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update a connected app settings.

## EXAMPLES

### EXAMPLE 1
```
$app = Set-TableauConnectedApp -Name "Connected App Example" -ProjectId "" -UnrestrictedEmbedding true
```

## PARAMETERS

### -ClientId
The client ID of the connected app to be updated.

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

### -Name
(Optional) The new name of the connected app.

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

### -Enabled
(Optional) Controls whether the connected app is enabled or not.

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

### -ProjectId
(Optional) The list of project LUID that the connected app's access level is scoped to.
Multiple projects can be specified for API version 3.22 and later.
For scoping to all projects: specify the empty string value.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainSafeList
(Optional) A list of domains the connected app is allowed to be hosted.
Please check Domain allowlist rules in online help for format specification.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UnrestrictedEmbedding
(Optional) Controls whether the connected app can be hosted on all domains.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#update_connectedapp](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#update_connectedapp)

