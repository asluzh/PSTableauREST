---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Add Workbook / Data Source / Flow Task to Server Schedule"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_workbook_to_schedule
redirect_from: ["/PowerShell/PSTableauREST/Add-TSContentToSchedule/", "/PowerShell/PSTableauREST/add-tscontenttoschedule/", "/PowerShell/add-tscontenttoschedule/"]
schema: 2.0.0
title: Add-TSContentToSchedule
---

# Add-TSContentToSchedule

## SYNOPSIS
Add Workbook / Data Source / Flow Task to Server Schedule

## SYNTAX

### Workbook
```
Add-TSContentToSchedule -ScheduleId <String> [-WorkbookId <String>] [-DataAccelerationTask]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Datasource
```
Add-TSContentToSchedule -ScheduleId <String> [-DatasourceId <String>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Flow
```
Add-TSContentToSchedule -ScheduleId <String> [-FlowId <String>] [-OutputStepId <String>]
 [-FlowParams <Hashtable>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds a task to refresh or accelerate a workbook to an existing schedule on Tableau Server.
Note: this is not supported on Tableau Cloud.
or
Adds a task to refresh a data source to an existing server schedule on Tableau Server.
Note: this is not supported on Tableau Cloud.
or
Adds a task to run a flow to an existing schedule.
Note: Tableau Prep Conductor is required to use this feature.

## EXAMPLES

### EXAMPLE 1
```
$task = Add-TSContentToSchedule -ScheduleId $extractScheduleId -WorkbookId $workbook.id
```

### EXAMPLE 2
```
$task = Add-TSContentToSchedule -ScheduleId $runFlowScheduleId -FlowId $flowForTasks.id
```

## PARAMETERS

### -ScheduleId
The LUID of the schedule that the task will be added into.

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

### -WorkbookId
Add Workbook to Server Schedule: The LUID of the workbook to add to the schedule.

```yaml
Type: String
Parameter Sets: Workbook
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DataAccelerationTask
Add Workbook to Server Schedule: Boolean switch, if supplied, the data acceleration task for the workbook will be added too.
Note: starting in Tableau version 2022.1 (API v3.16), the data acceleration feature is deprecated.

```yaml
Type: SwitchParameter
Parameter Sets: Workbook
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatasourceId
Add Data Source to Server Schedule: The LUID of the data source to add to the schedule.

```yaml
Type: String
Parameter Sets: Datasource
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FlowId
Add Flow Task to Schedule: The LUID of the flow to add to the schedule.

```yaml
Type: String
Parameter Sets: Flow
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputStepId
Add Flow Task to Schedule: (Optional) The LUID of the specific output step, if only this step needs to be run in the scheduled task.

```yaml
Type: String
Parameter Sets: Flow
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FlowParams
Add Flow Task to Schedule: (Optional) The hashtable for the flow parameters.
The keys are the parameter LUIDs and the values are the override values.

```yaml
Type: Hashtable
Parameter Sets: Flow
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_workbook_to_schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_workbook_to_schedule)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_data_source_to_schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#add_data_source_to_schedule)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#add_flow_task_to_schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#add_flow_task_to_schedule)

