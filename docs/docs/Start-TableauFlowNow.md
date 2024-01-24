---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Run Flow Now"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_now
redirect_from: ["/PowerShell/PSTableauREST/Start-TableauFlowNow/", "/PowerShell/PSTableauREST/start-tableauflownow/", "/PowerShell/start-tableauflownow/"]
schema: 2.0.0
title: Start-TableauFlowNow
---

# Start-TableauFlowNow

## SYNOPSIS
Run Flow Now

## SYNTAX

```
Start-TableauFlowNow [-FlowId] <String> [[-RunMode] <String>] [[-OutputStepId] <String>]
 [[-FlowParams] <Hashtable>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Runs the specified flow (asynchronously).

## EXAMPLES

### EXAMPLE 1
```
$job = Start-TableauFlowNow -FlowId $flow.id
```

## PARAMETERS

### -FlowId
The LUID of the flow to run.

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

### -RunMode
(Optional) The mode to use for running this flow, either 'full' or 'incremental'.
Default is 'full'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Full
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputStepId
(Optional) The LUID of the output steps you want to run.

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

### -FlowParams
(Optional) The hashtable of the flow parameters, with flow parameter IDs and values.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_now](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#run_flow_now)

