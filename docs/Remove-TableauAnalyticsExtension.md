# Remove-TableauAnalyticsExtension

## SYNOPSIS
Delete analytics extension connection from site
or
Remove current analytics extension connection for workbook

## SYNTAX

### Connection
```
Remove-TableauAnalyticsExtension -ConnectionId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Workbook
```
Remove-TableauAnalyticsExtension -WorkbookId <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Removes the specific analytics extension connection from a site or workbook.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauAnalyticsExtension -ConnectionId $conn
```

## PARAMETERS

### -ConnectionId
The LUID of the connection to remove.

```yaml
Type: String
Parameter Sets: Connection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkbookId
(Optional) If the connection should be removed for a workbook, this is the LUID of the workbook.

```yaml
Type: String
Parameter Sets: Workbook
Aliases:

Required: True
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_deleteAnalyticsExtensionsConnection](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_deleteAnalyticsExtensionsConnection)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_deleteConnectionFromWorkbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_deleteConnectionFromWorkbook)

