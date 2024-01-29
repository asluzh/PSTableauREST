---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Create Server Schedule"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#create_schedule
redirect_from: ["/PowerShell/PSTableauREST/New-TableauSchedule/", "/PowerShell/PSTableauREST/new-tableauschedule/", "/PowerShell/new-tableauschedule/"]
schema: 2.0.0
title: New-TableauSchedule
---

# New-TableauSchedule

## SYNOPSIS
Create Server Schedule

## SYNTAX

### Monthly
```
New-TableauSchedule -Name <String> -Type <String> [-Priority <Int32>] [-ExecutionOrder <String>]
 -Frequency <String> -StartTime <String> -IntervalMonthday <Int32> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Weekly
```
New-TableauSchedule -Name <String> -Type <String> [-Priority <Int32>] [-ExecutionOrder <String>]
 -Frequency <String> -StartTime <String> -IntervalWeekdays <String[]> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Daily
```
New-TableauSchedule -Name <String> -Type <String> [-Priority <Int32>] [-ExecutionOrder <String>]
 -Frequency <String> -StartTime <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### HourlyMinutes
```
New-TableauSchedule -Name <String> -Type <String> [-Priority <Int32>] [-ExecutionOrder <String>]
 -Frequency <String> -StartTime <String> [-EndTime <String>] -IntervalMinutes <Int32>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HourlyHours
```
New-TableauSchedule -Name <String> -Type <String> [-Priority <Int32>] [-ExecutionOrder <String>]
 -Frequency <String> -StartTime <String> [-EndTime <String>] -IntervalHours <Int32>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new server schedule on Tableau Server.
This method can be called only by Server Admins.

## EXAMPLES

### EXAMPLE 1
```
$schedule = New-TableauSchedule -Name "Monthly on 3rd day of the month" -Type Extract -Frequency Monthly -StartTime "08:00:00" -IntervalMonthday 3
```

## PARAMETERS

### -Name
The name to give to the schedule.

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

### -Type
The schedule typy, which is one of the following: Extract, Subscription, Flow, DataAcceleration.

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

### -Priority
An integer value between 1 and 100 that determines the default priority of the schedule if multiple tasks are pending in the queue.
Default is 50.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 50
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExecutionOrder
Parallel to allow jobs associated with this schedule to run at the same time, or Serial to require the jobs to run one after the other.
Default is Parallel.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Parallel
Accept pipeline input: False
Accept wildcard characters: False
```

### -Frequency
The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

Required: True
Position: Named
Default value: 00:00:00
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#create_schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#create_schedule)

