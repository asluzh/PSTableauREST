# Invoke-TableauRestMethod

## SYNOPSIS
Call Tableau Server REST API method

## SYNTAX

```
Invoke-TableauRestMethod [-Method] <WebRequestMethod> [-Uri] <Uri> [[-Body] <Object>] [[-InFile] <String>]
 [[-OutFile] <String>] [[-TimeoutSec] <Int32>] [[-ContentType] <String>] [-SkipCertificateCheck]
 [[-AddHeaders] <Hashtable>] [-NoStandardHeader] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Helper function that implements Tableau Server REST API calls with Invoke-RestMethod.
See help for Invoke-RestMethod for common parameters description.
This function should only be used by advanced users for non-implemented API calls.

## EXAMPLES

### EXAMPLE 1
```
$serverInfo = Invoke-TableauRestMethod -Uri $ServerUrl/api/$apiVersion/serverinfo -Method Get -NoStandardHeader
```

## PARAMETERS

### -Method
Specifies the method used for the web request.
The typical values for this parameter are:
Get, Post, Put, Delete, Patch, Options, Head

```yaml
Type: WebRequestMethod
Parameter Sets: (All)
Aliases:
Accepted values: Default, Get, Head, Post, Put, Delete, Trace, Options, Merge, Patch

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri
Specifies the Uniform Resource Identifier (URI) of the Internet resource to which the web request is sent.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
(Optional) Specifies the body of the request.
The body is the content of the request that follows the headers.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -InFile
(Optional) Gets the content of the web request from a file.
Enter a path and file name.
If you omit the path, the default is the current location.

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

### -OutFile
(Optional) Saves the response body in the specified output file.
Enter a path and file name.
If you omit the path, the default is the current location.

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

### -TimeoutSec
(Optional) Specifies how long the request can be pending before it times out.
Enter a value in seconds.
The default value, 0, specifies an indefinite time-out.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentType
(Optional) Specifies the content type of the web request.
Typical values: application/xml, application/json

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

### -SkipCertificateCheck
(Optional) Skips certificate validation checks that include all validations such as expiration,
revocation, trusted root authority, etc.

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

### -AddHeaders
(Optional) Specifies additional HTTP headers in a hashtable.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoStandardHeader
(Optional) Switch parameter, indicates not to include the standard Tableau Server auth token in the headers

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

## NOTES

## RELATED LINKS

[Invoke-RestMethod]()

