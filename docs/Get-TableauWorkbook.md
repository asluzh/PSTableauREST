---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Get Workbook / Workbooks on Site / Workbook Revisions"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_site
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauWorkbook/", "/PowerShell/PSTableauREST/get-tableauworkbook/", "/PowerShell/get-tableauworkbook/"]
schema: 2.0.0
title: Get-TableauWorkbook
---

# Get-TableauWorkbook

## SYNOPSIS
Get Workbook / Workbooks on Site / Workbook Revisions

## SYNTAX

### WorkbookRevisions
```
Get-TableauWorkbook -WorkbookId <String> [-Revisions] [-PageSize <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### WorkbookById
```
Get-TableauWorkbook -WorkbookId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WorkbookByContentUrl
```
Get-TableauWorkbook -ContentUrl <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Workbooks
```
Get-TableauWorkbook [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified workbook, or workbooks on a site.

## EXAMPLES

### EXAMPLE 1
```
$workbook = Get-TableauWorkbook -WorkbookId $workbookId
```

### EXAMPLE 2
```
$workbookRevisions = Get-TableauWorkbook -WorkbookId $workbookId -Revisions
```

### EXAMPLE 3
```
$workbooks = Get-TableauWorkbook -Filter "name:eq:$workbookName" -Sort name:asc -Fields id,name
```

## PARAMETERS

### -WorkbookId
Get Workbook by Id: The LUID of the workbook.

```yaml
Type: String
Parameter Sets: WorkbookRevisions, WorkbookById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentUrl
Get Workbook by Content URL: The content URL of the workbook.

```yaml
Type: String
Parameter Sets: WorkbookByContentUrl
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Revisions
(Get Workbook Revisions) Boolean switch, if supplied, the workbook revisions are returned.

```yaml
Type: SwitchParameter
Parameter Sets: WorkbookRevisions
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#workbooks

```yaml
Type: String[]
Parameter Sets: Workbooks
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#workbooks

```yaml
Type: String[]
Parameter Sets: Workbooks
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_workbooks_site

```yaml
Type: String[]
Parameter Sets: Workbooks
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
Parameter Sets: WorkbookRevisions, Workbooks
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbooks_for_site)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_revisions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_workbook_revisions)

