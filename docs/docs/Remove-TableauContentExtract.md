---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete the Extract from a Data Source / Delete Extracts of Embedded Data Sources from a Workbook"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extracts_from_workbook
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauContentExtract/", "/PowerShell/PSTableauREST/remove-tableaucontentextract/", "/PowerShell/remove-tableaucontentextract/"]
schema: 2.0.0
title: Remove-TableauContentExtract
---

# Remove-TableauContentExtract

## SYNOPSIS
Delete the Extract from a Data Source / Delete Extracts of Embedded Data Sources from a Workbook

## SYNTAX

### Workbook
```
Remove-TableauContentExtract -WorkbookId <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Datasource
```
Remove-TableauContentExtract -DatasourceId <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes the extract(s) inside a published data source or workbook.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauContentExtract -WorkbookId = $workbookId
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook whose extract(s) are to be deleted.
Either workbook ID or data source ID needs to be provided.

```yaml
Type: String
Parameter Sets: Workbook
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatasourceId
The LUID of the datasource whose extract is to be deleted.
Either workbook ID or data source ID needs to be provided.

```yaml
Type: String
Parameter Sets: Datasource
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extracts_from_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extracts_from_workbook)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extract_from_datasource](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#delete_extract_from_datasource)

