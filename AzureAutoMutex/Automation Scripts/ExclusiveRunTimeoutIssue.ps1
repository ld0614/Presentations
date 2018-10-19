Write-Verbose -Message "Attempting to load AzureAutoMutex"

Import-Module AzureAutoMutex -ErrorAction Stop -Force
$VerbosePreference = "continue"

$AutomationAccountRGName = "PSUG-VMDeployment"
$AutomationAccountName = "vmdeployment01"

Write-Verbose -Message "Module Loaded"

<#
    Log into Azure using the automatic service principle
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$mutex = & (Get-Module AzureAutoMutex).NewBoundScriptBlock({[AzureAutoMutex]::new($AutomationAccountRGName, $AutomationAccountName)})

Write-Output "Locking Mutex"

#Set timeout to only 10 seconds
$mutex.lock(10)
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