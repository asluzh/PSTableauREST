---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete Workbook / Delete Workbook Revision"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_workbook
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauWorkbook/", "/PowerShell/PSTableauREST/remove-tableauworkbook/", "/PowerShell/remove-tableauworkbook/"]
schema: 2.0.0
title: Remove-TableauWorkbook
---

# Remove-TableauWorkbook

## SYNOPSIS
Delete Workbook / Delete Workbook Revision

## SYNTAX

```
Remove-TableauWorkbook [-WorkbookId] <String> [[-Revision] <Int32>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes a published workbook.
When a workbook is deleted, all of its assets and revisions are also deleted.
If a specific revision is deleted, the workbook is still available.
It's not possible to delete the latest revision of the workbook.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauWorkbook -WorkbookId $sampleWorkbookId
```

### EXAMPLE 2
```
Remove-TableauWorkbook -WorkbookId $sampleWorkbookId -Revision 2
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to remove.

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

### -Revision
(Delete Workbook Revision) The revision number of the workbook to delete.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#delete_workbook)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_workbook_revision](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_workbook_revision)

