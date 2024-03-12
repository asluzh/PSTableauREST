# Get-TableauServerSettingsExtension

## SYNOPSIS
List Tableau extensions server settings
or
List dashboard extension settings of server - Retired in API 3.21

## SYNTAX

```
Get-TableauServerSettingsExtension
```

## DESCRIPTION
Lists the settings for extensions of a server.
This method can only be called by server administrators; it is not available on Tableau Cloud.
Note: for API prior to 3.21, the method calls a different API endpoint, which returns a JSON object - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-TableauServerSettingsExtension
```

## PARAMETERS

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#list_tableau_extensions_server_settings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#list_tableau_extensions_server_settings)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsServerSettings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsServerSettingsService_getDashboardExtensionsServerSettings)

