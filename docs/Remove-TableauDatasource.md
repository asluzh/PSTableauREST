---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Delete Data Source / Delete Data Source Revision"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#delete_data_source
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauDatasource/", "/PowerShell/PSTableauREST/remove-tableaudatasource/", "/PowerShell/remove-tableaudatasource/"]
schema: 2.0.0
title: Remove-TableauDatasource
---

# Remove-TableauDatasource

## SYNOPSIS
Delete Data Source / Delete Data Source Revision

## SYNTAX

```
Remove-TableauDatasource [-DatasourceId] <String> [[-Revision] <Int32>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes a published data source.
Note: it's not possible to delete the latest revision of the data source.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauDatasource -DatasourceId $sampleDatasourceId
```

### EXAMPLE 2
```
Remove-TableauDatasource -DatasourceId $sampleDatasourceId -Revision 1
```

## PARAMETERS

### -DatasourceId
The LUID of the data source to remove.

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

### -Revision
(Delete Data Source Revision) The revision number of the data source to delete.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#delete_data_source](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#delete_data_source)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_data_source_revision](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_revisions.htm#remove_data_source_revision)

