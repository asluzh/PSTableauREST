# PSTableauREST
This is a PowerShell module that facilitates working with Tableau Server REST API and implements wrapper functions for the API calls. For testing the functionality, a free Developer access to Tableau Cloud is recommended.

# Command Overview

## Invoke-TSSignIn
Implements Sign-In API call and retrieves an Auth Token that will be used in all subsequent REST API calls.

## Invoke-TSSignOut
Implements Sign-Out API call and thus terminates previously acquired Auth Token.

## Get-TSServerInfo
Gets Tableau Server parameters, such as latest supported API version. This method doesn't require an Auth Token.
