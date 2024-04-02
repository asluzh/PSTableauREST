# Get-TableauWebhook

## SYNOPSIS
Get a Webhook / List Webhooks

## SYNTAX

### WebhookById
```
Get-TableauWebhook -WebhookId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Webhooks
```
Get-TableauWebhook [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified webhook, or a list of webhooks on the specified site.
This method can only be called by server and site administrators.

## EXAMPLES

### EXAMPLE 1
```
$webhook = Get-TableauWebhook -WebhookId $id
```

### EXAMPLE 2
```
$webhooks = Get-TableauWebhook
```

## PARAMETERS

### -WebhookId
Get a Webhook: The LUID of the webhook

```yaml
Type: String
Parameter Sets: WebhookById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional, List Webhooks)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

```yaml
Type: String[]
Parameter Sets: Webhooks
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional, List Webhooks)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

```yaml
Type: String[]
Parameter Sets: Webhooks
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional, List Webhooks)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm

```yaml
Type: String[]
Parameter Sets: Webhooks
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, List Webhooks) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Webhooks
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#get_webhook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#get_webhook)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#list_webhooks_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#list_webhooks_for_site)

