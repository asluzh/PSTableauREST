---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Add User to Data-Driven Alert"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#add_user_to_data-driven_alert
redirect_from: ["/PowerShell/PSTableauREST/Add-TSUserToDataAlert/", "/PowerShell/PSTableauREST/add-tsusertodataalert/", "/PowerShell/add-tsusertodataalert/"]
schema: 2.0.0
title: Add-TSUserToDataAlert
---

# Add-TSUserToDataAlert

## SYNOPSIS
Add User to Data-Driven Alert

## SYNTAX

```
Add-TSUserToDataAlert [-DataAlertId] <String> [-UserId] <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds a specified user to the recipients list for a data-driven alert.

## EXAMPLES

### EXAMPLE 1
```
Add-TSUserToDataAlert -DataAlertId $id -UserId (Get-TSCurrentUserId)
```

## PARAMETERS

### -DataAlertId
The LUID of the data-driven alert.

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

### -UserId
The LUID of the user to add to the data-driven alert.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#add_user_to_data-driven_alert](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#add_user_to_data-driven_alert)

