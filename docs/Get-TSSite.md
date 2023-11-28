---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Query Site / Query Sites"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_site
redirect_from: ["/PowerShell/PSTableauREST/Get-TSSite/", "/PowerShell/PSTableauREST/get-tssite/", "/PowerShell/get-tssite/"]
schema: 2.0.0
title: Get-TSSite
---

# Get-TSSite

## SYNOPSIS
Query Site / Query Sites

## SYNTAX

### CurrentSite
```
Get-TSSite [-Current] [-IncludeUsageStatistics] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Sites
```
Get-TSSite [-PageSize <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Option 1: $Current = $true
Returns information about the specified site, with the option to return information about the storage space and user count for the site.
Option 2: $Current = $false
Returns a list of the sites on the server that the caller of this method has access to.
This method is not available for Tableau Cloud.

## EXAMPLES

### EXAMPLE 1
```
$site = Get-TSSite -Current
```

## PARAMETERS

### -Current
Boolean switch, specifies if only the current site (where the user session is signed in) is returned (option 1), or all sites (option 2).

```yaml
Type: SwitchParameter
Parameter Sets: CurrentSite
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeUsageStatistics
(Optional for current site)
Boolean switch, specifies if site usage statistics should be included in the response.

```yaml
Type: SwitchParameter
Parameter Sets: CurrentSite
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
(Optional) Page size when paging through results.

```yaml
Type: Int32
Parameter Sets: Sites
Aliases:

Required: False
Position: Named
Default value: 100
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

### System.Management.Automation.PSObject[]
## NOTES
Notes on API query options: it's also possible to use ?key=contentUrl to get site, but also works only with current site.
It's also possible to use ?key=name to get site, but also works only with current site.
Thus it doesn't make much sense to implement these options

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_site)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_sites](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#query_sites)

