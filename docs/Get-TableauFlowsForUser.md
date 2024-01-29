---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Query Flows for User"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_user
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauFlowsForUser/", "/PowerShell/PSTableauREST/get-tableauflowsforuser/", "/PowerShell/get-tableauflowsforuser/"]
schema: 2.0.0
title: Get-TableauFlowsForUser
---

# Get-TableauFlowsForUser

## SYNOPSIS
Query Flows for User

## SYNTAX

```
Get-TableauFlowsForUser [-UserId] <String> [-IsOwner] [[-PageSize] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the flows that the specified user owns or has read (view) permissions for.

## EXAMPLES

### EXAMPLE 1
```
$flows = Get-TableauFlowsForUser -UserId (Get-TableauCurrentUserId)
```

## PARAMETERS

### -UserId
The LUID of the user to get flows for.

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

### -IsOwner
(Optional) Boolean switch, if supplied, returns only flows that the specified user owns.

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

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_user](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flows_for_user)

