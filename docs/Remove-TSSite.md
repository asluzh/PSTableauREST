---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Delete Site"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#delete_site
redirect_from: ["/PowerShell/PSTableauREST/Remove-TSSite/", "/PowerShell/PSTableauREST/remove-tssite/", "/PowerShell/remove-tssite/"]
schema: 2.0.0
title: Remove-TSSite
---

# Remove-TSSite

## SYNOPSIS
Delete Site

## SYNTAX

```
Remove-TSSite [-SiteId] <String> [-BackgroundTask] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes the specified site.

## EXAMPLES

### EXAMPLE 1
```
$response = Remove-TSSite -SiteId $testSiteId
```

## PARAMETERS

### -SiteId
The LUID of the site to be deleted.
Should be the current site's ID.

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

### -BackgroundTask
(Introduced in API 3.18) If you set this to true, the process runs asynchronously.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
This method can only be called by server administrators.
Not supported on Tableau Cloud.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#delete_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#delete_site)

