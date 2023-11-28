---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Selects Tableau Server REST API version for future calls"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Set-TSRestApiVersion/", "/PowerShell/PSTableauREST/set-tsrestapiversion/", "/PowerShell/set-tsrestapiversion/"]
schema: 2.0.0
title: Set-TSRestApiVersion
---

# Set-TSRestApiVersion

## SYNOPSIS
Selects Tableau Server REST API version for future calls

## SYNTAX

```
Set-TSRestApiVersion [[-ApiVersion] <Version>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Selects Tableau Server REST API version for future calls (stored in module variable).

## EXAMPLES

### EXAMPLE 1
```
Set-TSRestApiVersion -ApiVersion 3.20
```

## PARAMETERS

### -ApiVersion
The specific API version to switch to.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

## NOTES

## RELATED LINKS
