---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Query Workbooks for User"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_user
redirect_from: ["/PowerShell/PSTableauREST/Get-TSWorkbooksForUser/", "/PowerShell/PSTableauREST/get-tsworkbooksforuser/", "/PowerShell/get-tsworkbooksforuser/"]
schema: 2.0.0
title: Get-TSWorkbooksForUser
---

# Get-TSWorkbooksForUser

## SYNOPSIS
Query Workbooks for User

## SYNTAX

```
Get-TSWorkbooksForUser [-UserId] <String> [-IsOwner] [[-PageSize] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns the workbooks that the specified user owns or has read (view) permissions for.

## EXAMPLES

### EXAMPLE 1
```
$workbooks = Get-TSWorkbooksForUser -UserId (Get-TSCurrentUserId)
```

## PARAMETERS

### -UserId
The LUID of the user to get workbooks for.

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
(Optional) Boolean switch, if supplied, returns only workbooks that the specified user owns.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_user](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_user)

