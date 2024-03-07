# New-TableauAnalyticsExtension

## SYNOPSIS
Add analytics extension connection to site

## SYNTAX

```
New-TableauAnalyticsExtension [-Name] <String> [-Type] <String> [-Hostname] <String> [-Port] <Int32>
 [-AuthRequired] [[-Username] <String>] [[-SecurePassword] <SecureString>] [-SslEnabled]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds a new analytics extension connection for the current site.

## EXAMPLES

### EXAMPLE 1
```
$ext = New-TableauAnalyticsExtension -Name $name -Type TABPY -Hostname $host -Port 443 -AuthRequired -SslEnabled -Username $user -SecurePassword $pw
```

## PARAMETERS

### -Name
The name for the analytics extension connection.

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

### -Type
The type for the analytics extension connection, which should be one of the following:
UNDEFINED,TABPY,RSERVE,EINSTEIN_DISCOVERY,GENERIC_API

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

### -Hostname
The hostname for the analytics extension service.

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

### -Port
The port number for the analytics extension service.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthRequired
Specifies if authentication should be required.

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

### -Username
Username for authentication for the analytics extension service.

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
Password as SecureString for authentication for the analytics extension service.

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

### -SslEnabled
Specifies SSL for the analytics extension connection should be enabled.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_addAnalyticsExtensionsConnection](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_analytics_extensions_settings.htm#AnalyticsExtensionsService_addAnalyticsExtensionsConnection)

