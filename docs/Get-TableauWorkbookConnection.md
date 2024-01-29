---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Query Workbook Connections"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_connections
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauWorkbookConnection/", "/PowerShell/PSTableauREST/get-tableauworkbookconnection/", "/PowerShell/get-tableauworkbookconnection/"]
schema: 2.0.0
title: Get-TableauWorkbookConnection
---

# Get-TableauWorkbookConnection

## SYNOPSIS
Query Workbook Connections

## SYNTAX

```
Get-TableauWorkbookConnection [-WorkbookId] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of data connections for the specific workbook.

## EXAMPLES

### EXAMPLE 1
```
$workbookConnections = Get-TableauWorkbookConnection -WorkbookId $workbookId
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to return connection information about.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_connections)

