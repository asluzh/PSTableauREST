# Set-TableauSiteSettingsAllowedExtension

## SYNOPSIS
Update settings for allowed dashboard extension on site - Retired in API 3.21

## SYNTAX

```
Set-TableauSiteSettingsAllowedExtension [-ExtensionId] <String> [-ExtensionUrl] <String>
 [-AllowFullData] <String> [-PromptNeeded] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Updates the settings of a specific dashboard extension in the safe list of the site you are signed into.
This method is retired and is not available on Tableau Cloud.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$ext = Set-TableauSiteSettingsAllowedExtension -ExtensionId $eid -ExtensionUrl "https://test.com" -AllowFullData false -PromptNeeded false
```

## PARAMETERS

### -ExtensionId
The unique ID of the extension on the allowed list.

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

### -ExtensionUrl
Location (URL) of the dashboard extension to be allowed on a site.

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

### -AllowFullData
When true, the extension has access to underlying data of a workbook.
This setting is only effective when the extension is on the site safe list.

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

### -PromptNeeded
When true, the user will be prompted to grant an extension access to the underlying data of a workbook.
This setting is only effective when the extension is on the site safe list.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_updateDashboardExtensionsSafeListItem](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_updateDashboardExtensionsSafeListItem)

