---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete Workbook / Data Source / View / Project / Flow Permission"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_workbook_permission
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauContentPermission/", "/PowerShell/PSTableauREST/remove-tableaucontentpermission/", "/PowerShell/remove-tableaucontentpermission/"]
schema: 2.0.0
title: Remove-TableauContentPermission
---

# Remove-TableauContentPermission

## SYNOPSIS
Delete Workbook / Data Source / View / Project / Flow Permission

## SYNTAX

### WorkbookOne
```
Remove-TableauContentPermission -WorkbookId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### WorkbookAllGrantee
```
Remove-TableauContentPermission -WorkbookId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### WorkbookAll
```
Remove-TableauContentPermission -WorkbookId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### DatasourceOne
```
Remove-TableauContentPermission -DatasourceId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### DatasourceAllGrantee
```
Remove-TableauContentPermission -DatasourceId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### DatasourceAll
```
Remove-TableauContentPermission -DatasourceId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### ViewOne
```
Remove-TableauContentPermission -ViewId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ViewAllGrantee
```
Remove-TableauContentPermission -ViewId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ViewAll
```
Remove-TableauContentPermission -ViewId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### ProjectOne
```
Remove-TableauContentPermission -ProjectId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ProjectAllGrantee
```
Remove-TableauContentPermission -ProjectId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ProjectAll
```
Remove-TableauContentPermission -ProjectId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### FlowOne
```
Remove-TableauContentPermission -FlowId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### FlowAllGrantee
```
Remove-TableauContentPermission -FlowId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### FlowAll
```
Remove-TableauContentPermission -FlowId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes the specified permission (or all permissions) from the specified content for a specific grantee or all grantees.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauContentPermission -WorkbookId $sampleWorkbookId -All
```

### EXAMPLE 2
```
Remove-TableauContentPermission -DatasourceId $datasource.id -GranteeType User -GranteeId (Get-TableauCurrentUserId)
```

### EXAMPLE 3
```
Remove-TableauContentPermission -FlowId $flow.id -GranteeType User -GranteeId (Get-TableauCurrentUserId) -CapabilityName Execute -CapabilityMode Allow
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to set permissions for.

```yaml
Type: String
Parameter Sets: WorkbookOne, WorkbookAllGrantee, WorkbookAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatasourceId
The LUID of the data source to set permissions for.

```yaml
Type: String
Parameter Sets: DatasourceOne, DatasourceAllGrantee, DatasourceAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ViewId
The LUID of the view to set permissions for.

```yaml
Type: String
Parameter Sets: ViewOne, ViewAllGrantee, ViewAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectId
The LUID of the project to set permissions for.

```yaml
Type: String
Parameter Sets: ProjectOne, ProjectAllGrantee, ProjectAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FlowId
The LUID of the flow to set permissions for.

```yaml
Type: String
Parameter Sets: FlowOne, FlowAllGrantee, FlowAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GranteeType
Delete permission(s) for specific grantee: the grantee type (User or Group).

```yaml
Type: String
Parameter Sets: WorkbookOne, WorkbookAllGrantee, DatasourceOne, DatasourceAllGrantee, ViewOne, ViewAllGrantee, ProjectOne, ProjectAllGrantee, FlowOne, FlowAllGrantee
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GranteeId
Delete permission(s) for specific grantee: the LUID of the user or group.

```yaml
Type: String
Parameter Sets: WorkbookOne, WorkbookAllGrantee, DatasourceOne, DatasourceAllGrantee, ViewOne, ViewAllGrantee, ProjectOne, ProjectAllGrantee, FlowOne, FlowAllGrantee
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CapabilityName
Delete permission(s) for specific grantee: the name of the capability to remove.
If this parameter is not provided, all existing permissions for the grantee will be deleted.

```yaml
Type: String
Parameter Sets: WorkbookOne, DatasourceOne, ViewOne, ProjectOne, FlowOne
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CapabilityMode
Delete permission(s) for specific grantee: the mode of the capability to remove (Allow or Deny).
If this parameter is not provided, all existing permissions for the grantee will be deleted.

```yaml
Type: String
Parameter Sets: WorkbookOne, DatasourceOne, ViewOne, ProjectOne, FlowOne
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Explicit boolean switch, supply this to delete ALL permissions for ALL grantees.

```yaml
Type: SwitchParameter
Parameter Sets: WorkbookAll, DatasourceAll, ViewAll, ProjectAll, FlowAll
Aliases:

Required: True
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

## NOTES
This function always returns $null.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_workbook_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_workbook_permission)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_data_source_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_data_source_permission)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_view_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_view_permission)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_project_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_project_permission)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#delete_flow_permission)

