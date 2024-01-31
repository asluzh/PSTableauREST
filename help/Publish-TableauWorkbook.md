---
external help file: PSTableauREST-help.xml
Module Name: PSTableauREST
online version: https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#publish_workbook
schema: 2.0.0
title: Publish-TableauWorkbook
---

# Publish-TableauWorkbook

## SYNOPSIS
Publish Workbook

## SYNTAX

```
Publish-TableauWorkbook [-InFile] <String> [-Name] <String> [[-FileName] <String>] [[-FileType] <String>]
 [[-Description] <String>] [[-ProjectId] <String>] [-ShowTabs] [[-HideViews] <Hashtable>]
 [[-ThumbnailsUserId] <String>] [-Overwrite] [-SkipConnectionCheck] [-BackgroundTask] [-Chunked]
 [[-Credentials] <Hashtable>] [[-Connections] <Hashtable[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Publishes supplied workbook.

## EXAMPLES

### EXAMPLE 1
```
$workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "Superstore.twbx" -ProjectId $samplesProjectId
```

### EXAMPLE 2
```
$workbook = Publish-TableauWorkbook -Name $sampleWorkbookName -InFile "Superstore.twbx" -ProjectId $samplesProjectId -Overwrite -HideViews @{Shipping="true";Performance="true";Forecast="true"}
```

## PARAMETERS

### -InFile
The filename (incl.
path) of the workbook to upload and publish.

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

### -Name
The name for the published workbook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName
(Optional) The filename (without path) that is included into the request payload.
If omitted, the filename is derived from the InFile parameter.

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

### -FileType
(Optional) The file type of the workbook file.
If omitted, the file type is derived from the Filename parameter.

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

### -Description
(Optional) The description for the published workbook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectId
(Optional) The LUID of the project to assign the workbook to.
If the project is not specified, the workbook will be published to the default project.

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

### -ShowTabs
(Optional) Boolean switch, if supplied, the published workbook shows views in tabs.

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

### -HideViews
(Optional) Hashtable, containing the mapping of view names and true/false if the specific view should be hidden in the published workbook.
If omitted, all original views are snown.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThumbnailsUserId
(Optional) The LUID of the user to generate thumbnails as.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Overwrite
(Optional) Boolean switch, if supplied, the workbook will be overwritten (otherwise existing published workbook with the same name is not overwritten).

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

### -SkipConnectionCheck
(Optional) Boolean switch, if supplied, Tableau server will not check if a non-published connection of a workbook is reachable.

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

### -BackgroundTask
(Optional) Boolean switch, if supplied, the publishing process (its final stage) is run asynchronously.

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

### -Chunked
(Optional) Boolean switch, if supplied, the publish process is forced to run as chunked.
By default, the payload is send in one request for files \< 64MB size.
This can be helpful if timeouts occur during upload.

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

### -Credentials
(Optional) Hashtable containing connection credentials (see online help).

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connections
(Optional) Hashtable array containing connection attributes and credentials (see online help).

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#publish_workbook](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_workbooks_and_views.htm#publish_workbook)

