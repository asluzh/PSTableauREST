---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Run Metadata GraphQL query"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/metadata_api/en-us/index.html
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauMetadataGraphQL/", "/PowerShell/PSTableauREST/get-tableaumetadatagraphql/", "/PowerShell/get-tableaumetadatagraphql/"]
schema: 2.0.0
title: Get-TableauMetadataGraphQL
---

# Get-TableauMetadataGraphQL

## SYNOPSIS
Run Metadata GraphQL query

## SYNTAX

```
Get-TableauMetadataGraphQL [-Query] <String> [[-PaginatedEntity] <String>] [[-PageSize] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Runs the specified GraphQL query through the Tableau Metadata API, including paginating of results.

## EXAMPLES

### EXAMPLE 1
```
$results = Get-TableauMetadataGraphQL -Query (Get-Content "workbooks.graphql" | Out-String)
```

## PARAMETERS

### -Query
The GraphQL query

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

### -PaginatedEntity
If this parameter is provided: modifies the query to implement paginating through results.
Pagination in Tableau Metadata API is supported on entities ending with "Connection" (edges), such as fieldsConnection, workbooksConnection, etc.

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

### -PageSize
(Optional, Query Columns in a Table) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

[https://help.tableau.com/current/api/metadata_api/en-us/index.html](https://help.tableau.com/current/api/metadata_api/en-us/index.html)

