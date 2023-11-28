---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get Users in Group"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_in_group
redirect_from: ["/PowerShell/PSTableauREST/Get-TSUsersInGroup/", "/PowerShell/PSTableauREST/get-tsusersingroup/", "/PowerShell/get-tsusersingroup/"]
schema: 2.0.0
title: Get-TSUsersInGroup
---

# Get-TSUsersInGroup

## SYNOPSIS
Get Users in Group

## SYNTAX

```
Get-TSUsersInGroup [-GroupId] <String> [[-PageSize] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets a list of users in the specified group.

## EXAMPLES

### EXAMPLE 1
```
$users = Get-TSUsersInGroup -GroupId $groupId
```

## PARAMETERS

### -GroupId
The LUID of the group to get the users for.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_in_group](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_in_group)

