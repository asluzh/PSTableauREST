---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#switch_site
schema: 2.0.0
title: Switch-TableauSite
---

# Switch-TableauSite

## SYNOPSIS
Switch Site

## SYNTAX

```
Switch-TableauSite [[-Site] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Switches you onto another site of Tableau Server without having to provide a user name and password again.

## EXAMPLES

### EXAMPLE 1
```
$credentials = Switch-TableauSite -Site 'mySite'
```

## PARAMETERS

### -Site
The permanent name of the site to sign in to (aka content URL).
E.g.
mySite is the content URL in the following example:
http://\<server or cloud URL\>/#/site/mySite/explore

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

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#switch_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm#switch_site)

