# Get-TableauContentSuggestion

## SYNOPSIS
Get content Suggestions

## SYNTAX

```
Get-TableauContentSuggestion [-Terms] <String> [[-Filter] <String[]>] [[-Luid] <String[]>] [[-Limit] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a specified number of suggestions for auto-completion of user input as they type.
You can specify content types of suggestions and prioritize recently viewed content.

## EXAMPLES

### EXAMPLE 1
```
$results = Get-TableauContentSuggestion -Terms regional
```

## PARAMETERS

### -Terms
The term that is matched to find suggestions.

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

### -Filter
(Optional) A filter to restrict suggestions to specified content types, e.g.
type:eq:workbook

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

### -Luid
(Optional) A comma separated list of luids that will be prioritized in scoring of content items matched to suggest.

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

### -Limit
(Optional) The number of suggestions to return.
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/ContentExploration_getSuggestions](https://help.tableau.com/current/api/rest_api/en-us/REST/TAG/index.html#tag/Content-Exploration-Methods/operation/ContentExploration_getSuggestions)

