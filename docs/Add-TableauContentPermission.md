# Add-TableauContentPermission

## SYNOPSIS
Add Workbook / Data Source / View / Project / Flow Permissions

## SYNTAX

### Workbook
```
Add-TableauContentPermission -WorkbookId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Datasource
```
Add-TableauContentPermission -DatasourceId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### View
```
Add-TableauContentPermission -ViewId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Project
```
Add-TableauContentPermission -ProjectId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Flow
```
Add-TableauContentPermission -FlowId <String> -PermissionTable <Hashtable[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds permissions to the specified content for list of grantees (Tableau user or group).
You can specify multiple sets of permissions using one call.

## EXAMPLES

### EXAMPLE 1
```
$permissions = Add-TableauContentPermission -WorkbookId $workbook.id -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Read="Allow"}}
```

### EXAMPLE 2
```
$permissions = Add-TableauContentPermission -FlowId $flow.id -PermissionTable @{granteeType="User"; granteeId=(Get-TableauCurrentUserId); capabilities=@{Execute="Allow"}}
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook to add permissions for.

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
The LUID of the data source to add permissions for.

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
The LUID of the view to add permissions for.

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
The LUID of the project to add permissions for.

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
The LUID of the flow to add permissions for.

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
Note: existing capabilities are not removed.

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
This method uses the corresponding REST API method directly.
This implies that existing permissions which are conflicting with the permissions to be added, the response will be an error.
To fall back to override existing permissions, and to use permission templates, check Set-TableauContentPermission.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_workbook_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_data_source_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_view_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm#query_project_permissions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#query_flow_permissions)

