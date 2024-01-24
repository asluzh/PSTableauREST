---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Get Task / List Tasks on Site"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#get_extract_refresh_task
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauTask/", "/PowerShell/PSTableauREST/get-tableautask/", "/PowerShell/get-tableautask/"]
schema: 2.0.0
title: Get-TableauTask
---

# Get-TableauTask

## SYNOPSIS
Get Task / List Tasks on Site

## SYNTAX

### TaskById
```
Get-TableauTask -Type <String> -TaskId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Tasks
```
Get-TableauTask -Type <String> [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns information about the specified extract refresh / run flow / run linked / data acceleration task, or a list of such tasks on the current site.
This function unifies the following API calls:
- Get Extract Refresh Task
- Get Flow Run Task
- Get Linked Task
- Get Data Acceleration Task
- List Extract Refresh Tasks in Site
- Get Flow Run Tasks
- Get Linked Tasks
- Get Data Acceleration Tasks in a Site

## EXAMPLES

### EXAMPLE 1
```
$extractTasks = Get-TableauTask -Type ExtractRefresh | Where-Object -FilterScript {$_.datasource.id -eq $datasourceForTasks.id}
```

### EXAMPLE 2
```
$flowTasks = Get-TableauTask -Type FlowRun -TaskId $taskId
```

## PARAMETERS

### -Type
The type of the task, which corresponds to a specific API call.
Supported types are: ExtractRefresh, DataAcceleration, FlowRun, Linked

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

### -TaskId
Get Task by Id: The LUID of the specific task.

```yaml
Type: String
Parameter Sets: TaskById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, List Tasks) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Tasks
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#get_extract_refresh_task](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#get_extract_refresh_task)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#list_extract_refresh_tasks](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#list_extract_refresh_tasks)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task1](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_task1)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks1](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_flow.htm#get_flow_run_tasks1)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get_data_acceleration_tasks](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get_data_acceleration_tasks)

