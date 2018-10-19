**Abstract**

For many years IT departments have been configuring virtual machine templates within their hypervisor to assist with the automation of new virtual machines. With the advent of Azure the same functionality is not immediately available and the concept of ‘gold images’ is no longer required. This session will go through some of the advantages of automating virtual machine deployment for IT departments, explain how PowerShell and Desired State Configuration can be combined to minimize the time spent on common tasks and will demonstrate a basic build process with ideas for extendibility.

**Script Description**

* New-AzureVM.ps1 - This is the primary script which should be loaded into an Azure Automation Account
* Publish-AzureVMDSC - Publish the DSC config to a Azure Storage Account so that it can be later accessed by the New-AzureVM script
* ServerBaseline.ps1 - The DSC config for customizing the Operating System

**Presented**

PowerShell London UK User Group - 16th August 2018

**Notes**

While the code should work it was designed as a quick Proof of Concept to highlight the ideas in the talk.  As such is should not be used in Production without a careful understanding of its limitations.

