---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get Custom View / List Custom Views"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view
redirect_from: ["/PowerShell/PSTableauREST/Get-TSCustomView/", "/PowerShell/PSTableauREST/get-tscustomview/", "/PowerShell/get-tscustomview/"]
schema: 2.0.0
title: Get-TSCustomView
---

# Get-TSCustomView

## SYNOPSIS
Get Custom View / List Custom Views

## SYNTAX

### CustomViewById
```
Get-TSCustomView -CustomViewId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### CustomViews
```
Get-TSCustomView [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the details of a specified custom view, or a list of custom views on a site.

## EXAMPLES

### EXAMPLE 1
```
$customView = Get-TSCustomView -CustomViewId $id
```

### EXAMPLE 2
```
$views = Get-TSCustomView -Filter "name:eq:Overview"
```

## PARAMETERS

### -CustomViewId
(Get Custom View) The LUID for the custom view.

```yaml
Type: String
Parameter Sets: CustomViewById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views
Also: Get View by Path - use Get-TSView with filter viewUrlName:eq:\<url\>

```yaml
Type: String[]
Parameter Sets: CustomViews
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#views

```yaml
Type: String[]
Parameter Sets: CustomViews
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_views_site

```yaml
Type: String[]
Parameter Sets: CustomViews
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: CustomViews
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_custom_views](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_custom_views)

