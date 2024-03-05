# Get-TableauDatasource

## SYNOPSIS
Query Data Source / Query Data Sources / Get Data Source Revisions

## SYNTAX

### DatasourceRevisions
```
Get-TableauDatasource -DatasourceId <String> [-Revisions] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DatasourceById
```
Get-TableauDatasource -DatasourceId <String> [-Revisions] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Datasources
```
Get-TableauDatasource [-Revisions] [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>]
 [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified data source or data sources.

## EXAMPLES

### EXAMPLE 1
```
$datasource = Get-TableauDatasource -DatasourceId $datasourceId
```

### EXAMPLE 2
```
$dsRevisions = Get-TableauDatasource -DatasourceId $datasourceId -Revisions
```

### EXAMPLE 3
```
$datasources = Get-TableauDatasource -Filter "name:eq:$datasourceName" -Sort name:asc -Fields id,name
```

## PARAMETERS

### -DatasourceId
(Query Data Source by Id) The LUID of the data source.

```yaml
Type: String
Parameter Sets: DatasourceRevisions, DatasourceById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Revisions
(Get Data Source Revisions) Boolean switch, if supplied, the data source revisions are returned.

```yaml
Type: SwitchParameter
Parameter Sets: DatasourceRevisions
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: DatasourceById, Datasources
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#datasources

```yaml
Type: String[]
Parameter Sets: Datasources
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#datasources

```yaml
Type: String[]
Parameter Sets: Datasources
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_datasources

```yaml
Type: String[]
Parameter Sets: Datasources
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
Parameter Sets: DatasourceRevisions, Datasources
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_source)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_sources](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#query_data_sources)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#get_data_source_revisions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#get_data_source_revisions)

