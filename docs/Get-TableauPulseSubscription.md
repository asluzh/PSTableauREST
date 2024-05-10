# Get-TableauPulseSubscription

## SYNOPSIS
List subscriptions
or
Batch get subscriptions
or
Get subscription

## SYNTAX

### GetSubscription
```
Get-TableauPulseSubscription -SubscriptionId <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ListSubscriptions
```
Get-TableauPulseSubscription [-MetricId <String>] [-UserId <String>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Lists the subscriptions to a specified metric and/or for a specified user.
or
Gets a batch of subscriptions, specified in a comma delimited list of subscriptions LUIDs.
or
Gets the number of unique users subscribed to a set of metrics specified in a comma separated list of metric LUIDs.
or
Gets a specified subscription to a metric.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$subs = Get-TableauPulseSubscription
```

### EXAMPLE 2
```
$subs = Get-TableauPulseSubscription -MetricId $mid
```

### EXAMPLE 3
```
$sub = Get-TableauPulseSubscription -SubscriptionId $sid
```

## PARAMETERS

### -SubscriptionId
The LUID of the subscriptions.
If more than one subscription ID is supplied, the batchGet method is called.

```yaml
Type: String[]
Parameter Sets: GetSubscription
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MetricId
(Optional) The LUID of a metric whose subscriptions will be returned.

```yaml
Type: String
Parameter Sets: ListSubscriptions
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
(Optional) The LUID of a user whose subscriptions will be returned.

```yaml
Type: String
Parameter Sets: ListSubscriptions
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
Parameter Sets: ListSubscriptions
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
A user who follows (has a subscription to) a metric can receive digests via email or Slack.
Digests can also be viewed in the Metrics home page in the Tableau UI.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_ListSubscriptions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_ListSubscriptions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_BatchGetSubscriptions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_BatchGetSubscriptions)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_GetSubscription](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_pulse.htm#PulseSubscriptionService_GetSubscription)

