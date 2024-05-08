# New-TableauPulseMetric

## SYNOPSIS
Create metric
or
Get or create metric

## SYNTAX

```
New-TableauPulseMetric [-DefinitionId] <String> [-Specification] <Hashtable> [-GetOrCreate]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a metric.
This method returns a PSCustomObject from JSON - see online help for more details.
Alternatively, if the switch parameter is supplied, calls Get or create metric:
Returns the details of a metric in a definition if it exists, or creates a new metric if it does not.
The method then returns the response object with two properties:
- metric
- is_metric_created (true if a new metric was created, or false if it already existed).

## EXAMPLES

### EXAMPLE 1
```
$def = New-TableauPulseMetric -DefinitionId $def -Specification $spec
```

### EXAMPLE 2
```
$def = New-TableauPulseMetric -DefinitionId $def -Specification $spec -GetOrCreate
```

## PARAMETERS

### -DefinitionId
The LUID(s) of the metric definition.

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

### -Specification
The specification of the metric, as hashtable.
Should include keys: filters (as list), measurement_period (granularity, range), comparison (comparison: "TIME_COMPARISON_UNSPECIFIED").
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetOrCreate
(Optional) Switch, if provided the Get or create metric method is called.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_CreateMetric](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_CreateMetric)

[https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Pulse-Methods/operation/MetricQueryService_GetOrCreateMetric](https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Pulse-Methods/operation/MetricQueryService_GetOrCreateMetric)

