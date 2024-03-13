# Get-TableauSiteSettingsExtension

## SYNOPSIS
List Tableau extensions site settings
or
List dashboard extension settings of site - Retired in API 3.21

## SYNTAX

```
Get-TableauSiteSettingsExtension
```

## DESCRIPTION
Lists the settings for extensions of a site.
This method can only be called by site or server administrators.
Note: for API prior to 3.21, the method calls a different API endpoint, which returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-TableauSiteSettingsExtension
```

## PARAMETERS

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#list_tableau_extensions_site_settings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_tableau_extensions_settings.htm#list_tableau_extensions_site_settings)

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_getDashboardExtensionsSiteSettings](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_dashboard_extensions_settings.htm#DashboardExtensionsSiteSettingsService_getDashboardExtensionsSiteSettings)

