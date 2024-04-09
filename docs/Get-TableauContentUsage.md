# Get-TableauContentUsage

## SYNOPSIS
Get content usage statistics

## SYNTAX

```
Get-TableauContentUsage [-Content] <Hashtable[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets usage statistics for one or multiple content items, specified by LUID and content type (workbook, datasource, flow).

## EXAMPLES

### EXAMPLE 1
```
$results = Get-TableauContentUsage -Content @{type='workbooks';luid=$id}
```

### EXAMPLE 2
```
$results = Get-TableauContentUsage -Content @{type='workbooks';luid=$wbid},@{type='datasources';luid=$dsid}
```

## PARAMETERS

### -Content
An array of hashtables, containing at least one item, each of those should have the following keys:
- type: workbook, datasource, flow
- luid: the LUID of the content

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
If the Content parameter contains one element, the GET request is sent (GetUsageStats).
If the Content parameter contains more than one element, the POST request is sent (BatchGetUsage).

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/UsageStatsService_GetUsageStats](https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/UsageStatsService_GetUsageStats)

[https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/UsageStatsService_BatchGetUsage](https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/UsageStatsService_BatchGetUsage)

