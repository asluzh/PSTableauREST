---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Delete Workbook / Data Source / View / Project / Flow from Favorites"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_workbook_from_favorites
redirect_from: ["/PowerShell/PSTableauREST/Remove-TSUserFavorite/", "/PowerShell/PSTableauREST/remove-tsuserfavorite/", "/PowerShell/remove-tsuserfavorite/"]
schema: 2.0.0
title: Remove-TSUserFavorite
---

# Remove-TSUserFavorite

## SYNOPSIS
Delete Workbook / Data Source / View / Project / Flow from Favorites

## SYNTAX

### Workbook
```
Remove-TSUserFavorite -UserId <String> -WorkbookId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Datasource
```
Remove-TSUserFavorite -UserId <String> -DatasourceId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### View
```
Remove-TSUserFavorite -UserId <String> -ViewId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Project
```
Remove-TSUserFavorite -UserId <String> -ProjectId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Flow
```
Remove-TSUserFavorite -UserId <String> -FlowId <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes the specified content to a user's favorites.

## EXAMPLES

### EXAMPLE 1
```
Remove-TSUserFavorite -UserId (Get-TSCurrentUserId) -WorkbookId $workbook.id
```

## PARAMETERS

### -UserId
The LUID of the user to remove favorite for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkbookId
The LUID of the workbook to remove from favorite.

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
The LUID of the data source to remove from favorite.

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

### -ViewId
The LUID of the view to remove from favorite.

```yaml
Type: String
Parameter Sets: View
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectId
The LUID of the project to remove from favorite.

```yaml
Type: String
Parameter Sets: Project
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FlowId
The LUID of the flow to remove from favorite.

```yaml
Type: String
Parameter Sets: Flow
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_workbook_from_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_workbook_from_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_data_source_from_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_data_source_from_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_view_from_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_view_from_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_project_from_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#delete_project_from_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#ref_delete_flow_from_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#ref_delete_flow_from_favorites)

