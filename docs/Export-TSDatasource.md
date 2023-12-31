---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Download Data Source / Download Data Source Revision"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#download_data_source
redirect_from: ["/PowerShell/PSTableauREST/Export-TSDatasource/", "/PowerShell/PSTableauREST/export-tsdatasource/", "/PowerShell/export-tsdatasource/"]
schema: 2.0.0
title: Export-TSDatasource
---

# Export-TSDatasource

## SYNOPSIS
Download Data Source / Download Data Source Revision

## SYNTAX

```
Export-TSDatasource [-DatasourceId] <String> [[-OutFile] <String>] [-ExcludeExtract] [[-Revision] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Downloads a data source or data source revision in .tds or .tdsx format.

## EXAMPLES

### EXAMPLE 1
```
Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Superstore_Data.tdsx" -ExcludeExtract
```

### EXAMPLE 2
```
Export-TSDatasource -DatasourceId $sampleDatasourceId -OutFile "Superstore_Data_1.tdsx" -Revision 1
```

## PARAMETERS

### -DatasourceId
The LUID of the data source to be downloaded.

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

### -OutFile
(Optional) Filename where the data source is saved upon download.
If not provided, the downloaded content is piped to the output.

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

### -ExcludeExtract
(Optional) Boolean switch, if supplied and the data source contains an extract, it is not included for the download.

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

### -Revision
(Optional) If revision number is specified, this revision will be downloaded.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
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

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#download_data_source](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#download_data_source)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#download_data_source_revision](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#download_data_source_revision)

