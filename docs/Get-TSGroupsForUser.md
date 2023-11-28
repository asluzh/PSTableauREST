---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get Groups for a User"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_groups_for_a_user
redirect_from: ["/PowerShell/PSTableauREST/Get-TSGroupsForUser/", "/PowerShell/PSTableauREST/get-tsgroupsforuser/", "/PowerShell/get-tsgroupsforuser/"]
schema: 2.0.0
title: Get-TSGroupsForUser
---

# Get-TSGroupsForUser

## SYNOPSIS
Get Groups for a User

## SYNTAX

```
Get-TSGroupsForUser [-UserId] <String> [[-PageSize] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets a list of groups of which the specified user is a member.

## EXAMPLES

### EXAMPLE 1
```
$groups = Get-TSGroupsForUser -UserId $selectedUserId
```

## PARAMETERS

### -UserId
The LUID of the user whose group memberships are listed.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_groups_for_a_user](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_groups_for_a_user)

