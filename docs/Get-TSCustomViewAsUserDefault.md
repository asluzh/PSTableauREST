---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "List Users with Custom View as Default"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default
redirect_from: ["/PowerShell/PSTableauREST/Get-TSCustomViewAsUserDefault/", "/PowerShell/PSTableauREST/get-tscustomviewasuserdefault/", "/PowerShell/get-tscustomviewasuserdefault/"]
schema: 2.0.0
title: Get-TSCustomViewAsUserDefault
---

# Get-TSCustomViewAsUserDefault

## SYNOPSIS
List Users with Custom View as Default

## SYNTAX

```
Get-TSCustomViewAsUserDefault [-CustomViewId] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets the list of users whose default view is the specified custom view.

## EXAMPLES

### EXAMPLE 1
```
$users = Get-TSCustomViewAsUserDefault -CustomViewId $id
```

## PARAMETERS

### -CustomViewId
The LUID for the custom view.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default)

