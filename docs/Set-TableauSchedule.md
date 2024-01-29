---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Update Server Schedule"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#update_schedule
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauSchedule/", "/PowerShell/PSTableauREST/set-tableauschedule/", "/PowerShell/set-tableauschedule/"]
schema: 2.0.0
title: Set-TableauSchedule
---

# Set-TableauSchedule

## SYNOPSIS
Update Server Schedule

## SYNTAX

### Monthly
```
Set-TableauSchedule -ScheduleId <String> [-Name <String>] [-State <String>] [-Priority <Int32>]
 [-ExecutionOrder <String>] [-Frequency <String>] [-StartTime <String>] -IntervalMonthday <Int32>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Weekly
```
Set-TableauSchedule -ScheduleId <String> [-Name <String>] [-State <String>] [-Priority <Int32>]
 [-ExecutionOrder <String>] [-Frequency <String>] [-StartTime <String>] -IntervalWeekdays <String[]>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Daily
```
Set-TableauSchedule -ScheduleId <String> [-Name <String>] [-State <String>] [-Priority <Int32>]
 [-ExecutionOrder <String>] [-Frequency <String>] [-StartTime <String>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HourlyMinutes
```
Set-TableauSchedule -ScheduleId <String> [-Name <String>] [-State <String>] [-Priority <Int32>]
 [-ExecutionOrder <String>] [-Frequency <String>] [-StartTime <String>] [-EndTime <String>]
 -IntervalMinutes <Int32> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HourlyHours
```
Set-TableauSchedule -ScheduleId <String> [-Name <String>] [-State <String>] [-Priority <Int32>]
 [-ExecutionOrder <String>] [-Frequency <String>] [-StartTime <String>] [-EndTime <String>]
 -IntervalHours <Int32> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Modifies settings for the specified server schedule, including the name, priority, and frequency details on Tableau Server.
This method can only be called by Server Admins.

## EXAMPLES

### EXAMPLE 1
```
$schedule = Set-TableauSchedule -ScheduleId $oldScheduleId -State Suspended
```

### EXAMPLE 2
```
$schedule = Set-TableauSchedule -ScheduleId $testScheduleId -Frequency Hourly -StartTime "12:00:00" -EndTime "16:00:00" -IntervalHours 1
```

## PARAMETERS

### -ScheduleId
The LUID of the schedule to update.

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

### -Name
(Optional) The new name to give to the schedule.

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

### -State
(Optional) 'Active' to enable the schedule, or 'Suspended' to disable it.

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

### -Priority
(Optional) An integer value between 1 and 100 that determines the default priority of the schedule if multiple tasks are pending in the queue.

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

### -ExecutionOrder
(Optional) Parallel to allow jobs associated with this schedule to run at the same time, or Serial to require the jobs to run one after the other.

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

### -Frequency
(Optional) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

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

### -StartTime
(Optional) The starting daytime for scheduled jobs.
For Hourly: the starting time of execution period (for example, 18:30:00).

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

### -EndTime
(Optional) For Hourly: the ending time for execution period (for example, 21:00:00).

```yaml
Type: String
Parameter Sets: HourlyMinutes, HourlyHours
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalHours
(Optional) For Hourly: the interval in hours between schedule runs.

```yaml
Type: Int32
Parameter Sets: HourlyHours
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMinutes
(Optional) For Hourly: the interval in minutes between schedule runs.
Valid values are 15 or 30.

```yaml
Type: Int32
Parameter Sets: HourlyMinutes
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalWeekdays
(Optional) For Weekly: list of weekdays, when the schedule runs.
The week days are specified strings (weekday names in English).

```yaml
Type: String[]
Parameter Sets: Weekly
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthday
(Optional) For Monthly: the day of the month when the schedule is run.
For last month day, the value 0 should be supplied.

```yaml
Type: Int32
Parameter Sets: Monthly
Aliases:

Required: True
Position: Named
Default value: 0
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#update_schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#update_schedule)

