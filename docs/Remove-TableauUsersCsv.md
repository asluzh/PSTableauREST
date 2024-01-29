---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Delete Users from Site with CSV file"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#delete_users_from_site_with_csv
redirect_from: ["/PowerShell/PSTableauREST/Remove-TableauUsersCsv/", "/PowerShell/PSTableauREST/remove-tableauuserscsv/", "/PowerShell/remove-tableauuserscsv/"]
schema: 2.0.0
title: Remove-TableauUsersCsv
---

# Remove-TableauUsersCsv

## SYNOPSIS
Delete Users from Site with CSV file

## SYNTAX

```
Remove-TableauUsersCsv [-CsvFile] <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a job to remove a list of users, specified in a .csv file, from a site.

## EXAMPLES

### EXAMPLE 1
```
Remove-TableauUsersCsv -CsvFile users_to_remove.csv
```

## PARAMETERS

### -CsvFile
The CSV file with users to remove.
The .csv file should comply with the rules described in the CSV import file guidelines:
https://help.tableau.com/current/server/en-us/csvguidelines.htm

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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#delete_users_from_site_with_csv](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#delete_users_from_site_with_csv)

