# Get-TableauViewUrl

## SYNOPSIS
Get View URL

## SYNTAX

### ViewId
```
Get-TableauViewUrl -ViewId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ContentUrl
```
Get-TableauViewUrl -ContentUrl <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the full URL of the specified view.

## EXAMPLES

### EXAMPLE 1
```
Get-TableauViewUrl -ViewId $view.id
```

## PARAMETERS

### -ViewId
The LUID of the specified view.
Either ViewId or ContentUrl needs to be provided.

```yaml
Type: String
Parameter Sets: ViewId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentUrl
The content URL of the specified view.
Either ViewId or ContentUrl needs to be provided.

```yaml
Type: String
Parameter Sets: ContentUrl
Aliases:

Required: True
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

### System.String
## NOTES

## RELATED LINKS
