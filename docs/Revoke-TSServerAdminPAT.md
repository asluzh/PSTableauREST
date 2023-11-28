---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Revoke Administrator Personal Access Tokens"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#revoke_administrator_personal_access_tokens
redirect_from: ["/PowerShell/PSTableauREST/Revoke-TSServerAdminPAT/", "/PowerShell/PSTableauREST/revoke-tsserveradminpat/", "/PowerShell/revoke-tsserveradminpat/"]
schema: 2.0.0
title: Revoke-TSServerAdminPAT
---

# Revoke-TSServerAdminPAT

## SYNOPSIS
Revoke Administrator Personal Access Tokens

## SYNTAX

```
Revoke-TSServerAdminPAT [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Revokes all personal access tokens created by server administrators.
This method is not available for Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$response = Revoke-TSServerAdminPAT
```

## PARAMETERS

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#revoke_administrator_personal_access_tokens](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#revoke_administrator_personal_access_tokens)

