# Get-TableauConnectedApp

## SYNOPSIS
List Connected Apps
or
Get Connected App

## SYNTAX

### ConnectedAppById
```
Get-TableauConnectedApp -ClientId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConnectedApps
```
Get-TableauConnectedApp [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Query all connected apps configured on a site, or details of the connected app by its ID.

## EXAMPLES

### EXAMPLE 1
```
$apps = Get-TableauConnectedApp
```

### EXAMPLE 2
```
$app = Get-TableauConnectedApp -ClientId $cid
```

## PARAMETERS

### -ClientId
Get Connected App: The client ID of the connected app.

```yaml
Type: String
Parameter Sets: ConnectedAppById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional, List Connected Apps) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: ConnectedApps
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapps](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapps)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp)

