---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Update Server Active Directory Domain"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#update_server_active_directory_domain
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauActiveDirectoryDomain/", "/PowerShell/PSTableauREST/set-tableauactivedirectorydomain/", "/PowerShell/set-tableauactivedirectorydomain/"]
schema: 2.0.0
title: Set-TableauActiveDirectoryDomain
---

# Set-TableauActiveDirectoryDomain

## SYNOPSIS
Update Server Active Directory Domain

## SYNTAX

```
Set-TableauActiveDirectoryDomain [-DomainId] <String> [[-Name] <String>] [[-ShortName] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Changes the nickname or full domain name of an Active Directory domain on the server.
This method can only be called by server administrators; it is not available on Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$domain = Set-TableauActiveDirectoryDomain
```

## PARAMETERS

### -DomainId
The integer ID of the of the Active Directory domain being updated.

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

### -Name
A new full domain name you are using to replace the existing one.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShortName
A new domain nickname you are using to replace the existing one.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#update_server_active_directory_domain](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#update_server_active_directory_domain)

