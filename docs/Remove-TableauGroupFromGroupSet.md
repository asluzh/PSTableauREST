# Remove-TableauGroupFromGroupSet

## SYNOPSIS
Remove Group from Group Set

## SYNTAX

```
Remove-TableauGroupFromGroupSet [-GroupId] <String> [-GroupSetId] <String> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes a group from the specified group set.

## EXAMPLES

### EXAMPLE 1
```
$response = Remove-TableauGroupFromGroupSet -GroupId $groupId -GroupSetId $gsId
```

## PARAMETERS

### -GroupId
The LUID of the group to remove.

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

### -GroupSetId
The LUID of the group set to remove the group from.

```yaml
Type: String
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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#remove_group_from_group_set](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#remove_group_from_group_set)

