# New-TableauPulseDefinition

## SYNOPSIS
Create metric definition

## SYNTAX

```
New-TableauPulseDefinition [-Name] <String> [[-Description] <String>] [-Specification] <Hashtable>
 [[-ExtensionOptions] <Hashtable>] [[-RepresentationOptions] <Hashtable>] [[-InsightsOptions] <Hashtable>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a metric definition.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$def = New-TableauPulseDefinition -Name Sales -Description "Sales metric definition" -Specification @{datasource=@{id="..."};basic_specification=@{measure=@{field="Sales";aggregation="AGGREGATION_SUM"};time_dimension=@{field="Order Date"};filters=@()};viz_state_specification=@{viz_state_string=""};is_running_total=$true} -RepresentationOptions @{type="NUMBER_FORMAT_TYPE_NUMBER";number_units=@{singular_noun="Sales";plural_noun="Sales"};sentiment_type="SENTIMENT_TYPE_UP_IS_GOOD";row_level_id_field=@{identifier_col="";identifier_label=""};row_level_entity_names=@{entity_name_singular="";entity_name_plural=""}} -ExtensionOptions @{allowed_dimensions=@("Category");allowed_granularities=@("GRANULARITY_UNSPECIFIED")} -InsightsOptions @{show_insights=$true;settings=@()}
```

## PARAMETERS

### -Name
The name of the metric definition.

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

### -Description
(Optional) The description of the metric definition.

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

### -Specification
The specification of the metric definition, as hashtable.
Should include keys: datasource (id), basic_specification (measure, time_dimension, filters), viz_state_specification (viz_state_string),
is_running_total (true/false).
Please check API documentation for full schema of item definition.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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
Position: 4
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
Position: 5
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
Position: 6
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_CreateDefinition](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#MetricQueryService_CreateDefinition)

