---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "List Extract Refresh Tasks in Server Schedule"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauExtractRefreshTask/", "/PowerShell/PSTableauREST/get-tableauextractrefreshtask/", "/PowerShell/get-tableauextractrefreshtask/"]
schema: 2.0.0
title: Get-TableauExtractRefreshTask
---

# Get-TableauExtractRefreshTask

## SYNOPSIS
List Extract Refresh Tasks in Server Schedule

## SYNTAX

```
Get-TableauExtractRefreshTask [-ScheduleId] <String> [[-PageSize] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns a list of the extract refresh tasks for a specified server schedule on the specified site on Tableau Server.
Not available for Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$tasks = Get-TableauExtractRefreshTask -ScheduleId $extractScheduleId
```

## PARAMETERS

### -ScheduleId
The LUID of the schedule to get extract information for.

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

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 100
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#list_extract_refresh_tasks1

## RELATED LINKS
