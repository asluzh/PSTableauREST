---
author: tto
category: pstableaurest
date: 2024-01-29
excerpt: "Perform File Upload in Chunks"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#initiate_file_upload
redirect_from: ["/PowerShell/PSTableauREST/Send-TableauFileUpload/", "/PowerShell/PSTableauREST/send-tableaufileupload/", "/PowerShell/send-tableaufileupload/"]
schema: 2.0.0
title: Send-TableauFileUpload
---

# Send-TableauFileUpload

## SYNOPSIS
Perform File Upload in Chunks

## SYNTAX

```
Send-TableauFileUpload [-InFile] <String> [[-FileName] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Initiates the upload process for a file, and then performs Append to File Upload to send individual blocks of the file to the server.
When the complete file has been sent to the server, the result (upload id string) can be used to publish the file as workbook, datasource or flow.
Note: this is an internal routine for Publish- methods, should not be used separately.

## EXAMPLES

### EXAMPLE 1
```
$uploadSessionId = Send-TableauFileUpload -InFile $InFile -FileName $FileName
```

## PARAMETERS

### -InFile
The filename of the file to upload.

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

### -FileName
(Optional) The filename (without path) that is included into the request payload.
This usually doesn't matter for Tableau Server uploads.
By default, the filename is sent as "file".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: File
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

### System.String
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#initiate_file_upload](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#initiate_file_upload)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#append_to_file_upload](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_publishing.htm#append_to_file_upload)

