---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_database
schema: 2.0.0
title: Get-TableauDatabase
---

# Get-TableauDatabase

## SYNOPSIS
Query Database / Query Databases

## SYNTAX

### DatabaseById
```
Get-TableauDatabase -DatabaseId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Databases
```
Get-TableauDatabase [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get information about a database asset, or a list of database assets.

## EXAMPLES

### EXAMPLE 1
```
$databases = Get-TableauDatabase
```

## PARAMETERS

### -DatabaseId
Query Database: The LUID of the database.

```yaml
Type: String
Parameter Sets: DatabaseById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, Query Databases) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Databases
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_database](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_database)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_databases](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_databases)

