# Get-TableauVirtualConnection

## SYNOPSIS
List Virtual Connections
or
List Virtual Connection Database Connections

## SYNTAX

### ListDbConnections
```
Get-TableauVirtualConnection -VirtualConnectionId <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ListVirtualConnections
```
Get-TableauVirtualConnection [-Filter <String[]>] [-Sort <String[]>] [-Fields <String[]>] [-PageSize <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of available virtual connection names and IDs.
or
Returns a list of database connections found in the specified virtual connection and information about them.

## EXAMPLES

### EXAMPLE 1
```
$vconn = Get-TableauVirtualConnection -Filter "name:eq:$vcname" -Sort name:asc -Fields id,name
```

### EXAMPLE 2
```
$dbConnections = Get-TableauVirtualConnection -VirtualConnectionId $id
```

## PARAMETERS

### -VirtualConnectionId
List Virtual Connection Database Connections: The LUID of the virtual connection.

```yaml
Type: String
Parameter Sets: ListDbConnections
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
(Optional)
An expression that lets you specify a subset of data records to return.

```yaml
Type: String[]
Parameter Sets: ListVirtualConnections
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort
(Optional)
An expression that lets you specify the order in which data is returned.

```yaml
Type: String[]
Parameter Sets: ListVirtualConnections
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
(Optional)
An expression that lets you specify which data attributes are included in response.
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_fields.htm#query_workbooks_site

```yaml
Type: String[]
Parameter Sets: ListVirtualConnections
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: ListVirtualConnections
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#ref_list_virtual_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#ref_list_virtual_connections)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#ref_list_virtual_connection_database_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#ref_list_virtual_connection_database_connections)

