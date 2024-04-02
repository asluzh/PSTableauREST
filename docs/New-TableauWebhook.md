# New-TableauWebhook

## SYNOPSIS
Create a Webhook

## SYNTAX

```
New-TableauWebhook [-Name] <String> [-EventName] <String> [-DestinationUrl] <String> [[-Enabled] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new webhook for a site.
This method can only be called by server and site administrators.

## EXAMPLES

### EXAMPLE 1
```
$webhook = New-TableauWebhook -Name "New Webhook" -Condition above -Threshold 14000 -WorksheetName "one_measure_no_dimension" -ViewId $view.id
```

## PARAMETERS

### -Name
The name for the webhook

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

### -EventName
The event name that should trigger the webhook.
See full list here: https://help.tableau.com/current/developer/webhooks/en-us/docs/webhooks-events-payload.html

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

### -DestinationUrl
The destination URL for the webhook.
The webhook destination URL must be https and have a valid certificate.

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

### -Enabled
(Optional) Boolean.
If true (default), the newly created webhook is enabled.
If false then the webhook will be disabled.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_webhook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_webhook)

