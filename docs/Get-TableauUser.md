---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Query User On Site / Get Users on Site"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_user_on_site
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauUser/", "/PowerShell/PSTableauREST/get-tableauuser/", "/PowerShell/get-tableauuser/"]
schema: 2.0.0
title: Get-TableauUser
---

# Get-TableauUser

## SYNOPSIS
Query User On Site / Get Users on Site

## SYNTAX

### UserById
```
Get-TableauUser -UserId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Users
```
Get-TableauUser [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the users associated with the specified site, or information about the specified user.

## EXAMPLES

### EXAMPLE 1
```
$user = Get-TableauUser -Filter "name:eq:$userName"
```

## PARAMETERS

### -UserId
Query User On Site: the LUID of the user to get information for.

```yaml
Type: String
Parameter Sets: UserById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional, Get Users on Site)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

```yaml
Type: String[]
Parameter Sets: Users
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional, Get Users on Site)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

```yaml
Type: String[]
Parameter Sets: Users
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional, Get Users on Site)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#get-users_site

```yaml
Type: String[]
Parameter Sets: Users
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, Get Users on Site) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Users
Aliases:

Required: False
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_user_on_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_user_on_site)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_on_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_users_on_site)

