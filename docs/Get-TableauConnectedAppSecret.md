# Get-TableauConnectedAppSecret

## SYNOPSIS
Get Connected App Secret

## SYNTAX

```
Get-TableauConnectedAppSecret [-ClientId] <String> [-SecretId] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Query a connected app secret and the token value using the connected app's ID.

## EXAMPLES

### EXAMPLE 1
```
$secret = Get-TableauConnectedAppSecret -ClientId $cid -SecretId $sid
```

## PARAMETERS

### -ClientId
The client ID of the connected app.

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

### -SecretId
The unique ID of the connected app secret.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp_secret](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm#get_connectedapp_secret)

