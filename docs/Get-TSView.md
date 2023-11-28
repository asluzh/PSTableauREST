---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get View / Query Views for Site / Query Views for Workbook"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_view
redirect_from: ["/PowerShell/PSTableauREST/Get-TSView/", "/PowerShell/PSTableauREST/get-tsview/", "/PowerShell/get-tsview/"]
schema: 2.0.0
title: Get-TSView
---

# Get-TSView

## SYNOPSIS
Get View / Query Views for Site / Query Views for Workbook

## SYNTAX

### ViewById
```
Get-TSView -ViewId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ViewsInWorkbook
```
Get-TSView -WorkbookId <String> [-IncludeUsageStatistics] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Views
```
Get-TSView [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns all the views for the specified site or workbook, or gets the details of a specific view.

## EXAMPLES

### EXAMPLE 1
```
$view = Get-TSView -ViewId $viewId
```

### EXAMPLE 2
```
$views = Get-TSView -Filter "name:eq:$viewName" -Sort name:asc -Fields id,name
```

### EXAMPLE 3
```
$viewsInWorkbook = Get-TSView -WorkbookId $workbookId -IncludeUsageStatistics
```

## PARAMETERS

### -ViewId
Get View: The LUID of the view whose details are requested.

```yaml
Type: String
Parameter Sets: ViewById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkbookId
Query Views for Workbook: The LUID of the workbook to get the views for.

```yaml
Type: String
Parameter Sets: ViewsInWorkbook
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeUsageStatistics
Query Views: include this boolean switch to return usage statistics with the views in response.

```yaml
Type: SwitchParameter
Parameter Sets: ViewsInWorkbook
Aliases:

Required: False
Position: Named
Default value: False
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
Parameter Sets: Views
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
Parameter Sets: Views
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
Parameter Sets: Views
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
Parameter Sets: Views
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_view](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_view)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_site)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_views_for_workbook)

