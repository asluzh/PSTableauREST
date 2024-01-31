---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_data_driven_alert
schema: 2.0.0
title: New-TableauDataAlert
---

# New-TableauDataAlert

## SYNOPSIS
Create Data Driven Alert

## SYNTAX

### View
```
New-TableauDataAlert -Subject <String> -Condition <String> -Threshold <Int32> [-Frequency <String>]
 [-Visibility <String>] [-Device <String>] -WorksheetName <String> -ViewId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CustomView
```
New-TableauDataAlert -Subject <String> -Condition <String> -Threshold <Int32> [-Frequency <String>]
 [-Visibility <String>] [-Device <String>] -WorksheetName <String> -CustomViewId <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a data driven alert (DDA) for a view with a single data axis.

## EXAMPLES

### EXAMPLE 1
```
$dataAlert = New-TableauDataAlert -Subject "Data Driven Alert for Forecast" -Condition above -Threshold 14000 -WorksheetName "one_measure_no_dimension" -ViewId $view.id
```

## PARAMETERS

### -Subject
The name of the data driven alert.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Condition
The condition that triggers the DDA.
Used in conjunction with the threshold to determine when to trigger an alert.
Valid values: above, above-equal, below, below-equal, equal

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Threshold
Numeric value for the alert threshold.
A data alert is triggered when this threshold is crossed.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Frequency
The time period between attempts by Tableau to assess whether the alert threshold has been crossed.
Valid values: once, freguently, hourly, daily, weekly.
Default is once.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Once
Accept pipeline input: False
Accept wildcard characters: False
```

### -Visibility
Determines whether the alert can be seen by only its creator (private), or by any user with permissions to the worksheet where the alert resides (public).
Default is private.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Private
Accept pipeline input: False
Accept wildcard characters: False
```

### -Device
(Optional) The type of device the alert is formatted for.
If no device is provided then the default device setting of the underlying view is used.
Valid values: desktop, phone, tablet.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorksheetName
The name of the worksheet that the DDA will be created on.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ViewId
The LUID of the view that contains the data that can trigger an alert.
Either the ViewId or CustomViewId needs to be provided.

```yaml
Type: String
Parameter Sets: View
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomViewId
The LUID of the custom view that contains the data that can trigger an alert.
Either the ViewId or CustomViewId needs to be provided.

```yaml
Type: String
Parameter Sets: CustomView
Aliases:

Required: True
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_data_driven_alert](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#create_data_driven_alert)

