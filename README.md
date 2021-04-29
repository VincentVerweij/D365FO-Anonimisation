# D365FO-Anonimisation
A SQL simple script which can be used to anonimize data which is coming from a customer's environment on a OneBox.

## The SQL script
This script can be used to apply on a backup that comes from Production or any other environment.
It will anonimize several tables but not all of them.
If you see that some crucial data is left untouched please be so kind to change it.

## Goal
The goal I want to achieve by putting this here is that we get a general script which can be used over companies.
This applies only to standard Microsoft Dynamics 365 for Finance and Operations (although some things can still be used in AX2012 as well).
Most companies have to anonimize their data to stay compliant with things like GDPR.
But we all need data to troubleshoot sometimes, and if there is a general anonimization script that can be applied that is benefit for all of us.