---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Get Flow Run / Get Flow Runs"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauFlowRun/", "/PowerShell/PSTableauREST/get-tableauflowrun/", "/PowerShell/get-tableauflowrun/"]
schema: 2.0.0
title: Get-TableauFlowRun
---

# Get-TableauFlowRun

## SYNOPSIS
Get Flow Run / Get Flow Runs

## SYNTAX

### FlowRunById
```
Get-TableauFlowRun -FlowRunId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### FlowRuns
```
Get-TableauFlowRun [-Filter <String[]>] [-PageSize <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets a specific flow run details, or flow runs.

## EXAMPLES

### EXAMPLE 1
```
$run = Get-TableauFlowRun -FlowRunId $id
```

### EXAMPLE 2
```
$runs = Get-TableauFlowRun -Filter "flowId:eq:$($flowRun.flowId)"
```

## PARAMETERS

### -FlowRunId
(Get Flow Run by Id) The LUID of the flow run.

```yaml
Type: String
Parameter Sets: FlowRunById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flow-runs

```yaml
Type: String[]
Parameter Sets: FlowRuns
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: FlowRuns
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_runs](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_runs)

