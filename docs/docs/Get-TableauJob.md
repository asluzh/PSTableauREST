---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Query Job / Query Jobs"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_job
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauJob/", "/PowerShell/PSTableauREST/get-tableaujob/", "/PowerShell/get-tableaujob/"]
schema: 2.0.0
title: Get-TableauJob
---

# Get-TableauJob

## SYNOPSIS
Query Job / Query Jobs

## SYNTAX

### JobById
```
Get-TableauJob -JobId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Jobs
```
Get-TableauJob [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the details about a specific job, or a list of active jobs on the current site.

## EXAMPLES

### EXAMPLE 1
```
$jobStatus = Get-TableauJob -JobId $job.id
```

### EXAMPLE 2
```
$extractJobs = Get-TableauJob -Filter "jobType:eq:refresh_extracts"
```

## PARAMETERS

### -JobId
Query Job: The LUID of the job to get status information for.

```yaml
Type: String
Parameter Sets: JobById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional, Query Jobs)
An expression that lets you specify a subset of data records to return.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#jobs

```yaml
Type: String[]
Parameter Sets: Jobs
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional, Query Jobs)
An expression that lets you specify the order in which data is returned.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_filtering_and_sorting.htm#users

```yaml
Type: String[]
Parameter Sets: Jobs
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional, Query Jobs)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_jobs

```yaml
Type: String[]
Parameter Sets: Jobs
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, Query Jobs) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Jobs
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_job](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_job)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_jobs](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_jobs)

