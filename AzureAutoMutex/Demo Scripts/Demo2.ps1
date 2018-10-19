Write-Verbose -Message "Attempting to load AzureAutoMutex"

Import-Module AzureAutoMutex -ErrorAction Stop -Force
$VerbosePreference = "continue"

$AutomationAccountRGName = "PSUG-VMDeployment"
$AutomationAccountName = "vmdeployment01"

Login-AzureRMAccount

Write-Verbose -Message "Module Loaded"

$mutex = & (Get-Module AzureAutoMutex).NewBoundScriptBlock({[AzureAutoMutex]::new($AutomationAccountRGName, $AutomationAccountName)})

Write-Output "Locking Mutex"

$mutex.lock()
Write-Output "Lock acquired"

Write-Output "Sleeping for 60 seconds"

for ($i = 1; $i -lt 60; $i++)
{
    Write-Output "Sleeping..."
    Start-Sleep -Seconds 1
}

Write-Output "Sleep Complete"

Write-Output "Unlocking Mutex"

$mutex.Unlock()

Write-Output "Unlock Complete"