---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Set Workbook / Data Source / View / Project / Flow Permissions"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauContentPermission/", "/PowerShell/PSTableauREST/set-tableaucontentpermission/", "/PowerShell/set-tableaucontentpermission/"]
schema: 2.0.0
title: Set-TableauContentPermission
---

# Set-TableauContentPermission

## SYNOPSIS
Set Workbook / Data Source / View / Project / Flow Permissions

## SYNTAX

### Workbook
```
Set-TableauContentPermission -WorkbookId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Datasource
```
Set-TableauContentPermission -DatasourceId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### View
```
Set-TableauContentPermission -ViewId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Project
```
Set-TableauContentPermission -ProjectId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Flow
```
Set-TableauContentPermission -FlowId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Sets permissions to the specified content for list of grantees (Tableau user or group).
This method is a wrapper for Set-TableauContentPermission with support for overriding conflicting permissions and permission templates.
You can specify multiple sets of permissions using one call, and use permission templates (similar to Tableau Server UI).

## EXAMPLES

### EXAMPLE 1
```
$permissions = Set-TableauContentPermission -ProjectId $projectId -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"}}
```

### EXAMPLE 2
```
$permissions = Set-TableauContentPermission -DatasourceId $datasourceId -PermissionTable @{granteeType="Group"; granteeId=$groupId; template='Publish'}
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to set permissions for.

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
The LUID of the data source to set permissions for.

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
The LUID of the view to set permissions for.

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
The LUID of the project to set permissions for.

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
The LUID of the flow to set permissions for.

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

### -PermissionTable
A list of permissions (hashtable), each item must be structured as follows:
- granteeType: 'user' or 'group'
- granteeId: the LUID of the user or group
- capabilities: hashtable with all permissions to add, the key is capability name and the value is allow or deny
Note: existing capabilities are removed for the same capability names, but other capabilities are untouched.
- template: can be used instead of 'capabilities'.
This corresponds to selecting "Template" in Tableau Server UI.
The following templates are supported: View, Explore, Publish, Administer, Denied, None
Note: existing capabilities are removed for the grantee, if template is used.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
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
This method is similar to Add-TableauContentPermission, but it can also override existing permissions, and supports permission templates.

## RELATED LINKS
