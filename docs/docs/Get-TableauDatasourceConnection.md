---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Query Data Source Connections"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source_connections
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauDatasourceConnection/", "/PowerShell/PSTableauREST/get-tableaudatasourceconnection/", "/PowerShell/get-tableaudatasourceconnection/"]
schema: 2.0.0
title: Get-TableauDatasourceConnection
---

# Get-TableauDatasourceConnection

## SYNOPSIS
Query Data Source Connections

## SYNTAX

```
Get-TableauDatasourceConnection [-DatasourceId] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns a list of data connections for the specific data source.

## EXAMPLES

### EXAMPLE 1
```
$dsConnections = Get-TableauDatasourceConnection -DatasourceId $datasourceId
```

## PARAMETERS

### -DatasourceId
The LUID of the data source to return connection information about.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source_connections)

