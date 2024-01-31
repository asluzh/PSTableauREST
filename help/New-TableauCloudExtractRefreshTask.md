---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_cloud_extract_refresh_task
schema: 2.0.0
title: New-TableauCloudExtractRefreshTask
---

# New-TableauCloudExtractRefreshTask

## SYNOPSIS
Create Cloud Extract Refresh Task

## SYNTAX

### Workbook
```
New-TableauCloudExtractRefreshTask -WorkbookId <String> [-Type <String>] [-Frequency <String>]
 [-StartTime <String>] [-EndTime <String>] [-IntervalHours <Int32>] [-IntervalMinutes <Int32>]
 [-IntervalWeekdays <String[]>] [-IntervalMonthdayNr <Int32>] [-IntervalMonthdayWeekday <String>]
 [-IntervalMonthdays <Int32[]>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Datasource
```
New-TableauCloudExtractRefreshTask -DatasourceId <String> [-Type <String>] [-Frequency <String>]
 [-StartTime <String>] [-EndTime <String>] [-IntervalHours <Int32>] [-IntervalMinutes <Int32>]
 [-IntervalWeekdays <String[]>] [-IntervalMonthdayNr <Int32>] [-IntervalMonthdayWeekday <String>]
 [-IntervalMonthdays <Int32[]>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a custom schedule for an extract refresh on Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$extractTaskResult = New-TableauCloudExtractRefreshTask -WorkbookId $workbook.id -Type FullRefresh -Frequency Daily -StartTime 12:00:00 -IntervalHours 24 -IntervalWeekdays 'Sunday','Monday'
```

## PARAMETERS

### -WorkbookId
The LUID of the workbook that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

```yaml
Type: String
Parameter Sets: Workbook
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatasourceId
The LUID of the data source that should be included into the custom schedule.
Either workbook ID or data source ID needs to be provided.

```yaml
Type: String
Parameter Sets: Datasource
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
The type of extract refresh being scheduled: FullRefresh or IncrementalRefresh

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: FullRefresh
Accept pipeline input: False
Accept wildcard characters: False
```

### -Frequency
The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Daily
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
The starting daytime for scheduled jobs.
For Hourly: the starting time of execution period (for example, 18:30:00).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 00:00:00
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

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

### -IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs.
Valid value is 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs.
Valid value is 60.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalWeekdays
(Optional) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs.
The week days are specified strings (weekday names in English).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthdayNr
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g.
for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthdayWeekday
(Optional) For Monthly, describing which occurrence of a weekday within the month, e.g.
for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

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

### -IntervalMonthdays
(Optional) For Monthly, describing specific days in a month, e.g.
for 3rd and 5th days, the list of values 3 and 5 should be provided.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_cloud_extract_refresh_task](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#create_cloud_extract_refresh_task)

