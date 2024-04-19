# Set-TableauVirtualConnection

## SYNOPSIS
Update Virtual Connection Database Connections

## SYNTAX

```
Set-TableauVirtualConnection [-VirtualConnectionId] <String> [-ConnectionId] <String>
 [[-ServerAddress] <String>] [[-ServerPort] <String>] [[-Username] <String>] [[-SecurePassword] <SecureString>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the server address, port, username, or password for the specified database connection in a virtual connection.

## EXAMPLES

### EXAMPLE 1
```
$connection = Set-TableauVirtualConnection -VirtualConnectionId $vc.id -ConnectionId $connectionId -ServerAddress myserver.com
```

## PARAMETERS

### -VirtualConnectionId
The LUID for the virtual connection that includes the database connections.

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

### -ConnectionId
The LUID of the database connection to update.

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

### -ServerAddress
(Optional) The new server address of the connection.

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

### -ServerPort
(Optional) The new server port of the connection.

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

### -Username
(Optional) The new user name of the connection.

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

### -SecurePassword
(Optional) The new password of the connection, should be supplied as SecurePassword.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#update_virtual_connection_database_connections](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_virtual_connections.htm#update_virtual_connection_database_connections)

