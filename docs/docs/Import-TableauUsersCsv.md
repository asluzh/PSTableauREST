---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Import Users to Site from CSV file"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#import_users_to_site_from_csv
redirect_from: ["/PowerShell/PSTableauREST/Import-TableauUsersCsv/", "/PowerShell/PSTableauREST/import-tableauuserscsv/", "/PowerShell/import-tableauuserscsv/"]
schema: 2.0.0
title: Import-TableauUsersCsv
---

# Import-TableauUsersCsv

## SYNOPSIS
Import Users to Site from CSV file

## SYNTAX

### UserAuthSettings
```
Import-TableauUsersCsv -CsvFile <String> -UserAuthSettings <Hashtable> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AuthSetting
```
Import-TableauUsersCsv -CsvFile <String> -AuthSetting <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### OnlyCsv
```
Import-TableauUsersCsv -CsvFile <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a job to import the users listed in a specified .csv file to a site, and assign their roles and authorization settings.

## EXAMPLES

### EXAMPLE 1
```
Import-TableauUsersCsv -CsvFile users_to_add.csv
```

## PARAMETERS

### -CsvFile
The CSV file with users to import.
The .csv file should comply with the rules described in the CSV import file guidelines:
https://help.tableau.com/current/server/en-us/csvguidelines.htm

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthSetting
The auth setting that will be applied for all imported users.
The setting should be one of the values: ServerDefault, SAML, OpenID, TableauIDWithMFA

```yaml
Type: String
Parameter Sets: AuthSetting
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserAuthSettings
The hashtable array with user names (key) and their individual auth setting (value).

```yaml
Type: Hashtable
Parameter Sets: UserAuthSettings
Aliases:

Required: True
Position: Named
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#import_users_to_site_from_csv](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm#import_users_to_site_from_csv)

