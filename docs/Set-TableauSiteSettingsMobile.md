# Set-TableauSiteSettingsMobile

## SYNOPSIS
Update Mobile Security Settings for Site

## SYNTAX

```
Set-TableauSiteSettingsMobile [-Settings] <Hashtable[]> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Updates the mobile security sections for a specified site.
This method can only be called by server administrators.

## EXAMPLES

### EXAMPLE 1
```
$settings = Set-TableauSiteSettingsMobile -Settings @{name='mobile.security.jailbroken_device';enabled='true';iosConfig=@{valueList=@('true');severity='warn'};androidConfig=@{valueList=@('false');severity='critical'}}
```

## PARAMETERS

### -Settings
List of mobile security settings, each as a hashtable for each individual settings params, corresponding to the input json element (mobileSecuritySettings).

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_mobile_settings.htm#Update_mobile_security_settings_for_site](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_mobile_settings.htm#Update_mobile_security_settings_for_site)

