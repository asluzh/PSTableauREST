# Remove-TableauDefaultPermission

## SYNOPSIS
Delete Default Permission(s)

## SYNTAX

### OneCapability
```
Remove-TableauDefaultPermission -ProjectId <String> -GranteeType <String> -GranteeId <String>
 -CapabilityName <String> -CapabilityMode <String> -ContentType <String> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### OneGranteeForContentType
```
Remove-TableauDefaultPermission -ProjectId <String> -GranteeType <String> -GranteeId <String>
 -ContentType <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### OneGrantee
```
Remove-TableauDefaultPermission -ProjectId <String> -GranteeType <String> -GranteeId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AllPermissions
```
Remove-TableauDefaultPermission -ProjectId <String> [-All] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes the specific default permission rules granted to users and groups for
workbooks, data sources, flows, data roles, lenses, metrics, databases or tables resources in a specific project.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauDefaultPermission -ProjectId $projectId -GranteeType User -GranteeId (Get-TableauCurrentUserId)
```

### EXAMPLE 2
```
Remove-TableauDefaultPermission -ProjectId $projectId -GranteeType Group -GranteeId $groupId -ContentType workbooks
```

### EXAMPLE 3
```
Remove-TableauDefaultPermission -ProjectId $project.id -All
```

## PARAMETERS

### -ProjectId
The LUID of the project to delete default permissions for.

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

### -GranteeType
Delete default permission(s) for specific grantee: the grantee type (User or Group).

```yaml
Type: String
Parameter Sets: OneCapability, OneGranteeForContentType, OneGrantee
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GranteeId
Delete default permission(s) for specific grantee: the LUID of the user or group.

```yaml
Type: String
Parameter Sets: OneCapability, OneGranteeForContentType, OneGrantee
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CapabilityName
Delete default permission(s) for specific grantee: the name of the capability to remove.
If this parameter is not provided, all existing permissions for the grantee will be deleted.

```yaml
Type: String
Parameter Sets: OneCapability
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CapabilityMode
Delete default permission(s) for specific grantee: the mode of the capability to remove (Allow or Deny).
If this parameter is not provided, all existing permissions for the grantee will be deleted.

```yaml
Type: String
Parameter Sets: OneCapability
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentType
Specific content type to delete default permission(s) for.
If omitted, default permissions for all content types are deleted (for specific grantees or all grantees).

```yaml
Type: String
Parameter Sets: OneCapability, OneGranteeForContentType
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Explicit boolean switch, supply this to delete ALL permissions for ALL grantees and ALL content types.

```yaml
Type: SwitchParameter
Parameter Sets: AllPermissions
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_default_permission](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#delete_default_permission)

