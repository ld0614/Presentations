**Abstract**

While running multiple runbooks and multiple instances of a runbook is often a good thing there are times when this can cause unexpected or undesired behaviour. This session will explain some of the reasons why undesired behaviour may occur and will then talk through a potential solution using Azure Automation Variables. The session will finish with a demonstration of sample code showing how multiple runbooks and multiple instances can safely share resources.

**Script Description**

* Demo1.ps1 - This is the script used to show off parts of the module
* Demo2.ps1 - Basic use of the module running locally
* Demo3.ps1 - Showing a local script using a specific named mutex
* Demo4.ps1 - Intentionally failing script to show of the use of the automatic cleanup of mutexes
* ExclusiveRun.ps1 - Basic use of the module running in an Azure Automation Account
* ExclusiveRunAlwaysFail.ps1 - Demonstrates that unless the LockWithCleanUp method is called a failure will lock indefinably requiring manual effort to clear
* ExclusiveRunNamedMutex.ps1 - Demonstrates a script using a specific named mutex
* ExclusiveRunTimeoutIssue.ps1 - Demonstrates a instance with a timeout so short any other instance will cause the second runbook to fail
**Presented**

PowerShell London UK User Group - 19th October 2018

**Notes**

* While the code should work it was designed as a quick Proof of Concept to highlight the ideas in the talk.  As such is should not be used in Production without a careful understanding of its limitations.
* The module can either be used as a class or as a series of cmdlets
* The full module is available from https://github.com/ld0614/AzureAutoMutex
