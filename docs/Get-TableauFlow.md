---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Query Flow / Query Flows / Query Flow Revisions"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauFlow/", "/PowerShell/PSTableauREST/get-tableauflow/", "/PowerShell/get-tableauflow/"]
schema: 2.0.0
title: Get-TableauFlow
---

# Get-TableauFlow

## SYNOPSIS
Query Flow / Query Flows / Query Flow Revisions

## SYNTAX

### FlowRevisions
```
Get-TableauFlow -FlowId <String> [-Revisions] [-PageSize <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FlowById
```
Get-TableauFlow -FlowId <String> [-OutputSteps] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Flows
```
Get-TableauFlow [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified flow, or flows.

## EXAMPLES

### EXAMPLE 1
```
$flow = Get-TableauFlow -FlowId $flowId
```

### EXAMPLE 2
```
$outputSteps = Get-TableauFlow -FlowId $flowId -OutputSteps
```

### EXAMPLE 3
```
$flows = Get-TableauFlow -Filter "name:eq:$flowName"
```

## PARAMETERS

### -FlowId
(Query Flow by Id) The LUID of the flow.

```yaml
Type: String
Parameter Sets: FlowRevisions, FlowById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Revisions
(Get Flow Revisions) Boolean switch, if supplied, the flow revisions are returned.
Note: reserved for future use, flow revisions are currently not supported via REST API

```yaml
Type: SwitchParameter
Parameter Sets: FlowRevisions
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputSteps
(Optional, Query Flow) Boolean switch, if supplied, the flow output steps are returned, instead of flow.

```yaml
Type: SwitchParameter
Parameter Sets: FlowById
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flows

```yaml
Type: String[]
Parameter Sets: Flows
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#flows

```yaml
Type: String[]
Parameter Sets: Flows
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_flows

```yaml
Type: String[]
Parameter Sets: Flows
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
Parameter Sets: FlowRevisions, Flows
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_site)

