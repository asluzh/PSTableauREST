---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Get Recently Viewed for Site"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#get_recently_viewed
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauRecentlyViewedContent/", "/PowerShell/PSTableauREST/get-tableaurecentlyviewedcontent/", "/PowerShell/get-tableaurecentlyviewedcontent/"]
schema: 2.0.0
title: Get-TableauRecentlyViewedContent
---

# Get-TableauRecentlyViewedContent

## SYNOPSIS
Get Recently Viewed for Site

## SYNTAX

```
Get-TableauRecentlyViewedContent
```

## DESCRIPTION
Gets the details of the views and workbooks on a site that have been most recently created, updated, or accessed by the signed in user.
The 24 most recently viewed items are returned, though it may take some minutes after being viewed for an item to appear in the results.

## EXAMPLES

### EXAMPLE 1
```
$recents = Get-TableauRecentlyViewedContent
```

## PARAMETERS

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject[]
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#get_recently_viewed](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_site.htm#get_recently_viewed)

