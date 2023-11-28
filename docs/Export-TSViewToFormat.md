---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Query View PDF / Image / Data"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_pdf
redirect_from: ["/PowerShell/PSTableauREST/Export-TSViewToFormat/", "/PowerShell/PSTableauREST/export-tsviewtoformat/", "/PowerShell/export-tsviewtoformat/"]
schema: 2.0.0
title: Export-TSViewToFormat
---

# Export-TSViewToFormat

## SYNOPSIS
Query View PDF / Image / Data

## SYNTAX

```
Export-TSViewToFormat [-ViewId] <String> [-Format] <String> [[-PageType] <String>]
 [[-PageOrientation] <String>] [[-MaxAge] <Int32>] [[-VizWidth] <Int32>] [[-VizHeight] <Int32>]
 [[-Resolution] <String>] [[-OutFile] <String>] [[-ViewFilters] <Hashtable>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a specified view rendered as a .pdf file.
or
Returns an image of the specified view.
or
Returns a specified view rendered as data in comma-separated-value (CSV) format.

## EXAMPLES

### EXAMPLE 1
```
Export-TSViewToFormat -ViewId $sampleViewId -Format pdf -OutFile "export.pdf" -ViewFilters @{Region="Europe"}
```

### EXAMPLE 2
```
Export-TSViewToFormat -ViewId $sampleViewId -Format image -OutFile "export.png" -Resolution high
```

### EXAMPLE 3
```
Export-TSViewToFormat -ViewId $sampleViewId -Format csv -OutFile "export.csv" -ViewFilters @{"Ease of Business (clusters)"="Low"}
```

## PARAMETERS

### -ViewId
The LUID of the view to export.

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

### -Format
The output format of the export: pdf, powerpoint or image.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: A4
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced.
The value can be Portrait or Landscape.
Default is Portrait.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Portrait
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxAge
(Optional) The maximum number of minutes a view export output will be cached before being refreshed.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -VizWidth
The width of the rendered pdf image in pixels, these parameter determine its resolution and aspect ratio.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -VizHeight
The height of the rendered pdf image in pixels, these parameter determine its resolution and aspect ratio.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resolution
The resolution of the image (high/standard).
Image width and actual pixel density are determined by the display context of the image.
Aspect ratio is always preserved.
Set the value to high to ensure maximum pixel density.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: High
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ViewFilters
Filter expression to modify the view data returned.
The expression uses fields in the underlying workbook data to define the filter.
To filter a view using a field, add one or more query parameters to your method call, structured as key=value pairs, prefaced by the constant 'vf_'
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#Filter-query-views

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_pdf](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_pdf)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_image](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_image)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_data](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_view_data)

