# Get-TableauCustomViewUserDefault

## SYNOPSIS
List Users with Custom View as Default - Preview Release

## SYNTAX

```
Get-TableauCustomViewUserDefault [-CustomViewId] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets the list of users whose default view is the specified custom view.
Note: This method is currently available as a preview release in some regions.

## EXAMPLES

### EXAMPLE 1
```
$users = Get-TableauCustomViewUserDefault -CustomViewId $id
```

## PARAMETERS

### -CustomViewId
The LUID for the custom view.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#list_users_with_custom_view_as_default)

