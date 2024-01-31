---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_embedding_settings_for_site
schema: 2.0.0
title: Set-TableauSiteSettingsEmbedding
---

# Set-TableauSiteSettingsEmbedding

## SYNOPSIS
Update Embedding Settings for Site

## SYNTAX

### Unrestricted
```
Set-TableauSiteSettingsEmbedding [-UnrestrictedEmbedding] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### AllowDomains
```
Set-TableauSiteSettingsEmbedding -AllowDomains <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the embedding settings for a site.
Embedding settings can be used to restrict embedding Tableau views to only certain domains.

## EXAMPLES

### EXAMPLE 1
```
$result = Set-TableauSiteSettingsEmbedding -Unrestricted false -Allow "mydomain.com"
```

## PARAMETERS

### -UnrestrictedEmbedding
(Optional) Boolean switch, specifies whether embedding is not restricted to certain domains.
When supplied, Tableau views on this site can be embedded in any domain.

```yaml
Type: SwitchParameter
Parameter Sets: Unrestricted
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowDomains
(Optional) Specifies the domains where Tableau views on this site can be embedded.
Use this setting with UnrestrictedEmbedding set to false, to restrict embedding functionality to only certain domains.

```yaml
Type: String
Parameter Sets: AllowDomains
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

### System.Management.Automation.PSObject[]
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_embedding_settings_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#update_embedding_settings_for_site)

