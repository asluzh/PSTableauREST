---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Query Table / Query Tables"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_table
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauTable/", "/PowerShell/PSTableauREST/get-tableautable/", "/PowerShell/get-tableautable/"]
schema: 2.0.0
title: Get-TableauTable
---

# Get-TableauTable

## SYNOPSIS
Query Table / Query Tables

## SYNTAX

### TableById
```
Get-TableauTable -TableId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Tables
```
Get-TableauTable [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get information about a table asset, or a list of table assets.

## EXAMPLES

### EXAMPLE 1
```
$tables = Get-TableauTable
```

## PARAMETERS

### -TableId
Query Table: The LUID of the table.

```yaml
Type: String
Parameter Sets: TableById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, Query Tables) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Tables
Aliases:

Required: False
Position: Named
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

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_table](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_table)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_tables](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_tables)

