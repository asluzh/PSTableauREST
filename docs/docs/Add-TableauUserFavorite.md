---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Add Workbook / Data Source / View / Project / Flow to Favorites"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_workbook_to_favorites
redirect_from: ["/PowerShell/PSTableauREST/Add-TableauUserFavorite/", "/PowerShell/PSTableauREST/add-tableauuserfavorite/", "/PowerShell/add-tableauuserfavorite/"]
schema: 2.0.0
title: Add-TableauUserFavorite
---

# Add-TableauUserFavorite

## SYNOPSIS
Add Workbook / Data Source / View / Project / Flow to Favorites

## SYNTAX

### Workbook
```
Add-TableauUserFavorite -UserId <String> [-Label <String>] -WorkbookId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Datasource
```
Add-TableauUserFavorite -UserId <String> [-Label <String>] -DatasourceId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### View
```
Add-TableauUserFavorite -UserId <String> [-Label <String>] -ViewId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Project
```
Add-TableauUserFavorite -UserId <String> [-Label <String>] -ProjectId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Flow
```
Add-TableauUserFavorite -UserId <String> [-Label <String>] -FlowId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds the specified content to a user's favorites.

## EXAMPLES

### EXAMPLE 1
```
Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -WorkbookId $workbook.id -Label $workbook.name
```

### EXAMPLE 2
```
Add-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -ProjectId $reportsProjectId
```

## PARAMETERS

### -UserId
The LUID of the user to add the favorite for.

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

### -Label
(Optional) A label to assign to the favorite.
This value is displayed when you search for favorites on the server.
Note: label has to be unique for the content type, if an existing label is supplied, an error is returned.
If label is omitted, the content ID is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkbookId
The LUID of the workbook to add as a favorite.

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
The LUID of the data source to add as a favorite.

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
The LUID of the view to add as a favorite.

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
The LUID of the project to add as a favorite.

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
The LUID of the flow to add as a favorite.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_workbook_to_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_workbook_to_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_data_source_to_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_data_source_to_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_view_to_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_view_to_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_project_to_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_project_to_favorites)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_flow_to_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#add_flow_to_favorites)

