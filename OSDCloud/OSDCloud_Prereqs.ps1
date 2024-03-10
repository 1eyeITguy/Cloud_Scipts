#Requires -RunAsAdministrator
<#
.DESCRIPTION
Installs WinGet, Microsoft ADK and the Windows PE add-on for Windows 11, version 22H2, and MDT using WinGet.  ALso installs the OSDCloud 
PowerShell module if not intalled. 
.LINK
https://www.osdcloud.com/osdcloud/setup
#>
[CmdletBinding()]
param()

if (Get-Command 'WinGet' -ErrorAction SilentlyContinue) {
    Write-Host -ForegroundColor Green -Message '[+] WinGet is installed.'
} else {
    try {
        Invoke-Expression (Invoke-RestMethod -uri "https://raw.githubusercontent.com/1eyeITguy/Cloud_Scipts/main/WinGet/Install-WinGet_Server2022.ps1")
    }
    catch {
        Write-Error -Message 'WinGet could not be installed.'
    }
}

if (Get-Command 'WinGet' -ErrorAction SilentlyContinue) {

# Microsoft ADK Windows 11 22H2 10.1.22621.1
Write-Host -ForegroundColor Green "[+] Installing the Windows ADK"
winget install --id Microsoft.WindowsADK --version 10.1.22621.1 --exact --accept-source-agreements --accept-package-agreements

Write-Host -ForegroundColor Green "[+] Installing the WinPE Add-On"
winget install --id Microsoft.ADKPEAddon --version 10.1.22621.1 --exact --accept-source-agreements --accept-package-agreements

New-Item -Path 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs' -ItemType Directory -Force | Out-Null

# Microsoft Deployment Toolkit
Write-Host -ForegroundColor Green "[+] Installing MDT"
winget install --id Microsoft.DeploymentToolkit --version 6.3.8456.1000 --exact --accept-source-agreements --accept-package-agreements
} else {
    Write-Error -Message 'WinGet is not installed.'
}

# Check if the OSD module is installed
if (-not (Get-Module -ListAvailable -Name OSD)) {
    Write-Host -ForegroundColor Yellow "[!] OSD module is not installed. Installing the latest version..."

    Write-Host -ForegroundColor Green "[+] Transport Layer Security (TLS) 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Pre-Load some OSDCloud functions
    Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_anywhere.psm1')
    osdcloud-InstallPackageManagement
    osdcloud-TrustPSGallery

    # Install the OSD module from the PowerShell Gallery
    Install-Module -Name OSD -Force

    # Import the newly installed module
    Import-Module -Name OSD
    Write-Host -ForegroundColor Green "[+] OSD module has been installed and imported."
} else {
    Write-Host -ForegroundColor Green "[+} OSD module is already installed."
}