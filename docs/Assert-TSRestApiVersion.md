---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Assert check for Tableau Server REST API version"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Assert-TSRestApiVersion/", "/PowerShell/PSTableauREST/assert-tsrestapiversion/", "/PowerShell/assert-tsrestapiversion/"]
schema: 2.0.0
title: Assert-TSRestApiVersion
---

# Assert-TSRestApiVersion

## SYNOPSIS
Assert check for Tableau Server REST API version

## SYNTAX

```
Assert-TSRestApiVersion [[-AtLeast] <Version>] [[-LessThan] <Version>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Assert check for Tableau Server REST API version.
If the version is not compatible with the parameter inputs, an exception is generated through Write-Error call.

## EXAMPLES

### EXAMPLE 1
```
Assert-TSRestApiVersion -AtLeast 3.16
```

## PARAMETERS

### -AtLeast
Demands that the REST API version has to be at least this version number.
This is useful when a specific functionality has been introduced with this version.

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

### -LessThan
Demands that the REST API version has to be less than this version number.
This is needed for compatibility when a specific functionality has been decommissioned.

```yaml
Type: Version
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Version mapping: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_concepts_versions.htm
What's new in REST API: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_whats_new.htm

## RELATED LINKS
