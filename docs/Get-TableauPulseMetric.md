# Get-TableauPulseMetric

## SYNOPSIS
List metrics in definition
or
Batch list metrics
or
Get metric

## SYNTAX

### ListMetrics
```
Get-TableauPulseMetric -DefinitionId <String> [-SortByName] [-OrderBy <String[]>] [-Filter <String[]>]
 [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### GetMetrics
```
Get-TableauPulseMetric -MetricId <String[]> [-SortByName] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Lists the metrics contained in a metric definition.
or
Gets a batch of metrics from a definition, specified in a comma delimited list.
or
Gets the details of the specified metric.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$defs = Get-TableauPulseMetric
```

### EXAMPLE 2
```
$def = Get-TableauPulseMetric -MetricId $id
```

## PARAMETERS

### -DefinitionId
(Optional) The LUID of the metric definition.
If definition ID is provided, List metrics in definition is called.
Otherwise, Batch list metrics or Get metric is called.

```yaml
Type: String
Parameter Sets: ListMetrics
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MetricId
(Optional) The LUID(s) of the metric.
If one metric ID is provided, Get metric is called.
If more than one definition ID is provided, Batch list metrics is called.

```yaml
Type: String[]
Parameter Sets: GetMetrics
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SortByName
(Optional) Switch parameter, when provided, the output metrics are sorted by name.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
(Optional) The sorting method for items returned, based on the popularity of the item.

```yaml
Type: String[]
Parameter Sets: ListMetrics
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional) An expression to filter the response using one or multiple attributes.

```yaml
Type: String[]
Parameter Sets: ListMetrics
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Specifies the number of results in a paged response.

```yaml
Type: Int32
Parameter Sets: ListMetrics
Aliases:

Required: False
Position: Named
Default value: 0
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
A metric is the interactive object that users follow and receive updates on.
It specifies the values to give the filterable dimensions of the metric's definition and the measurement time period of the metric.
Example: A user or REST request could filter the metric, and its automatically generated insights, based on the West region and product line sold.
The insight provided might call out that discounted sales have risen sharply in a region between last quarter and the current one.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_ListMetrics](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_ListMetrics)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_BatchGetMetrics](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_BatchGetMetrics)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_GetMetric](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_GetMetric)

