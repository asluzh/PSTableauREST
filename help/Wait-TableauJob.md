---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version:
schema: 2.0.0
title: Wait-TableauJob
---

# Wait-TableauJob

## SYNOPSIS
Wait For Job to complete

## SYNTAX

```
Wait-TableauJob [-JobId] <String> [[-Timeout] <Int32>] [[-Interval] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Wait until the job completion, while displaying the progress status.

## EXAMPLES

### EXAMPLE 1
```
$finished = Wait-TableauJob -JobId $job.id -Timeout 600
```

## PARAMETERS

### -JobId
The LUID of the job process.

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

### -Timeout
(Optional) Timeout in seconds.
Default is 3600 (1 hour).
Set timeout to 0 to wait indefinitely long.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 3600
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interval
(Optional) Poll interval in seconds.
Default is 1.
Increase interval to reduce the frequency of refresh status requests.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1
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
See also: wait_for_job() in TSC

## RELATED LINKS
