---
author: tto
category: pstableaurest
date: 2023-11-28
excerpt: "Encrypt Extracts in a Site / Decrypt Extracts in a Site / Reencrypt Extracts in a Site"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#encrypt_extracts
redirect_from: ["/PowerShell/PSTableauREST/Invoke-TSEncryption/", "/PowerShell/PSTableauREST/invoke-tsencryption/", "/PowerShell/invoke-tsencryption/"]
schema: 2.0.0
title: Invoke-TSEncryption
---

# Invoke-TSEncryption

## SYNOPSIS
Encrypt Extracts in a Site / Decrypt Extracts in a Site / Reencrypt Extracts in a Site

## SYNTAX

### Encrypt
```
Invoke-TSEncryption [-EncryptExtracts] [-SiteId <String>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Decrypt
```
Invoke-TSEncryption [-DecryptExtracts] [-SiteId <String>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Reencrypt
```
Invoke-TSEncryption [-ReencryptExtracts] [-SiteId <String>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Encrypts, decrypts or re-encrypts all extracts with new encryption keys on the specified site.
Extract encryption at rest is a data security feature that allows you to encrypt .hyper extracts while they are stored on Tableau Server.
Note: Depending on the number and size of extracts, this operation may consume significant server resources.
Consider running this command outside of normal business hours.

## EXAMPLES

### EXAMPLE 1
```
Invoke-TSEncryption -EncryptExtracts
```

## PARAMETERS

### -EncryptExtracts
Boolean switch, if supplied, the encryption of all extracts is triggered.

```yaml
Type: SwitchParameter
Parameter Sets: Encrypt
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DecryptExtracts
Boolean switch, if supplied, the decryption of all extracts is triggered.

```yaml
Type: SwitchParameter
Parameter Sets: Decrypt
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReencryptExtracts
Boolean switch, if supplied, the re-encryption of all extracts is triggered.

```yaml
Type: SwitchParameter
Parameter Sets: Reencrypt
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteId
Site LUID where the encryption process should be conducted.
If omitted, the current site is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#encrypt_extracts](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#encrypt_extracts)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#decrypt_extracts](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#decrypt_extracts)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#reencrypt_extracts](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_extract_and_encryption.htm#reencrypt_extracts)

