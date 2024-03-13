# Get-TableauSiteSettingsAllowedExtension

## SYNOPSIS
List allowed dashboard extensions on site - Retired in API 3.21
or
Get allowed dashboard extension on site - Retired in API 3.21

## SYNTAX

```
Get-TableauSiteSettingsAllowedExtension [[-ExtensionId] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Lists the dashboard extensions on the safe list of the site you are signed into, or
Gets the details of a specific dashboard extension on the safe list of the site you are signed into.
This method is retired and is not available on Tableau Cloud.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-TableauSiteSettingsAllowedExtension
```

### EXAMPLE 2
```
$ext = Get-TableauSiteSettingsAllowedExtension -ExtensionId $eid
```

## PARAMETERS

### -ExtensionId
(Optional) The unique ID of the extension on the allowed list.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsSafeListItems](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsSafeListItems)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_getDashboardExtensionsSafeListItem](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_getDashboardExtensionsSafeListItem)

