$ExclusiveRun = "https://s2events.azure-automation.net/webhooks?token=UPDATEME"
$ExclusiveRunNamedMutex = "https://s2events.azure-automation.net/webhooks?token=UPDATEME"
$ExclusiveRunTimeout = "https://s2events.azure-automation.net/webhooks?token=UPDATEME"
$ExclusiveRunAlwaysFail = "https://s2events.azure-automation.net/webhooks?token=UPDATEME"

#Start two runbooks simultaneously
Invoke-WebRequest -Uri $ExclusiveRun -Method Post
Invoke-WebRequest -Uri $ExclusiveRun -Method Post

#Run script locally
."Demo2.ps1"

#Run with different names
$mutexName1 = @{MutexName="Dept1"}
Invoke-WebRequest -Uri $ExclusiveRunNamedMutex -Method Post -Body (ConvertTo-Json -InputObject $mutexName1)
Invoke-WebRequest -Uri $ExclusiveRunNamedMutex -Method Post -Body (ConvertTo-Json -InputObject $mutexName1)
$mutexName2 = @{MutexName="Dept2"}
Invoke-WebRequest -Uri $ExclusiveRunNamedMutex -Method Post -Body (ConvertTo-Json -InputObject $mutexName2)
Invoke-WebRequest -Uri $ExclusiveRunNamedMutex -Method Post -Body (ConvertTo-Json -InputObject $mutexName2)

#Run different Names locally
."Demo3.ps1"

#Fail due to timeout
Invoke-WebRequest -Uri $ExclusiveRunTimeout -Method Post
Invoke-WebRequest -Uri $ExclusiveRunTimeout -Method Post

#Crash locks forever
Invoke-WebRequest -Uri $ExclusiveRunAlwaysFail -Method Post
Invoke-WebRequest -Uri $ExclusiveRunAlwaysFail -Method Post

#Crash script but recover mutex
."Demo4.ps1"