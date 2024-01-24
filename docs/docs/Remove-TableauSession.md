---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete Server Session"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#delete_server_session
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauSession/", "/PowerShell/PSTableauREST/remove-tableausession/", "/PowerShell/remove-tableausession/"]
schema: 2.0.0
title: Remove-TableauSession
---

# Remove-TableauSession

## SYNOPSIS
Delete Server Session

## SYNTAX

```
Remove-TableauSession [-SessionId] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes a specified session.
This method is not available for Tableau Cloud and is typically used in programmatic management of the life cycles of embedded Tableau sessions.

## EXAMPLES

### EXAMPLE 1
```
$response = Remove-TableauSession -SessionId $id
```

## PARAMETERS

### -SessionId
The session ID to be deleted.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#delete_server_session](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#delete_server_session)

