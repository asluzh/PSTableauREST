# Get-TableauGroupSet

## SYNOPSIS
Query Group Sets
or
Get Group Set

## SYNTAX

### GroupsetById
```
Get-TableauGroupSet -GroupSetId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Groupsets
```
Get-TableauGroupSet [-ResultLevel <String>] [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>]
 [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Lists all group sets matching optional filter and ordered by optional sort expression.
or
Returns information about the specified group set including ID, name, and member groups.

## EXAMPLES

### EXAMPLE 1
```
$group = Get-TableauGroupSet -Filter "name:eq:$groupSet"
```

## PARAMETERS

### -GroupSetId
Get Group Set: specifies the LUID of the group set.

```yaml
Type: String
Parameter Sets: GroupsetById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResultLevel
(Optional) tbd

```yaml
Type: String
Parameter Sets: Groupsets
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#groups

```yaml
Type: String[]
Parameter Sets: Groupsets
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#groups

```yaml
Type: String[]
Parameter Sets: Groupsets
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_groups

```yaml
Type: String[]
Parameter Sets: Groupsets
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Groupsets
Aliases:

Required: False
Position: Named
Default value: 100
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_group_sets](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#query_group_sets)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_group_set](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#get_group_set)

