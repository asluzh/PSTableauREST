---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete Flow"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauFlow/", "/PowerShell/PSTableauREST/remove-tableauflow/", "/PowerShell/remove-tableauflow/"]
schema: 2.0.0
title: Remove-TableauFlow
---

# Remove-TableauFlow

## SYNOPSIS
Delete Flow

## SYNTAX

```
Remove-TableauFlow [-FlowId] <String> [[-Revision] <Int32>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes a flow.
When a flow is deleted, its associated connections, the output and input steps, any associated scheduled tasks, and run history are also deleted.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauFlow -FlowId $sampleFlowId
```

## PARAMETERS

### -FlowId
The LUID of the flow to delete.

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

### -Revision
(Optional) If revision number is specified, this revision will be removed.
Note: reserved for future use, flow revisions are currently not supported via REST API

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow)

