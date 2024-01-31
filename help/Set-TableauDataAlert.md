---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_data-driven_alert
schema: 2.0.0
title: Set-TableauDataAlert
---

# Set-TableauDataAlert

## SYNOPSIS
Update Data-Driven Alert

## SYNTAX

```
Set-TableauDataAlert [-DataAlertId] <String> [[-OwnerUserId] <String>] [[-Subject] <String>]
 [[-Frequency] <String>] [[-Public] <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Update one or more settings for the specified data-driven alert; including the alert subject, frequency, and owner.

## EXAMPLES

### EXAMPLE 1
```
$dataAlert = Set-TableauDataAlert -DataAlertId $id -Subject "New Alert for Forecast"
```

## PARAMETERS

### -DataAlertId
The LUID of the data-driven alert.

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

### -OwnerUserId
(Optional) The LUID of the user to assign as owner of the data-driven alert.

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

### -Subject
(Optional) The string to set as the new subject of the alert.

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

### -Frequency
(Optional) The frequency of the data-driven alert: once, frequently, hourly, daily, or weekly.

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

### -Public
(Optional) Determines the visibility of the data-driven alert.
If the flag is true, users with access to the view containing the alert can see the alert and add themselves as recipients.
If the flag is false, then the alert is only visible to the owner, site or server administrators, and specific users they add as recipients.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_data-driven_alert](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#update_data-driven_alert)

