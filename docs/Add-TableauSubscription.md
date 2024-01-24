---
author: tto
category: pstableaurest
date: 2024-01-24
excerpt: "Create Subscription"
external help file: PSTableauREST-help.xml
layout: pshelp
Module Name: PSTableauREST
online version:
redirect_from: ["/PowerShell/PSTableauREST/Add-TableauSubscription/", "/PowerShell/PSTableauREST/add-tableausubscription/", "/PowerShell/add-tableausubscription/"]
schema: 2.0.0
title: Add-TableauSubscription
---

# Add-TableauSubscription

## SYNOPSIS
Create Subscription

## SYNTAX

### ServerSchedule
```
Add-TableauSubscription -Subject <String> -Message <String> -UserId <String> -ContentType <String>
 -ContentId <String> [-SendIfViewEmpty <String>] [-AttachImage <String>] [-AttachPdf <String>]
 [-PageType <String>] [-PageOrientation <String>] -ScheduleId <String> [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CloudSchedule
```
Add-TableauSubscription -Subject <String> -Message <String> -UserId <String> -ContentType <String>
 -ContentId <String> [-SendIfViewEmpty <String>] [-AttachImage <String>] [-AttachPdf <String>]
 [-PageType <String>] [-PageOrientation <String>] -Frequency <String> -StartTime <String> [-EndTime <String>]
 [-IntervalHours <Int32>] [-IntervalMinutes <Int32>] [-IntervalWeekdays <String[]>]
 [-IntervalMonthdayNr <Int32>] [-IntervalMonthdayWeekday <String>] [-IntervalMonthdays <Int32[]>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new, unsuspended subscription to a view or workbook for a specific user on Tableau Server and Tableau Cloud.
When a user is subscribed to the content, Tableau sends the content to the user in email on the schedule that you define.

## EXAMPLES

### EXAMPLE 1
```
$subscription = Add-TableauSubscription -ScheduleId $subscriptionScheduleId -ContentType Workbook -ContentId $workbook.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId)
```

### EXAMPLE 2
```
$subscription = Add-TableauSubscription -ContentType View -ContentId $view.id -Subject "test" -Message "Test subscription" -UserId (Get-TableauCurrentUserId) -Frequency Weekly -StartTime 12:00:00 -IntervalWeekdays 'Sunday'
```

## PARAMETERS

### -Subject
A description, or subject for the subscription.
This subject is displayed when users list subscriptions for a site in the server environment.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
The text body of the subscription email message.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
The LUID of the user to create the subscription for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentType
Workbook to create a subscription for a workbook, or View to create a subscription for a view.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentId
The LUID of the workbook or view to subscribe to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SendIfViewEmpty
(Optional) Applies to views only.
If true, an image is sent even if the view specified in a subscription is empty.
If false, nothing is sent if the view is empty.
The default value is true.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -AttachImage
(Optional) Setting this true will cause the subscriber to receive mail with .png images of workbooks or views attached to it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -AttachPdf
(Optional) Setting this true will cause the subscriber to receive mail with a .pdf file containing images of workbooks or views attached to it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageType
(Optional, for PDF) The type of page, which determines the page dimensions of the .pdf file returned.
The value can be: A3, A4, A5, B5, Executive, Folio, Ledger, Legal, Letter, Note, Quarto, or Tabloid.
Default is A4.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: A4
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageOrientation
(Optional, for PDF) The orientation of the pages in the .pdf file produced.
The value can be Portrait or Landscape.
Default is Portrait.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Portrait
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduleId
(Optional) The ID of a schedule to associate the subscription with.
This needs to be provided only for Tableau Server Request, but not for Tableau Cloud.

```yaml
Type: String
Parameter Sets: ServerSchedule
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Frequency
(Optional, for Tableau Cloud) The frequency granularity of the schedule executions: Hourly, Daily, Weekly or Monthly.
If frequency is supplied, the StartTime and other relevant frequency details parameters need to be also provided.

```yaml
Type: String
Parameter Sets: CloudSchedule
Aliases:

Required: True
Position: Named
Default value: Daily
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
(Optional, for Tableau Cloud) The starting daytime for scheduled jobs.
For Hourly: the starting time of execution period (for example, 18:30:00).

```yaml
Type: String
Parameter Sets: CloudSchedule
Aliases:

Required: True
Position: Named
Default value: 00:00:00
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
(Optional, for Tableau Cloud) For Hourly: the ending time for execution period (for example, 21:00:00).

```yaml
Type: String
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalHours
(Optional, for Tableau Cloud) For Hourly: the interval in hours between schedule runs.
Valid value is 1.

```yaml
Type: Int32
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMinutes
(Optional, for Tableau Cloud) For Hourly: the interval in minutes between schedule runs.
Valid value is 60.

```yaml
Type: Int32
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalWeekdays
(Optional, for Tableau Cloud) For Hourly, Daily or Weekly: list of weekdays, when the schedule runs.
The week days are specified strings (weekday names in English).

```yaml
Type: String[]
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthdayNr
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g.
for 3rd Tuesday, the value 3 should be provided.
For last specific weekday day, the value 0 should be supplied.

```yaml
Type: Int32
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthdayWeekday
(Optional, for Tableau Cloud) For Monthly, describing which occurrence of a weekday within the month, e.g.
for 3rd Tuesday, the value 'Tuesday' should be provided.
For last day of the month, leave this parameter empty.

```yaml
Type: String
Parameter Sets: CloudSchedule
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntervalMonthdays
(Optional, for Tableau Cloud) For Monthly, describing specific days in a month, e.g.
for 3rd and 5th days, the list of values 3 and 5 should be provided.

```yaml
Type: Int32[]
Parameter Sets: CloudSchedule
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
https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_subscriptions.htm#create_subscription

## RELATED LINKS
