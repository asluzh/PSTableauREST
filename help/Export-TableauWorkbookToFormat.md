# Export-TableauWorkbookToFormat

## SYNOPSIS
Download Workbook as PDF / PowerPoint / Image

## SYNTAX

```
Export-TableauWorkbookToFormat [-WorkbookId] <String> [-Format] <String> [[-PageType] <String>]
 [[-PageOrientation] <String>] [[-MaxAge] <Int32>] [[-OutFile] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Downloads a .pdf containing images of the sheets that the user has permission to view in a workbook
or
Downloads a PowerPoint (.pptx) file containing slides with images of the sheets that the user has permission to view in a workbook
or
Query Workbook Preview Image

## EXAMPLES

### EXAMPLE 1
```
Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format pdf -PageOrientation Landscape -OutFile "export.pdf"
```

### EXAMPLE 2
```
Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format powerpoint -OutFile "export.pptx"
```

### EXAMPLE 3
```
Export-TableauWorkbookToFormat -WorkbookId $sampleWorkbookId -Format image -OutFile "export.png"
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to use as the source.

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
(Optional) The maximum number of minutes a workbook export output will be cached before being refreshed.

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

### -OutFile
(Optional) Filename where the download is saved.
If not provided, the downloaded content is piped to the output.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_pdf](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_pdf)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_powerpoint](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#download_workbook_powerpoint)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_preview_image](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#query_workbook_preview_image)

