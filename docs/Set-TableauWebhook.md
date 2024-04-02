# Set-TableauWebhook

## SYNOPSIS
Update a Webhook

## SYNTAX

```
Set-TableauWebhook [-WebhookId] <String> [[-Name] <String>] [[-EventName] <String>]
 [[-DestinationUrl] <String>] [[-Enabled] <String>] [[-ReasonForDisablement] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Modify the properties of an existing webhook.
This method can only be called by server and site administrators.

## EXAMPLES

### EXAMPLE 1
```
$webhook = Set-TableauWebhook -WebhookId $id -Name "Updated Webhook"
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

### -Name
(Optional) The new name for the webhook.

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

### -EventName
(Optional) The new event name for the webhook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationUrl
(Optional) The new destination URL for the webhook.
The webhook destination URL must be https and have a valid certificate.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enabled
(Optional) Boolean.
If true (default), the newly created webhook is enabled.
If false then the webhook will be disabled.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReasonForDisablement
(Optional) The reason a webhook is disabled.
If Enabled is set to false, provides the reason for changing the status, or defaults to "Webhook disabled by user".
If Enabled set to true, this parameter is ignored.

```yaml
Type: String
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_webhook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_webhook)

