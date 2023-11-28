---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Get View URL"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Get-TSViewUrl/", "/PowerShell/PSTableauREST/get-tsviewurl/", "/PowerShell/get-tsviewurl/"]
schema: 2.0.0
title: Get-TSViewUrl
---

# Get-TSViewUrl

## SYNOPSIS
Get View URL

## SYNTAX

### ViewId
```
Get-TSViewUrl -ViewId <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ContentUrl
```
Get-TSViewUrl -ContentUrl <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the full URL of the specified view.

## EXAMPLES

### EXAMPLE 1
```
Get-TSViewUrl -ViewId $view.id
```

## PARAMETERS

### -ViewId
The LUID of the specified view.
Either ViewId or ContentUrl needs to be provided.

```yaml
Type: String
Parameter Sets: ViewId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentUrl
The content URL of the specified view.
Either ViewId or ContentUrl needs to be provided.

```yaml
Type: String
Parameter Sets: ContentUrl
Aliases:

Required: True
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

### System.String
## NOTES

## RELATED LINKS
