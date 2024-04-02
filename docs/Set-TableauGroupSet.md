# Set-TableauGroupSet

## SYNOPSIS
Update Group Set

## SYNTAX

```
Set-TableauGroupSet [-GroupSetId] <String> [[-Name] <String>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates a group set name on a Tableau Server or Tableau Cloud site.
If a Tableau Server or Tableau Cloud site is configured to use local authentication, the method lets you update the group name.
If Tableau Server is configured to use Active Directory authentication, the method synchronizes the group with Active Directory.

## EXAMPLES

### EXAMPLE 1
```
$groupset = Set-TableauGroupSet -GroupSetId $groupSetId -Name $newName
```

## PARAMETERS

### -GroupSetId
The LUID of the group set to update.

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
(Optional) The new name for the group set.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#update_group_set](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#update_group_set)

