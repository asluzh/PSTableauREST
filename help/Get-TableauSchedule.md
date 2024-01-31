# Get-TableauSchedule

## SYNOPSIS
Get Server Schedule / List Server Schedules

## SYNTAX

### ScheduleById
```
Get-TableauSchedule -ScheduleId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Schedules
```
Get-TableauSchedule [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns detailed information about the specified server schedule, or list of schedules on Tableau Server.
Not available for Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$schedules = Get-TableauSchedule
```

### EXAMPLE 2
```
$schedule = Get-TableauSchedule -ScheduleId $testScheduleId
```

## PARAMETERS

### -ScheduleId
(Get Server Schedule by Id) The LUID of the specific schedule.

```yaml
Type: String
Parameter Sets: ScheduleById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Schedules
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get-schedule](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#get-schedule)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_schedules](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_jobs_tasks_and_schedules.htm#query_schedules)

