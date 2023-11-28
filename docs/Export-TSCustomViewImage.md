---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get Custom View Image"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view_image
redirect_from: ["/PowerShell/PSTableauREST/Export-TSCustomViewImage/", "/PowerShell/PSTableauREST/export-tscustomviewimage/", "/PowerShell/export-tscustomviewimage/"]
schema: 2.0.0
title: Export-TSCustomViewImage
---

# Export-TSCustomViewImage

## SYNOPSIS
Get Custom View Image

## SYNTAX

```
Export-TSCustomViewImage [-CustomViewId] <String> [[-MaxAge] <Int32>] [[-Resolution] <String>]
 [[-OutFile] <String>] [[-ViewFilters] <Hashtable>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Downloads a .png format image file of a specified custom view.

## EXAMPLES

### EXAMPLE 1
```
Export-TSCustomViewImage -CustomViewId $id -OutFile "export.png" -Resolution high
```

## PARAMETERS

### -CustomViewId
The LUID of the custom view.

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

### -MaxAge
(Optional) The maximum number of minutes a view export output will be cached before being refreshed.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 3
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
Position: 4
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
Position: 5
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view_image](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#get_custom_view_image)

