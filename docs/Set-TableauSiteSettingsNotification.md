# Set-TableauSiteSettingsNotification

## SYNOPSIS
Update User Notification Preferences

## SYNTAX

```
Set-TableauSiteSettingsNotification [-Preferences] <Hashtable[]> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates user notifications preferences to enabled or disabled on the specified site.
This method can only be called by site or server administrators.

## EXAMPLES

### EXAMPLE 1
```
$settings = Set-TableauSiteSettingsNotification -Preferences @{channel='email';notificationType='extractrefresh';enabled='true'}
```

## PARAMETERS

### -Preferences
Array consisting of notification preferences, each preference is expected to be a hashtable with the following keys:
- enabled: true | false
- channel: email | in_app | slack
- notificationType: comments | webhooks | prepflow | share | dataalerts | extractrefresh

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_user_notification_preferences](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_user_notification_preferences)

