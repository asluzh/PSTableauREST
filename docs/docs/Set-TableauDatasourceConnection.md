---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Update Data Source Connection"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_connection
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauDatasourceConnection/", "/PowerShell/PSTableauREST/set-tableaudatasourceconnection/", "/PowerShell/set-tableaudatasourceconnection/"]
schema: 2.0.0
title: Set-TableauDatasourceConnection
---

# Set-TableauDatasourceConnection

## SYNOPSIS
Update Data Source Connection

## SYNTAX

```
Set-TableauDatasourceConnection [-DatasourceId] <String> [-ConnectionId] <String> [[-ServerAddress] <String>]
 [[-ServerPort] <String>] [[-Username] <String>] [[-SecurePassword] <SecureString>] [-EmbedPassword]
 [-QueryTagging] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the server address, port, username, or password for the specified data source connection.

## EXAMPLES

### EXAMPLE 1
```
$datasourceConnection = Set-TableauDatasourceConnection -DatasourceId $sampleDatasourceId -ConnectionId $connectionId -ServerAddress myserver.com
```

## PARAMETERS

### -DatasourceId
The LUID of the data source to update.

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
The LUID of the connection to update.

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

### -EmbedPassword
(Optional) Boolean switch, if supplied, the connection password is embedded.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -QueryTagging
(Optional) Boolean, true to enable query tagging for the connection.
https://help.tableau.com/current/pro/desktop/en-us/performance_tips.htm

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_connection](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#update_data_source_connection)

