---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Update Workbook"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauWorkbook/", "/PowerShell/PSTableauREST/set-tableauworkbook/", "/PowerShell/set-tableauworkbook/"]
schema: 2.0.0
title: Set-TableauWorkbook
---

# Set-TableauWorkbook

## SYNOPSIS
Update Workbook

## SYNTAX

```
Set-TableauWorkbook [-WorkbookId] <String> [[-Name] <String>] [[-Description] <String>]
 [[-NewProjectId] <String>] [[-NewOwnerId] <String>] [-ShowTabs] [-RecentlyViewed] [-EncryptExtracts]
 [-EnableDataAcceleration] [-AccelerateNow] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Updates the owner, project or other properties of the specified workbook.

## EXAMPLES

### EXAMPLE 1
```
$workbook = Set-TableauWorkbook -WorkbookId $sampleWorkbookId -ShowTabs:$false
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to update.

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

### -Name
(Optional) The new name for the published workbook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
(Optional) The new description for the published workbook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewProjectId
(Optional) The LUID of the project where the published workbook should be moved.

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

### -NewOwnerId
(Optional) The LUID of the user who should own the workbook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowTabs
(Optional) Boolean, controls if the published workbook shows views in tabs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecentlyViewed
(Optional) Boolean switch, if supplied, the updated workbook will show in the site's recently viewed list.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EncryptExtracts
(Optional) Boolean switch, include to encrypt the embedded extracts.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableDataAcceleration
(Optional) Boolean switch, include to enable data acceleration for the workbook.
Note: this feature is not supported anymore in API 3.16 and higher.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccelerateNow
(Optional) Boolean switch, when acceleration is enabled, start the pre-computation for acceleration immediately when the next backgrounder process becomes available.
Note: this feature is not supported anymore in API 3.16 and higher.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#update_workbook)

