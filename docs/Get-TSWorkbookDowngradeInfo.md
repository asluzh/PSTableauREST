---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get Workbook Downgrade Info"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_downgrade_info
redirect_from: ["/PowerShell/PSTableauREST/Get-TSWorkbookDowngradeInfo/", "/PowerShell/PSTableauREST/get-tsworkbookdowngradeinfo/", "/PowerShell/get-tsworkbookdowngradeinfo/"]
schema: 2.0.0
title: Get-TSWorkbookDowngradeInfo
---

# Get-TSWorkbookDowngradeInfo

## SYNOPSIS
Get Workbook Downgrade Info

## SYNTAX

```
Get-TSWorkbookDowngradeInfo [-WorkbookId] <String> [-DowngradeVersion] <Version>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of the features that would be impacted, and the severity of the impact,
when a workbook is exported as a downgraded version (for instance, exporting a v2019.3 workbook to a v10.5 version).

## EXAMPLES

### EXAMPLE 1
```
$downgradeInfo = Get-TSWorkbookDowngradeInfo -WorkbookId $sampleWorkbookId -DowngradeVersion 2019.3
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook which would be downgraded.

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

### -DowngradeVersion
The Tableau release version number the workbook would be downgraded to.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_downgrade_info](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_downgrade_info)

