# Get-TableauAuthConfiguration

## SYNOPSIS
List Authentication Configurations

## SYNTAX

```
Get-TableauAuthConfiguration
```

## DESCRIPTION
List information about all authentication instances.
This method can only be called by users with server administrator permissions.
This method returns a PSCustomObject from JSON - see online help for more details.

## EXAMPLES

### EXAMPLE 1
```
$instances = Get-TableauAuthConfiguration
```

## PARAMETERS

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#AuthnService_ListAuthConfigurations](https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_identity_pools.htm#AuthnService_ListAuthConfigurations)

