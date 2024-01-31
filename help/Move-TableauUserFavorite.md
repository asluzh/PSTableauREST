# Move-TableauUserFavorite

## SYNOPSIS
Organize Favorites

## SYNTAX

```
Move-TableauUserFavorite [-UserId] <String> [-FavoriteId] <String> [-FavoriteType] <String>
 [-AfterFavoriteId] <String> [-AfterFavoriteType] <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Move an item to organize a user's favorites list.

## EXAMPLES

### EXAMPLE 1
```
Move-TableauUserFavorite -UserId (Get-TableauCurrentUserId) -FavoriteId $view.id -FavoriteType View -AfterFavoriteId $view2.id -AfterFavoriteType View
```

## PARAMETERS

### -UserId
The LUID of the user to arrange favorites for.

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

### -FavoriteId
The LUID of the specific favorite item to arrange.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FavoriteType
The type of the specific favorite item to arrange.
Valid types are Workbook, Datasource, View, Project, Flow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AfterFavoriteId
The LUID of a favorite item that should precede (insert the specific favorite after this item).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AfterFavoriteType
The type of a favorite item that should precede (insert the specific favorite after this item).
Valid types are Workbook, Datasource, View, Project, Flow.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#update_favorites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_favorites.htm#update_favorites)

