---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Delete Subscription"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#delete_subscription
redirect_from: ["/PowerShell/PSTableauREST/Remove-TSSubscription/", "/PowerShell/PSTableauREST/remove-tssubscription/", "/PowerShell/remove-tssubscription/"]
schema: 2.0.0
title: Remove-TSSubscription
---

# Remove-TSSubscription

## SYNOPSIS
Delete Subscription

## SYNTAX

```
Remove-TSSubscription [-SubscriptionId] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes the specified subscription on Tableau Server or Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
Remove-TSSubscription -SubscriptionId $subscriptionId
```

## PARAMETERS

### -SubscriptionId
The ID of the subscription to delete.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#delete_subscription](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#delete_subscription)

