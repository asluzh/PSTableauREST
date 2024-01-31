# Set-TableauSite

## SYNOPSIS
Update Site

## SYNTAX

```
Set-TableauSite [-SiteId] <String> [[-Name] <String>] [[-SiteParams] <Hashtable>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Modifies settings for the specified site, including the content URL, administration mode, user quota, state (active or suspended),
storage quota, whether flows are enabled, whether subscriptions are enabled, and whether revisions are enabled.

## EXAMPLES

### EXAMPLE 1
```
$site = Set-TableauSite -SiteId $siteId -Name "New Site" -SiteParams @{adminMode="ContentAndUsers"; userQuota="1"}
```

## PARAMETERS

### -SiteId
The LUID of the site to update.

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
(Optional)
The new name of the site.

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

### -SiteParams
(Optional)
Hashtable with site options.
Please check the linked help page for up-to-date supported options.
See also New-TableauSite

```yaml
Type: Hashtable
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
You must be signed in to a site in order to update it.
No validation is done for SiteParams.
If some invalid option is included in the request, an HTTP error will be returned by the request.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_site)

