---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Download Flow"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#download_flow
redirect_from: ["/PowerShell/PSTableauREST/Export-TSFlow/", "/PowerShell/PSTableauREST/export-tsflow/", "/PowerShell/export-tsflow/"]
schema: 2.0.0
title: Export-TSFlow
---

# Export-TSFlow

## SYNOPSIS
Download Flow

## SYNTAX

```
Export-TSFlow [-FlowId] <String> [[-OutFile] <String>] [[-Revision] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Downloads a flow in .tfl or .tflx format.

## EXAMPLES

### EXAMPLE 1
```
Export-TSFlow -FlowId $sampleflowId -OutFile "Flow.tflx"
```

## PARAMETERS

### -FlowId
The LUID of the flow to download.

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
(Optional) Filename where the download is saved.
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

### -Revision
(Optional) If revision number is specified, this revision will be downloaded.
Note: reserved for future use, flow revisions are currently not supported via REST API

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#download_flow](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#download_flow)

