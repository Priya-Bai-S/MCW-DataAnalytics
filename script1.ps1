Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,

    [string]
    $AzurePassword,

    [string]
    $AzureTenantID,

    [string]
    $AzureSubscriptionID,

    [string]
    $ODLID,
    
    [string]
    $DeploymentID,

    [string]
    $azuserobjectid,

    [string]
    $adminUsername,

    [string]
    $adminPassword     
)
Start-Transcript -Path C:\Logs\logontasklogs1.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

#InstallAzPowerShellModule
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")
sleep 5
Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose


#Install synapse modules
Install-PackageProvider NuGet -Force
Install-Module -Name Az.Synapse -RequiredVersion 0.3.0 -AllowClobber -Force
  
sleep 5


#Install-Module -Name Az.Synapse -RequiredVersion 1.0.0 -Force
$userName = $AzureUserName
$password = $AzurePassword


$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*BigData-$deploymentId*" }).ResourceGroupName
$deploymentId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri "https://github.com/Priya-Bai-S/MCW-DataAnalytics/blob/main/bigdatasynapse.json" -TemplateParameterUri "https://github.com/Priya-Bai-S/MCW-DataAnalytics/blob/main/synapseparam.json"


Stop-Transcript

#To not display Server Manager automatically at logon
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord

#To Disable IE Enhanced Security Configuration
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

# Resolves an error caused by Powershell defaulting to TLS 1.0 to connect to website, but website security requires TLS 1.2.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"

# Disable IE ESC
Disable-InternetExplorerESC


#install Chocolatey
Function InstallChocolatey
{   
    $env:chocolateyUseWindowsCompression = 'true'
    $env:chocolateyIgnoreRebootDetected = 'true'
    $env:chocolateyVersion = '1.4.0'
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation
}
InstallChocolatey

#install powerbi 
choco install powerbi -y 

#install microsoft edge
choco install microsoft-edge -y

#install vi
choco install visualstudio2019community --package-parameters "--add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.NetWeb" -y

#uninstall Chocolatey
choco uninstall chocolatey -y --force


#Install az module 
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Repository PSGallery -Force
Update-Module -Name Az -Force -y

Restart-Computer -Force

