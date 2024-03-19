#Requires -RunAsAdministrator
<#
.DESCRIPTION
Installs WinGet, Microsoft ADK and the Windows PE add-on for Windows 11, version 22H2, and MDT.  ALso installs the OSDCloud 
PowerShell module if not intalled. 
.LINK
https://www.osdcloud.com/osdcloud/setup
#>
[CmdletBinding()]
param()

# Define the download URLs
$adkUrl = "https://download.microsoft.com/download/6/7/4/674ec7db-7c89-4f2b-8363-689055c2b430/adk/adksetup.exe"
$addonUrl = "https://download.microsoft.com/download/5/2/5/525dcde0-c7b8-487a-894d-0952775a78c7/adkwinpeaddons/adkwinpesetup.exe"
$mdtUrl = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"

# Define the installation paths
$adkInstallerPath = "C:\temp\adksetup.exe"
$addonInstallerPath = "C:\temp\adkwinpesetup.exe"
$mdtInstallerPath = "C:\temp\MicrosoftDeploymentToolkit_x64.msi"

# Create C:\temp directory if it doesn't exist
if (-not (Test-Path -Path "C:\temp" -PathType Container)) {
    New-Item -Path "C:\temp" -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Green "[+] Created C:\Temp Directory"
}

# Download the installers using curl 
curl -Uri $adkUrl -OutFile $adkInstallerPath
curl -Uri $addonUrl -OutFile $addonInstallerPath
curl -Uri $mdtUrl -OutFile $mdtInstallerPath

# Install ADK silently
Write-Host -ForegroundColor Yellow "[-] Installing Windows ADK..."
Start-Process -FilePath $adkInstallerPath -ArgumentList "/quiet" -Wait
Write-Host -ForegroundColor Green "[+] Windows ADK Installed"

# Install WinPE Addon silently
Write-Host -ForegroundColor Yellow "[-] Installing WinPE Add-On..."
Start-Process -FilePath $addonInstallerPath -ArgumentList "/quiet" -Wait
Write-Host -ForegroundColor Green "[+] WinPE Add-On installed"

# Install MDT silently
Write-Host -ForegroundColor Yellow "[-] Installing MDT..."
Start-Process -FilePath msiexec.exe -ArgumentList "/i $mdtInstallerPath /quiet" -Wait
New-Item -Path 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs' -ItemType Directory -Force | Out-Null
Write-Host -ForegroundColor Green "[+] MDT Installed"

# Clean up: Delete the downloaded installers
Remove-Item -Path $adkInstallerPath, $addonInstallerPath, $mdtInstallerPath -Force | Out-Null

Write-Host -ForegroundColor Green "[+] Windows ADK, WinPE Addon, and MDT have been installed silently."


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
    Write-Host -ForegroundColor Green "[+] OSD module is already installed."
}
