---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Sign In (using username and password, or using PAT)"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
redirect_from: ["/PowerShell/PSTableauREST/Connect-TableauServer/", "/PowerShell/PSTableauREST/connect-tableauserver/", "/PowerShell/connect-tableauserver/"]
schema: 2.0.0
title: Connect-TableauServer
---

# Connect-TableauServer

## SYNOPSIS
Sign In (using username and password, or using PAT)

## SYNTAX

```
Connect-TableauServer [-ServerUrl] <String> [[-Username] <String>] [[-SecurePassword] <SecureString>]
 [[-PersonalAccessTokenName] <String>] [[-PersonalAccessTokenSecret] <SecureString>] [[-Site] <String>]
 [[-ImpersonateUserId] <String>] [[-UseServerVersion] <Boolean>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Signs you in as a user on the specified site on Tableau Server or Tableau Cloud.
This function initiates the session and stores the auth token that's needed for almost other REST API calls.
Authentication on Tableau Server (or Tableau Cloud) can be done with either
- username and password
- personal access token (PAT), using PAT name and PAT secret

## EXAMPLES

### EXAMPLE 1
```
$credentials = Connect-TableauServer -Server https://tableau.myserver.com -Username $user -SecurePassword $securePw
```

### EXAMPLE 2
```
$credentials = Connect-TableauServer -Server https://10ay.online.tableau.com -Site sandboxXXXXXXNNNNNN -PersonalAccessTokenName $pat_name -PersonalAccessTokenSecret $pat_secret
```

## PARAMETERS

### -ServerUrl
The URL of the Tableau Server, including the protocol (usually https://) and the FQDN (not including the URL path).
For Tableau Cloud, the server address in the URI must contain the pod name, such as 10az, 10ay, or us-east-1.

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

### -Username
The name of the user when signing in with username and password.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecurePassword
SecureString, containing the password when signing in with username and password.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessTokenName
The name of the personal access token when signing in with a personal access token.
The token name is available on a user's account page on Tableau server or online.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessTokenSecret
SecureString, containing the secret value of the personal access token when signing in with a personal access token.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Site
The permanent name of the site to sign in to (aka content URL).
By default, the default site with content URL "" is selected.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImpersonateUserId
The user ID to impersonate upon sign-in.
This can be only used by Server Administrators.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseServerVersion
Boolean, if true, sets current REST API version to the latest version supported by the Tableau Server.
Default is true.
If false, the minimum supported version 2.4 is retained.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: True
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
This function has to be called prior to other REST API function calls.
Typically, a credentials token is valid for 240 minutes.
With administrator permissions on Tableau Server you can increase this idle timeout.

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm)

