# Get-TableauTableColumn

## SYNOPSIS
Query Column in a Table / Query Columns in a Table

## SYNTAX

### ColumnById
```
Get-TableauTableColumn -TableId <String> -ColumnId <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Columns
```
Get-TableauTableColumn -TableId <String> [-PageSize <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get information about a column in a table asset, or a list of column assets.

## EXAMPLES

### EXAMPLE 1
```
$columns = Get-TableauTableColumn -TableId $id
```

## PARAMETERS

### -TableId
The LUID of the table.

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

### -ColumnId
Query Column in a Table: The LUID of the column.

```yaml
Type: String
Parameter Sets: ColumnById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, Query Columns in a Table) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Columns
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_column](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_column)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_columns](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_metadata.htm#query_columns)

