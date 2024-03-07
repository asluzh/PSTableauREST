# Get-TableauAnalyticsExtension

## SYNOPSIS
List analytics extension connections on site
or
List analytics extension connections of workbook
or
Get analytics extension connection details
or
Get current analytics extension for workbook

## SYNTAX

### Connection
```
Get-TableauAnalyticsExtension [-ConnectionId <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### WorkbookCurrent
```
Get-TableauAnalyticsExtension -WorkbookId <String> [-Current] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Workbook
```
Get-TableauAnalyticsExtension -WorkbookId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a list of configured analytics extensions for a site or workbook
or
Retrieves the details of the configured analytics extension for a site or workbook

## EXAMPLES

### EXAMPLE 1
```
$list = Get-TableauAnalyticsExtension
```

### EXAMPLE 2
```
$ext = Get-TableauAnalyticsExtension -ConnectionId $conn
```

## PARAMETERS

### -ConnectionId
The LUID of the connection to get the details for.

```yaml
Type: String
Parameter Sets: Connection
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkbookId
The LUID of the workbook to get the list of connections, or connection details for.

```yaml
Type: String
Parameter Sets: WorkbookCurrent, Workbook
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Current
(Switch) Specifies if the current analytics extension for workbook should be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: WorkbookCurrent
Aliases:

Required: True
Position: Named
Default value: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsConnections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsConnections)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getConnectionOptionsForWorkbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getConnectionOptionsForWorkbook)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsConnection](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsConnection)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getSelectedConnectionForWorkbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getSelectedConnectionForWorkbook)

