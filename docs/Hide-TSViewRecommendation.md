---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Hide a Recommendation for a View"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#hide_view_recommendation
redirect_from: ["/PowerShell/PSTableauREST/Hide-TSViewRecommendation/", "/PowerShell/PSTableauREST/hide-tsviewrecommendation/", "/PowerShell/hide-tsviewrecommendation/"]
schema: 2.0.0
title: Hide-TSViewRecommendation
---

# Hide-TSViewRecommendation

## SYNOPSIS
Hide a Recommendation for a View

## SYNTAX

```
Hide-TSViewRecommendation [-ViewId] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Hides a view from being recommended by the server by adding it to a list of views that are dismissed for a user.

## EXAMPLES

### EXAMPLE 1
```
Hide-TSViewRecommendation -ViewId $viewId
```

## PARAMETERS

### -ViewId
The LUID of the view to be added to the list of views hidden from recommendation for a user.

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

### System.String
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#hide_view_recommendation](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#hide_view_recommendation)

