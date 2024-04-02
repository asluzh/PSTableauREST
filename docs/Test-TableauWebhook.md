# Test-TableauWebhook

## SYNOPSIS
Test a Webhook

## SYNTAX

```
Test-TableauWebhook [-WebhookId] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Tests the specified webhook. 
Sends an empty payload to the configured destination URL of the webhook and returns the response from the server.
This method can only be called by server and site administrators.

## EXAMPLES

### EXAMPLE 1
```
$result = Test-TableauWebhook -WebhookId $id
```

## PARAMETERS

### -WebhookId
The LUID of the webhook.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#test_webhook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#test_webhook)

