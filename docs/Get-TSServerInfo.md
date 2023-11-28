---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Retrieves the object with Tableau Server info"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#server_info
redirect_from: ["/PowerShell/PSTableauREST/Get-TSServerInfo/", "/PowerShell/PSTableauREST/get-tsserverinfo/", "/PowerShell/get-tsserverinfo/"]
schema: 2.0.0
title: Get-TSServerInfo
---

# Get-TSServerInfo

## SYNOPSIS
Retrieves the object with Tableau Server info

## SYNTAX

```
Get-TSServerInfo [[-ServerUrl] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves the object with Tableau Server info, such as build number, product version, etc.

## EXAMPLES

### EXAMPLE 1
```
$serverInfo = Get-TSServerInfo
```

## PARAMETERS

### -ServerUrl
Optional parameter with Tableau Server URL.
If not provided, the current Server URL (when signed-in) is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
This API can be called by anyone, even non-authenticated, so it doesn't require X-Tableau-Auth header.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#server_info](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#server_info)

