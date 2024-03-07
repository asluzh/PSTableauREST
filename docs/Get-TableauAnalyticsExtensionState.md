# Get-TableauAnalyticsExtensionState

## SYNOPSIS
Get enabled state of analytics extensions on site
or
Get enabled state of analytics extensions on server

## SYNTAX

```
Get-TableauAnalyticsExtensionState [-Scope] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves the current state (enabled/disabled) for analytics extensions on the site or server.

## EXAMPLES

### EXAMPLE 1
```
$enabled = Get-TableauAnalyticsExtensionState -Scope Site
```

## PARAMETERS

### -Scope
Specifies the scope for analytcs extension settings (Server or Site).
If requested for the scope of Server, the server admin privileges are required.

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

### System.String
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsSiteSettings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsSiteSettings)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsServerSettings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_getAnalyticsExtensionsServerSettings)

