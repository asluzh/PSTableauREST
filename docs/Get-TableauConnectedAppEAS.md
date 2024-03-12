# Get-TableauConnectedAppEAS

## SYNOPSIS
List All Registered EAS
or
List Registered EAS

## SYNTAX

### ConnectedAppById
```
Get-TableauConnectedAppEAS -EasId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConnectedApps
```
Get-TableauConnectedAppEAS [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get all external authorization servers (EASs) registered to a site, or details of an EAS registered to a site.
Tableau Cloud only, currently not supported for Tableau Server.

## EXAMPLES

### EXAMPLE 1
```
$list = Get-TableauConnectedAppEAS
```

### EXAMPLE 2
```
$eas = Get-TableauConnectedAppEAS -EasId $id
```

## PARAMETERS

### -EasId
List Registered EAS: The unique ID of the registered EAS.

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
(Optional, List All Registered EAS) Page size when paging through results.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapps_eas](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapps_eas)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp_eas](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp_eas)

