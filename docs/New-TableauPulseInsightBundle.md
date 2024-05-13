# New-TableauPulseInsightBundle

## SYNOPSIS
Generate current metric value / detail / springboard insight bundle

## SYNTAX

```
New-TableauPulseInsightBundle [-Type] <String> [-MetricName] <String> [-MetricId] <String>
 [-DefinitionId] <String> [[-Version] <Int32>] [[-OutputFormat] <String>] [[-Timestamp] <String>]
 [[-Timezone] <String>] [[-Definition] <Hashtable>] [[-Specification] <Hashtable>]
 [[-ExtensionOptions] <Hashtable>] [[-RepresentationOptions] <Hashtable>] [[-InsightsOptions] <Hashtable>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates a bundle the current aggregated value for each metric.
or
Generates a detail insight bundle.
or
Generates a springboard insight bundle.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$result = New-TableauPulseInsightBundle -MetricName Sales -MetricId $mid -DefinitionId $id -Definition @{...} -Specification @{...} -RepresentationOptions @{...} -ExtensionOptions @{...} -InsightsOptions @{show_insights=$true;settings=@()}
```

## PARAMETERS

### -Type
The type of the insight bundle: ban, detail or springboard.

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

### -MetricName
The name of the metric.

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

### -MetricId
The LUID of the metric.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefinitionId
The LUID of the metric definition.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
(Optional) The version of the bundle type to request.
Default is 0.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFormat
(Optional) Determines the type of markup to return for the insight text (text or html).
Default is unspecified.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Unspecified
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timestamp
(Optional) If specified, the date/time to use as current for insight analysis.
If empty the current date/time is used.
The format should be "YYYY-MM-DD HH:MM:SS" or "YYYY-MM-DD" or empty.
If no time is specified, then midnight ("00:00:00") is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timezone
(Optional) The time zone to use for insight analysis.
If empty, UTC is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Definition
(Optional) The metric definition, as hashtable.
Should include keys: datasource (id), basic_specification (measure, time_dimension, filters), viz_state_specification (viz_state_string),
is_running_total (true/false).
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Specification
(Optional) The specification of the metric definition, as hashtable.
Should include keys: filters (as list), measurement_period (granularity, range), comparison (comparison: "TIME_COMPARISON_UNSPECIFIED").
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtensionOptions
(Optional) The extension options of the metric definition, as hashtable.
Should include keys: allowed_dimensions (as list), allowed_granularities (enum, default: "GRANULARITY_UNSPECIFIED")
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RepresentationOptions
(Optional) The representation options of the metric definition, as hashtable.
Should include keys: type (enum, default: "NUMBER_FORMAT_TYPE_UNSPECIFIED"), number_units (singular_noun, plural_noun),
sentiment_type (e.g.
"SENTIMENT_TYPE_UP_IS_GOOD"), row_level_id_field, row_level_entity_names.
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InsightsOptions
(Optional) The insights options of the metric definition, as hashtable.
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
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
An insight is a data-driven observation about a metric.Tableau automatically generates and ranks insights by usefulness.
An insight bundle is a collection of insights for a metric That can be configured to include various elements.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleBAN](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleBAN)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleDetail](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleDetail)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleSpringboard](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseInsightsService_GenerateInsightBundleSpringboard)

