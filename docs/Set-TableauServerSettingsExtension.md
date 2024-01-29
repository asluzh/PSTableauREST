---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Update Tableau extensions server settings"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#update_tableau_extensions_server_settings
redirect_from: ["/PowerShell/PSTableauREST/Set-TableauServerSettingsExtension/", "/PowerShell/PSTableauREST/set-tableauserversettingsextension/", "/PowerShell/set-tableauserversettingsextension/"]
schema: 2.0.0
title: Set-TableauServerSettingsExtension
---

# Set-TableauServerSettingsExtension

## SYNOPSIS
Update Tableau extensions server settings

## SYNTAX

```
Set-TableauServerSettingsExtension [-Enabled] <String> [[-BlockList] <String[]>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the settings for extensions of a server.
This method can only be called by server administrators; it is not available on Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$settings = Set-TableauServerSettingsExtension -Enabled true -BlockList 'https://test.com'
```

## PARAMETERS

### -Enabled
True/false.
True: extensions are allowed to run on the server.
False: all extendions are disabled on the server.

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

### -BlockList
(Optional) List of domains that are not allowed to serve extensions to the Tableau Server.
Domains are in the form of https://blocked_example.com

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#update_tableau_extensions_server_settings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#update_tableau_extensions_server_settings)

