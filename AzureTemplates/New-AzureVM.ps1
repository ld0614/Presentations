<#
Copyright (c) 2018 Leo D'Arcy - leo.darcy@outlook.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
    Define the required parameters
#>

Param
(
    [Parameter(Mandatory = $true)]
    [ValidateLength(3,4)]
    [String]
    $VMCode,
    [Parameter(Mandatory = $true)]
    [String]
    $VMSize,
    [Parameter(Mandatory = $true, HelpMessage="DEV, TEST or LIVE")]
    [ValidateSet('DEV', 'TEST', 'PROD')]
    [String]
    $Environment,
    [Parameter(Mandatory = $true)]
    [String]
    $CostCode,
    [Parameter(HelpMessage="UK South or West Europe")]
    [ValidateSet('UK South', 'West Europe')]
    [String]
    $Location='West Europe',
    [Parameter()]
    [ValidateSet('Standard', 'Premium')]
    [String]
    $DiskType='Standard',
    [Parameter()]
    [ValidateRange(1,99)]
    [Int]
    $ResourceGroupNumber=1,
    [Parameter()]
    [ValidateRange(1,99)]
    [Int]
    $VMNumber=1,
    [Parameter()]
    [Bool]
    $DomainJoin=$true,
    [Parameter()]
    [Bool]
    $RunBaseline=$true
)

<#
    Define Functions
#>

Function Get-AzureRMVMDSCLatestExtentionVersion
{
    Param
    (
        [String]
        $Location="West Europe"
    )
    $DSCPublisher = "Microsoft.PowerShell"
    $Type = "DSC"
    $ImageVersions = Get-AzureRmVMExtensionImage -Location $Location -PublisherName $DSCPublisher -Type $Type
    $LatestVersion = $ImageVersions | %{[System.Version]$_.Version} | Sort-Object -Descending | Select-Object -First 1
    return "$($LatestVersion.Major).$($LatestVersion.Minor)"
}

<#
    Define Static Variables
#>

#VNet Settings
$VNetName = "PSUGVNet"
$VNetRGName = "PSUGVNetRG"
#Timezone Settings
$Timezone = "GMT Standard Time"
#VMSource Image
$Publisher = "MicrosoftWindowsServer"
$Offer = "WindowsServer"
$SKU = "2016-Datacenter"
$Version = "latest"
#Domain Options
$ADDomain = "Test.local"
$ADOUPath = "OU=TestComputers,DC=Test,DC=Local"
#DSC Configuration
$DSCStorageAccountName = "storageaccount01"
$DSCStorageAccountResourceGroupName = "storageaccountrg-01"

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

<#
    Access Azure Automation Resources
#>

$DefaultAdmin = Get-AutomationPSCredential -Name "DefaultAdmin"
$DomainCred = Get-AutomationPSCredential -Name "DomainJoinAccount"

<#
    Generate other variables
#>

$errorActionPreference = "Stop"

Switch ($DiskType)
{
    "Standard"
    {
        $DiskTypeName = "Standard_LRS"
    }
    "Premium"
    {
        $DiskTypeName = "Premium_LRS"
    }
    default
    {
        throw "Unknown disk type $DiskType"
    }
}

Switch ($Location)
{
    "West Europe"
    {
        $LocationShortCode = "WEU"
    }
    "North Europe"
    {
        $LocationShortCode = "NEU"
    }
    "UK South"
    {
        $LocationShortCode = "UKS"
    }
    "UK West"
    {
        $LocationShortCode = "UKW"
    }
    default
    {
        throw "Unknown location $location"
    }
}

$TrimmedLocation = $Location.Replace(' ','').ToLower()

Switch ($Environment)
{
    "DEV"
    {
        $SubnetName = "Development"
    }
    "TEST"
    {
        $SubnetName = "Testing"
    }
    "PROD"
    {
        $SubnetName = "Production"
    }
    default
    {
        throw "Unknown location $Environment"
    }
}

$RGNumber = $ResourceGroupNumber.ToString("00")
$LongVMNumber = $VMNumber.ToString("00")

$RGName = "RG-$Environment-$LocationShortCode-$VMCode-$RGNumber"
$VMName = "AZ-$LocationShortCode-$VMCode-$LongVMNumber"
$NICName = "$VMName-NIC-01"
$OSDiskName = "$VMName-osDisk"
$DataDiskName = "$VMName-Data-01"

$VMTags = @{
    Environment = $Environment
    CodeCode = $CostCode
}

Write-Verbose -Message "Resource Group name: $RGName"
Write-Verbose -Message "Virtual Machine name: $VMName"

<#
    Check resources exist
#>

$CurrentVM = Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName -ErrorAction SilentlyContinue
if ($null -ne $CurrentVM)
{
    Throw "Virtual Machine $VMName already exists"
}

#Get Virtual Network and subnet
$VirtualNetwork = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $VNetRGName -ErrorAction Stop
if ($VirtualNetwork.Location -ne $TrimmedLocation)
{
    Throw "Virtual network not located in $Location"
}

$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork -ErrorAction Stop

<#
    Create required resources
#>

#Create Resource Group
$ResourceGroup = Get-AzureRmResourceGroup -Name $RGName -ErrorAction SilentlyContinue
if ($null -eq $ResourceGroup)
{
    $ResourceGroup = New-AzureRmResourceGroup -Name $RGName -Location $Location -ErrorAction Stop
}
else
{
    if ($ResourceGroup.Location -ne $TrimmedLocation)
    {
        Throw "Resource Group already exists in another location"
    }
}

#Create NIC
$VMNIC = Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RGName -ErrorAction SilentlyContinue
if ($null -eq $VMNIC)
{
    $VMNIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RGName -Location $Location -SubnetId $Subnet.Id -ErrorAction Stop
}
elseif ($null -ne $VMNIC.VirtualMachine)
{
    Throw "$NICName is already in use"
}
elseif ($VMNIC.Location -ne $TrimmedLocation)
{
    Throw "$NICName is not in the correct region"
}

<#
    Create VM
#>

$VMConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -Tags $VMTags
$VMConfig = Set-AzureRmVMOperatingSystem -VM $VMConfig -Windows -ComputerName $VMName -Credential $DefaultAdmin -TimeZone $Timezone
$VMConfig = Set-AzureRmVMSourceImage -VM $VMConfig -PublisherName $Publisher -Offer $Offer -Skus $SKU -Version $Version
$VMConfig = Add-AzureRmVMNetworkInterface -VM $VMConfig -Id $VMNIC.Id -Primary
$VMConfig = Set-AzureRmVMOSDisk -VM $VMConfig -Name $OSDiskName -CreateOption FromImage -StorageAccountType $DiskTypeName

Write-Output "Creating VM"
$VMStatus = New-AzureRmVM -ResourceGroupName $RGName -Location $Location -VM $VMConfig
Write-Output "VM Created"

$VM = Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName

<#
    Set Static IP Address
#>

$VMNIC = Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RGName
Write-Output "New VM IP Address: $($VMNIC.IpConfigurations[0].PrivateIpAddress)"

<#
    Domain Join the VM
#>

if ($domainJoin)
{
    Write-Output "Joining Domain"
    Set-AzureRmVMADDomainExtension -ResourceGroupName $RGName -VMName $VMName -Location $Location -DomainName $ADDomain -OUPath $ADOUPath -JoinOption 3 -Credential $DomainCred -Restart
}

<#
    Deploy DSC
#>

if ($RunBaseline)
{
    Write-Output "Running Post Deployment Configuration"
    $DSCStatus = Set-AzureRmVMDscExtension -ResourceGroupName $RGName -VMName $VMName -Name "ServerBaseline" -ArchiveResourceGroupName $DSCStorageAccountResourceGroupName -ArchiveStorageAccountName $DSCStorageAccountName -ArchiveBlobName "ServerBaseline.ps1.zip" -Version (Get-AzureRMVMDSCLatestExtentionVersion -Location $Location) -ConfigurationName "ServerBaseline"
    Write-Output "VM Build Complete, Post build configuration status: $($DSCStatus.StatusCode)"
}
