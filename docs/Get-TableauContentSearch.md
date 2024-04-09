# Get-TableauContentSearch

## SYNOPSIS
Get content search results

## SYNTAX

```
Get-TableauContentSearch [[-Terms] <String[]>] [[-Filter] <String[]>] [[-OrderBy] <String[]>] [-All]
 [[-Limit] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Searches across all supported content types for objects relevant to the search expression specified in the querystring of the request URI.

## EXAMPLES

### EXAMPLE 1
```
$results = Get-TableauContentSearch -Terms sales -Filter type:eq:workbook -Limit 5
```

## PARAMETERS

### -Terms
(Optional) One or more terms the search uses as the basis for which items are relevant to return.
The items may be of any supported content type.
The relevance may be assessed based on any element of a given item.
If no terms are supplied, then results will be based filtering and page size limits.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional) An expression to filter the response using one of the following parameters, or a combination of expressions separated by a comma:
- type, e.g.
type:eq:workbook, type:in:\[workbook,datasource\]
- ownerId, e.g.
ownerId:in:\[akhil,fred,alice\]
- modifiedTime, using eq, lte, gte, gt operators.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
(Optional) The sorting method for items returned, based on the popularity of the item.
You can sort based on:
hitsTotal - The number of times a content item has been viewed since it was created.
hitsSmallSpanTotal The number of times viewed in the last month.
hitsMediumSpanTotal The number of times viewed in the last three months.
hitsLargeSpanTotal The number of times viewed in the last twelve months.
downstreamWorkbookCount The number workbooks in a given project.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
(Switch) When this parameter is provided, the search results are iterated for all pages
(until the search is exhausted, that is when "next" pointer in the results is empty).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Limit
(Optional) The number of search results to return.
The default is 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 10
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/ContentExplorationService_getSearch](https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/ContentExplorationService_getSearch)

