---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Convert permissions response into "PermissionTable""
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/ConvertTo-TableauPermissionTable/", "/PowerShell/PSTableauREST/convertto-tableaupermissiontable/", "/PowerShell/convertto-tableaupermissiontable/"]
schema: 2.0.0
title: ConvertTo-TableauPermissionTable
---

# ConvertTo-TableauPermissionTable

## SYNOPSIS
Convert permissions response into "PermissionTable"

## SYNTAX

```
ConvertTo-TableauPermissionTable [-Permissions] <XmlElement> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Converts the response of permission methods into the list-hashtable which can be used as input (PermissionTable) for:
- Add-TableauContentPermission
- Set-TableauContentPermission

## EXAMPLES

### EXAMPLE 1
```
$currentPermissionTable = Get-TableauContentPermission -WorkbookId $sampleWorkbookId | ConvertTo-TableauPermissionTable
```

## PARAMETERS

### -Permissions
XmlElement with the input raw data.

```yaml
Type: XmlElement
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### System.Collections.Hashtable[]
## NOTES
The following functions can be used as input for ConvertTo-TableauPermissionTable:
- Get-TableauContentPermission
- Add-TableauContentPermission
- Set-TableauContentPermission

## RELATED LINKS
