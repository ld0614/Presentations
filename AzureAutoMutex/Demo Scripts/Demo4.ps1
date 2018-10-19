Write-Verbose -Message "Attempting to load AzureAutoMutex"

Import-Module AzureAutoMutex -ErrorAction Stop -Force
$VerbosePreference = "continue"

$AutomationAccountRGName = "PSUG-VMDeployment"
$AutomationAccountName = "vmdeployment01"

Write-Verbose -Message "Module Loaded"

Login-AzureRMAccount

$mutex = & (Get-Module AzureAutoMutex).NewBoundScriptBlock({[AzureAutoMutex]::new($AutomationAccountRGName, $AutomationAccountName)})

Write-Output "Locking Mutex"

$mutex.LockWithCleanUpPSUGSpecial()
Write-Output "Lock acquired"

throw "Something went wrong"