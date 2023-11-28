---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Delete Project"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#delete_project
redirect_from: ["/PowerShell/PSTableauREST/Remove-TSProject/", "/PowerShell/PSTableauREST/remove-tsproject/", "/PowerShell/remove-tsproject/"]
schema: 2.0.0
title: Remove-TSProject
---

# Remove-TSProject

## SYNOPSIS
Delete Project

## SYNTAX

```
Remove-TSProject [-ProjectId] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes the specified project on a specific site.
When a project is deleted, all Tableau assets inside of it are also deleted, including assets like associated workbooks, data sources, project view options, and rights.

## EXAMPLES

### EXAMPLE 1
```
$response = Remove-TSProject -ProjectId $testProjectId
```

## PARAMETERS

### -ProjectId
The LUID of the project to delete.

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#delete_project](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm#delete_project)

