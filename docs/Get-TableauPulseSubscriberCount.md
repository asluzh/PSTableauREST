# Get-TableauPulseSubscriberCount

## SYNOPSIS
Batch get subscriber counts

## SYNTAX

```
Get-TableauPulseSubscriberCount [[-MetricId] <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets the number of unique users subscribed to a set of metrics specified in a comma separated list of metric LUIDs.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$defs = Get-TableauPulseSubscriberCount
```

### EXAMPLE 2
```
$def = Get-TableauPulseSubscriberCount -MetricId $id
```

## PARAMETERS

### -MetricId
(Optional) The metrics to get follower counts for, formatted as a comma separated list of LUIDs.
If no LUIDs are specified, the follower count for all metrics in a definition will be returned.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_BatchGetMetricFollowerCounts](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_BatchGetMetricFollowerCounts)

