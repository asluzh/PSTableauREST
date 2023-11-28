---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Query Workbook / Data Source / View / Project / Flow Permissions"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions
redirect_from: ["/PowerShell/PSTableauREST/Get-TSContentPermission/", "/PowerShell/PSTableauREST/get-tscontentpermission/", "/PowerShell/get-tscontentpermission/"]
schema: 2.0.0
title: Get-TSContentPermission
---

# Get-TSContentPermission

## SYNOPSIS
Query Workbook / Data Source / View / Project / Flow Permissions

## SYNTAX

### Workbook
```
Get-TSContentPermission -WorkbookId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Datasource
```
Get-TSContentPermission -DatasourceId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### View
```
Get-TSContentPermission -ViewId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Project
```
Get-TSContentPermission -ProjectId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Flow
```
Get-TSContentPermission -FlowId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of permissions for the specific workbook (or data source / view / project / flow).

## EXAMPLES

### EXAMPLE 1
```
$permissions = Get-TSContentPermission -WorkbookId $workbookId
```

### EXAMPLE 2
```
$permissions = Get-TSContentPermission -DatasourceId $datasourceId
```

### EXAMPLE 3
```
$permissions = Get-TSContentPermission -ProjectId $project.id
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to get permissions for.

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
The LUID of the data source to get permissions for.

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
The LUID of the view to get permissions for.

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
The LUID of the project to get permissions for.

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
The LUID of the flow to get permissions for.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions)

