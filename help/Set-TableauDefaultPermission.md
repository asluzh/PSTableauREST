---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#add_default_permissions
schema: 2.0.0
title: Set-TableauDefaultPermission
---

# Set-TableauDefaultPermission

## SYNOPSIS
Set (add) Default Permission(s)

## SYNTAX

```
Set-TableauDefaultPermission [-ProjectId] <String> [-PermissionTable] <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Sets the default permission rules granted to users and groups for
workbooks, data sources, flows, data roles, lenses, metrics, databases or tables resources in a specific project.

## EXAMPLES

### EXAMPLE 1
```
$dpt = @{contentType="workbooks"; granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"}}
$dpt += @{contentType="datasources"; granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow";Connect="Allow"}}
$permissions = Set-TableauDefaultPermission -ProjectId $testProjectId -PermissionTable $dpt
```

## PARAMETERS

### -ProjectId
The LUID of the project to set default permissions for.

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

### -PermissionTable
A list of permissions (hashtable), each item must be structured as follows:
- contentType: the specific content type to set the default permission for, e.g.
'workbooks' or 'datasources'
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
Position: 2
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

### System.Object[]
## NOTES
The PermissionTable parameter has similar structure as for Set-TableauContentPermission, but has in addition to provide 'contentType' keys.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#add_default_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#add_default_permissions)

