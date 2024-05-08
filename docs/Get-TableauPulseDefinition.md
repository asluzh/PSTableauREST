# Get-TableauPulseDefinition

## SYNOPSIS
List metric definitions
or
Batch list metric definitions
or
Get metric definition

## SYNTAX

### GetDefinitions
```
Get-TableauPulseDefinition -DefinitionId <String[]> [-DefinitionViewType <String>] [-NumberOfMetrics <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ListDefinitions
```
Get-TableauPulseDefinition [-DefinitionViewType <String>] [-NumberOfMetrics <Int32>] [-Filter <String[]>]
 [-OrderBy <String[]>] [-MetricId <String>] [-PageSize <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Lists the metric definitions configured for a site or, optionally, the details and definition for a specific metric.
or
Gets a batch of metric definitions and metrics available on a site.
or
Gets a metric definition and optionally metrics it contains.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$defs = Get-TableauPulseDefinition
```

### EXAMPLE 2
```
$def = Get-TableauPulseDefinition -DefinitionId $id
```

## PARAMETERS

### -DefinitionId
(Optional) The LUID(s) of the metric definition.
If one definition ID is provided, Get metric definition is called.
If more than one definition ID is provided, Batch get metric definition is called.
Otherwise, List metric definitions is called.

```yaml
Type: String[]
Parameter Sets: GetDefinitions
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefinitionViewType
(Optional) Specifies the range of metrics to return for a definition.
unspecified - N/A
basic       - Return only the specified metric definition.
This type is returned when the parameter is omitted.
full        - Return the metric definition and the specified number of metrics.
default     - Return the metric definition and the default metric.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumberOfMetrics
(Required if view is DEFINITION_VIEW_FULL) The number of metrics to return.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional) An expression to filter the response using one or multiple attributes.

```yaml
Type: String[]
Parameter Sets: ListDefinitions
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
(Optional) The sorting method for items returned, based on the popularity of the item.

```yaml
Type: String[]
Parameter Sets: ListDefinitions
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MetricId
(Optional) If a metric LUID is specified, only return the definition that is related to the metric, and the details of the metric.

```yaml
Type: String
Parameter Sets: ListDefinitions
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
Parameter Sets: ListDefinitions
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
A metric definition specifies the metadata for all related metrics created using the definition.
This includes the data source, measure, time dimension, and which data source dimensions can be filtered by users
or programmatically to create related metrics.
Example: A metric definition might specify that the data source is the Superstore sales database, and that the measure
to focus on is the aggregation "sum of sales".
It could define the filterable dimensions as region and product line,
that the time dimension for analysis is order date, and that the favorable direction is for the metric to increase.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_ListDefinitions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_ListDefinitions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_BatchGetDefinitions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_BatchGetDefinitions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_GetDefinition](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_GetDefinition)

