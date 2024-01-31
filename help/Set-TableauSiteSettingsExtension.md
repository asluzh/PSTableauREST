# Set-TableauSiteSettingsExtension

## SYNOPSIS
Update Tableau extensions site settings

## SYNTAX

```
Set-TableauSiteSettingsExtension [-Enabled] <String> [[-UseDefaultSetting] <String>]
 [[-SafeList] <Hashtable[]>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the settings for extensions of a site.
This method can only be called by site or server administrators.

## EXAMPLES

### EXAMPLE 1
```
$settings = Set-TableauSiteSettingsExtension -Enabled true -SafeList @{url='https://test.com';fullDataAllowed='true';promptNeeded='true'}
```

## PARAMETERS

### -Enabled
True/false.
True: extensions are allowed to run on the site.
False: no extensions are allowed to run on the site even if their URL is in the site safelist.

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

### -UseDefaultSetting
(Optional) True/false.
If extensions are enabled on the server, the default settings allow extensions to run on a site,
provided the extension is not specifically blocked on the server.

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

### -SafeList
(Optional) List of URLs of the extensions that are allowed to run on the site and their properties (full data access, prompt to run).
An extension permissions to run an a site are also dependent on the domain of the URL not being present on the server blocklist,
and server and site extension enablement being true.
Note that updating the safelist replaces the existing list with the new list.
If you want to add a URL to the existing list, you must also include the existing URLs in the new list.

```yaml
Type: Hashtable[]
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#update_tableau_extensions_site_settings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#update_tableau_extensions_site_settings)

