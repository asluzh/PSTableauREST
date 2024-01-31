# Publish-TableauDatasource

## SYNOPSIS
Publish Data Source

## SYNTAX

```
Publish-TableauDatasource [-InFile] <String> [-Name] <String> [[-FileName] <String>] [[-FileType] <String>]
 [[-Description] <String>] [[-ProjectId] <String>] [-Overwrite] [-Append] [-BackgroundTask] [-Chunked]
 [-UseRemoteQueryAgent] [[-Credentials] <Hashtable>] [[-Connections] <Hashtable[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Publishes supplied data source.

## EXAMPLES

### EXAMPLE 1
```
$datasource = Publish-TableauDatasource -Name $sampleDatasourceName -InFile "Superstore_2023.tdsx" -ProjectId $samplesProjectId -Overwrite
```

### EXAMPLE 2
```
$datasource = Publish-TableauDatasource -Name "Datasource" -InFile "data.hyper" -ProjectId $samplesProjectId -Append -Chunked
```

## PARAMETERS

### -InFile
The filename (incl.
path) of the data source to upload and publish.

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
The name for the published data source.

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
(Optional) The file type of the data source file.
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
(Optional) The description for the published data source.

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
(Optional) The LUID of the project to assign the data source to.
If the project is not specified, the data source will be published to the default project.

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

### -Overwrite
(Optional) Boolean switch, if supplied, the data source will be overwritten (otherwise existing published data source with the same name is not overwritten).

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

### -Append
(Optional) Boolean switch, if supplied, the data will be appended to the existin data source.
If the data source doesn't already exist, the operation will fail.
Append flag cannot be used together with the Overwrite flag.

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

### -UseRemoteQueryAgent
(Optional) When true, this flag will allow your Tableau Cloud site to use Tableau Bridge clients.
Bridge allows you to maintain data sources with live connections to supported on-premises data sources.

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
Position: 7
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
Position: 8
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#publish_data_source](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_data_sources.htm#publish_data_source)

