---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Publish Flow"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#publish_flow
redirect_from: ["/PowerShell/PSTableauREST/Publish-TSFlow/", "/PowerShell/PSTableauREST/publish-tsflow/", "/PowerShell/publish-tsflow/"]
schema: 2.0.0
title: Publish-TSFlow
---

# Publish-TSFlow

## SYNOPSIS
Publish Flow

## SYNTAX

```
Publish-TSFlow [-InFile] <String> [-Name] <String> [[-FileName] <String>] [[-FileType] <String>]
 [[-ProjectId] <String>] [-Overwrite] [-Chunked] [[-Connections] <Hashtable[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Publishes a flow on the current site.

## EXAMPLES

### EXAMPLE 1
```
$flow = Publish-TSFlow -Name $sampleFlowName -InFile "Flow.tflx" -ProjectId $projectId -Overwrite
```

## PARAMETERS

### -InFile
The filename (incl.
path) of the flow to upload and publish.

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

### -Name
The name for the published flow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName
(Optional) The filename (without path) that is included into the request payload.
If omitted, the filename is derived from the InFile parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileType
(Optional) The file type of the flow file.
If omitted, the file type is derived from the Filename parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectId
(Optional) The LUID of the project to assign the flow to.
If the project is not specified, the flow will be published to the default project.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Overwrite
(Optional) Boolean switch, if supplied, the flow will be overwritten (otherwise existing published flow with the same name is not overwritten).

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

### -Chunked
(Optional) Boolean switch, if supplied, the publish process is forced to run as chunked.
By default, the payload is send in one request for files \< 64MB size.
This can be helpful if timeouts occur during upload.

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

### -Connections
(Optional) Hashtable array containing connection attributes and credentials (see online help).

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#publish_flow](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#publish_flow)

