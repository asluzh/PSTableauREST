# Get-TableauSubscription

## SYNOPSIS
Get Subscription / List Subscriptions

## SYNTAX

### SubscriptionById
```
Get-TableauSubscription -SubscriptionId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Subscriptions
```
Get-TableauSubscription [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified subscription, or a list of subscriptions.

## EXAMPLES

### EXAMPLE 1
```
$subscriptions = Get-TableauSubscription
```

### EXAMPLE 2
```
$subscription = Get-TableauSubscription -SubscriptionId $id
```

## PARAMETERS

### -SubscriptionId
Get Subscription: The ID of the subscription to get information for.

```yaml
Type: String
Parameter Sets: SubscriptionById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, List Subscriptions) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Subscriptions
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#get_subscription](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#get_subscription)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#list_subscriptions](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#list_subscriptions)

