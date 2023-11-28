---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Query Flow Connections"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_connections
redirect_from: ["/PowerShell/PSTableauREST/Get-TSFlowConnection/", "/PowerShell/PSTableauREST/get-tsflowconnection/", "/PowerShell/get-tsflowconnection/"]
schema: 2.0.0
title: Get-TSFlowConnection
---

# Get-TSFlowConnection

## SYNOPSIS
Query Flow Connections

## SYNTAX

```
Get-TSFlowConnection [-FlowId] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of data connections for the specific flow.

## EXAMPLES

### EXAMPLE 1
```
$connections = Get-TSFlowConnection -FlowId $flowId
```

## PARAMETERS

### -FlowId
The LUID of the flow to return connection information about.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_connections)

