# Update-TableauHyperData

## SYNOPSIS
Update Data in Hyper Data Source or Connection

## SYNTAX

```
Update-TableauHyperData [-Action] <Hashtable[]> [-DatasourceId] <String> [[-ConnectionId] <String>]
 [[-InFile] <String>] [[-RequestId] <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Incrementally updates data (insert, update, upsert, replace and delete) in a published data source from a live-to-Hyper connection,
where the data source has a single connection or multiple connections.
See also: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_how_to_update_data_to_hyper.htm

## EXAMPLES

### EXAMPLE 1
```
$job = Update-TableauHyperData -InFile upload.hyper -Action $action -DatasourceId $datasource.id
```

### EXAMPLE 2
```
$job = Update-TableauHyperData -InFile upload.hyper -DatasourceId $datasourceId -Action $action1,$action2  -ConnectionId $connectionId
```

## PARAMETERS

### -Action
The actions list to perform.
Each element of the list is a hashtable, describing the action's properties.
The actions are performed sequentially, first to last, and if any of the actions fail, the whole operation is discarded.
The actions have the following properties:
- action: insert, update, delete, replace, or upsert
- target-table: The table name inside the target database
- target-schema: The name of a schema inside the target Hyper file
- source-table: The table name inside the source database
- source-schema: The name of a schema inside the uploaded source Hyper payload
- condition: the condition used to select the columns to be modified (applicable for update, delete, and upsert actions)

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

### -DatasourceId
The LUID of the data source to update.

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

### -ConnectionId
(Optional) The LUID of the data source connection to update.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InFile
(Optional) The filename (incl.
path) of the hyper file payload.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequestId
(Optional) A user-generated identifier that uniquely identifies a request.
If this parameter is not supplied, the request ID will be generated randomly.
Purpose: If the server receives more than one request with the same ID within 24 hours,
all subsequent requests will be treated as duplicates and ignored by the server.
This can be used to guarantee idempotency of requests.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_in_hyper_data_source](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_in_hyper_data_source)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_now](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_now)

