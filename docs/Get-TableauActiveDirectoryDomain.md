---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "List Server Active Directory Domains"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#list_server_active_directory_domains
redirect_from: ["/PowerShell/PSTableauREST/Get-TableauActiveDirectoryDomain/", "/PowerShell/PSTableauREST/get-tableauactivedirectorydomain/", "/PowerShell/get-tableauactivedirectorydomain/"]
schema: 2.0.0
title: Get-TableauActiveDirectoryDomain
---

# Get-TableauActiveDirectoryDomain

## SYNOPSIS
List Server Active Directory Domains

## SYNTAX

```
Get-TableauActiveDirectoryDomain
```

## DESCRIPTION
Returns the details of the Active Directory domains that are in use on the server, including their full domain names, nicknames and IDs.
If the server is configured to use local authentication, the command returns only the domain name local.

## EXAMPLES

### EXAMPLE 1
```
$domains = Get-TableauActiveDirectoryDomain
```

## PARAMETERS

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#list_server_active_directory_domains](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_server.htm#list_server_active_directory_domains)

