
<#
.SYNOPSIS
Automated Deployment Script for OSD Module Update and Configuration.

.DESCRIPTION
This script is designed to facilitate the automated update and configuration of the OSD (Operating System Deployment) module. It ensures that the module is up-to-date, properly configured, and provides a seamless deployment experience. The script handles the installation of the OSD module, updates if necessary, and configures various components related to deployment.

.NOTES
Author: Matthew Miles
Created: March 10, 2024
Version: 1.0

#>

$brand = 'Sight & Sound Theatres'
$wallpaperPath = "E:\SSWallpaper2017_1920x1080.jpg"


$choice = Read-Host "Would you like to check update your PowerShell modules? (Yes(Y) / No(N) / Cancel(C))"

if ($choice -eq "y" -or $choice -eq "yes") {
    Write-Host -ForegroundColor Green "[+] Updating all PowerShell modules"
    Invoke-Expression (Invoke-RestMethod -uri "https://raw.githubusercontent.com/1eyeITguy/Cloud_Scipts/main/Modules/Update-ModuleVersions.ps1")    
} elseif ($choice -eq "n" -or $choice -eq "no") {
    Write-Host -ForegroundColor Yellow "[-] Not updating modules, continuing with the rest of the script..."
} elseif ($choice -eq "c" -or $choice -eq "cancel") {
    Write-Warning "Script execution canceled."
    Exit
} else {
    Write-Warning "Invalid choice. Please select 'y'/'yes', 'n'/'no', or 'c'/'cancel'."
}

function Remove-Workspaces {
    [CmdletBinding()]
    param ()

# Delete the old OSDCloud template and workspace

$directoriesToDelete = @("C:\ProgramData\OSDCloud", "C:\OSDCloud")

foreach ($dir in $directoriesToDelete) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host -ForegroundColor DarkGray "Deleting directory: $dir"
        Remove-Item -Path $dir -Recurse -Force
    } else {
        Write-Warning "Directory not found: $dir"
    }
}
}

# Remove old workspaces and templates
Remove-Workspaces

# Create new OSDCloud template
New-OSDCloudTemplate

# Create new OSDCloud Workspace
New-OSDCloudWorkspace

# Edit the WinPE image with branding and all drivers
Edit-OSDCloudWinPE -StartOSDCloudGUI -Brand $brand -CloudDriver * -Wallpaper $wallpaperPath

# Set OSDCloudGUI Defaults for the PXE boot image
# Set the path to the boot.wim file
$BootWimPath = "C:\OSDCloud\Media\sources\boot.wim"
$MountPath = "C:\Mount"
$DestinationPath = "$MountPath\OSDCloud\Automate"

# Check if the $MountPath directory exists
if (-not (Test-Path -Path $MountPath)) {
    # Create the directory
    New-Item -ItemType Directory -Path $MountPath
    Write-Host -ForegroundColor Green "[+] Directory $MountPath has been created."
} else {
    Write-Host -ForegroundColor Green "[+] Directory $MountPath already exists."
}

# Mount the boot.wim file
Mount-WindowsImage -ImagePath $BootWimPath -Index 1 -Path $MountPath

# Set OSDCloudGUI Defaults
$Global:OSDCloud_Defaults = [ordered]@{
BrandName = $brand
BrandColor = "Orange"
OSActivation = "Retail"
OSEdition = "Pro"
OSLanguage = "en-us"
OSImageIndex = 9
OSName = "Windows 11 23H2 x64"
OSReleaseID = "23H2"
OSVersion = "Windows 11"
OSActivationValues = @(
"Volume",
"Retail"
)
OSEditionValues = @(
"Enterprise",
"Pro"
)
OSLanguageValues = @(
"en-us"
)
OSNameValues = @(
"Windows 11 23H2 x64",
"Windows 10 22H2 x64"
)
OSReleaseIDValues = @(
"23H2"
)
OSVersionValues = @(
"Windows 11",
"Windows 10"
)
captureScreenshots = $false
ClearDiskConfirm = $false
restartComputer = $true
updateDiskDrivers = $true
updateFirmware = $true
updateNetworkDrivers = $true
updateSCSIDrivers = $true
}

# Convert the OSDCloud_Defaults variable to JSON format
$OSDCloud_Defaults_JSON = $Global:OSDCloud_Defaults | ConvertTo-Json

# Create 'Start-OSDCloudGUI.json' within the mounted image
$OSDCloudGUIjson = New-Item -Path "$DestinationPath\Start-OSDCloudGUI.json" -Force

# Write the contents of the OSDCloud_Defaults_JSON variable to the Start-OSDCloudGUI.json file
Set-Content -Path $OSDCloudGUIjson.FullName -Value $OSDCloud_Defaults_JSON

# Save changes and unmount the image
Dismount-WindowsImage -Path $MountPath -Save

# Clean up the C:\Mount directory by deleting all files in it
Remove-Item -Path "$MountPath\*" -Recurse -Force
