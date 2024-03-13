# Get-TableauServerSettingsBlockedExtension

## SYNOPSIS
List blocked dashboard extensions on server - Retired in API 3.21
or
Get blocked dashboard extension on server - Retired in API 3.21

## SYNTAX

```
Get-TableauServerSettingsBlockedExtension [[-ExtensionId] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Lists the dashboard extensions on the blocked list of a server, or retrieves the details of a blocked extension.
This method can only be called by server administrators; it is not available on Tableau Cloud.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-TableauServerSettingsBlockedExtension
```

### EXAMPLE 2
```
$ext = Get-TableauServerSettingsBlockedExtension -ExtensionId $eid
```

## PARAMETERS

### -ExtensionId
(Optional) The unique ID of the extension on the blocked list.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsBlockListItems](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsBlockListItems)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsBlockListItem](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsBlockListItem)

