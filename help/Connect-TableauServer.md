---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
schema: 2.0.0
title: Connect-TableauServer
---

# Connect-TableauServer

## SYNOPSIS
Connect / Sign-In to Tableau Server or Tableau Cloud service.

## SYNTAX

```
Connect-TableauServer [-ServerUrl] <String> [-Credential] <PSCredential> [-PersonalAccessToken]
 [[-Site] <String>] [[-ImpersonateUserId] <String>] [[-UseServerVersion] <Boolean>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Signs in as a specific user on the specified site of Tableau Server or Tableau Cloud.
This function initiates the session and stores the auth token that's required for most other REST API calls.
Authentication on Tableau Server (or Tableau Cloud) can be done with either
- username and password
- personal access token (PAT), using PAT name and PAT secret

## EXAMPLES

### EXAMPLE 1
```
$credentials = Connect-TableauServer -Server https://tableau.myserver.com -Credential (New-Object System.Management.Automation.PSCredential ($user, $securePw))
```

### EXAMPLE 2
```
$credentials = Connect-TableauServer -Server https://10ay.online.tableau.com -Site sandboxXXXXXXNNNNNN -Credential $pat_credential -PersonalAccessToken
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

### -Credential
The credential object for signing in.
It contains either:
- username and password (as SecureString)
- name and the secret value of the personal access token

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken
This switch parameter indicates that the credential contain personal access token.
The token can be created/viewed on an account page of an individual user (on Tableau Server or Tableau Cloud).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
Position: 3
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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseServerVersion
Boolean, if true, sets current REST API version to the latest version supported by the Tableau Server.
Default is true.
If false, the minimum supported version (2.4) is retained.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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

