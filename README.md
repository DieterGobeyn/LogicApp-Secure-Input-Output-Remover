# Logic App Secure Input/Output Remover

This repository contains scripts and sample configuration files to remove secure input/output settings from all workflows within an Azure Logic App Standard. This tool is intended for use in development and testing environments only. **DO NOT USE THIS SCRIPT IN PRODUCTION.**

Logic Apps with secure input/output settings are designed to protect sensitive data or credentials. While this is essential for production environments, non-production environments often do not have the same requirements. This script modifies these parameters in non-production environments to facilitate testing and development processes.

## Blog Post
For a detailed explanation and step-by-step guide, check out our blog post: [Automate Secure Config Removal in Azure Logic Apps](https://azuretechinsider.com/logic-app-secure-input-output-removal/)

## Contents
- `RemoveSecureInputOutput.ps1`: PowerShell script to remove secure input/output configurations from a specified Logic App.
- `Sample_pipeline.yml`: Azure DevOps pipeline configuration sample to automate the execution of the script in a pipeline.

## Prerequisites
- Azure subscription with [necessary permissions to connect with Kudu](https://learn.microsoft.com/en-us/azure/app-service/resources-kudu).
- Logic App Standard deployed in the specified subscription.
- PowerShell v6 or higher installed on the local machine or the build agent.
- Azure DevOps setup. (optional)

## RemoveSecureInputOutput.ps1
This script removes secure input/output configurations from an Azure Logic App Standard. It iterates over all workflows in the Logic App Standard and removes the settings accordingly.

**Input Parameters**
- `$LogicAppName`:  Name of the Logic App Standard

## Authentication
The script uses the active Azure connection. Ensure the correct connection and subscription are set prior to execution.

## Execute locally (sample)
    Connect-AzAccount
    .\RemoveSecureInputOutput.ps1 -LogicAppName 'MyLogicAppNameHere'

## Not in scope:
- Logic App Consumption
- Power Automate Flow

## Note:
- Not recommended to run this on a Production environment
- It is tested with limited test cases and volume of runs, validate this first