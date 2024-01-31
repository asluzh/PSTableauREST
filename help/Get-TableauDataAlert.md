---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alert_details
schema: 2.0.0
title: Get-TableauDataAlert
---

# Get-TableauDataAlert

## SYNOPSIS
Get Data-Driven Alert / List Data-Driven Alerts on Site

## SYNTAX

### DataAlertById
```
Get-TableauDataAlert -DataAlertId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DataAlerts
```
Get-TableauDataAlert [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns details on a specified data-driven alert, or a list of data-driven alerts in use on the specified site

## EXAMPLES

### EXAMPLE 1
```
$dataAlert = Get-TableauDataAlert -DataAlertId $id
```

## PARAMETERS

### -DataAlertId
Get Data-Driven Alert: The LUID of the data-driven alert.

```yaml
Type: String
Parameter Sets: DataAlertById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

```yaml
Type: String[]
Parameter Sets: DataAlerts
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm

```yaml
Type: String[]
Parameter Sets: DataAlerts
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional, List Data-Driven Alerts on Site)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm

```yaml
Type: String[]
Parameter Sets: DataAlerts
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, List Data-Driven Alerts on Site) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: DataAlerts
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alert_details](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alert_details)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alerts](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_notifications.htm#query_data-driven_alerts)

