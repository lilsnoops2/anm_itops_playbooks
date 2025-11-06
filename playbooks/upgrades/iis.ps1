# Ensure script is running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator!"
    exit
}

# Check if IIS is installed
$feature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole

if ($feature.State -ne "Enabled") {
    Write-Output "IIS is not installed. Installing IIS..."
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
    Write-Output "IIS installation complete."
} else {
    Write-Output "IIS is already installed."
}

Import-Module WebAdministration

# Define the site and virtual directory parameters
$siteName = "Default Web Site"
$vDirName = "http"

# Ensure Default Web Site exists
$defaultSite = Get-Website -Name $siteName -ErrorAction SilentlyContinue
if (-not $defaultSite) {
    Write-Output "Default Web Site does not exist. Creating it..."
    $rootPath = "C:\inetpub\wwwroot"
    if (-not (Test-Path $rootPath)) {
        New-Item -Path $rootPath -ItemType Directory -Force
    }
    New-Website -Name $siteName -Port 80 -PhysicalPath $rootPath -Force
    Write-Output "Default Web Site created."
} else {
    Write-Output "Default Web Site already exists."
}

# Get the current user's Desktop path
$desktopPath = [Environment]::GetFolderPath("Desktop")
$physicalPath = Join-Path $desktopPath $vDirName

# Create physical path if it doesn't exist
if (-not (Test-Path $physicalPath)) {
    Write-Output "Creating physical directory at $physicalPath"
    New-Item -Path $physicalPath -ItemType Directory -Force
}

# Grant IIS_IUSRS read/execute permissions to the folder
$acl = Get-Acl $physicalPath
$permission = "IIS_IUSRS","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
if (-not ($acl.Access | Where-Object { $_.IdentityReference -eq "IIS_IUSRS" })) {
    $acl.AddAccessRule($accessRule)
    Set-Acl $physicalPath $acl
    Write-Output "Granted Read/Execute permissions to IIS_IUSRS for $physicalPath"
}

# Check if virtual directory exists
$vDir = Get-WebVirtualDirectory -Site $siteName -Name $vDirName -ErrorAction SilentlyContinue

if (-not $vDir) {
    Write-Output "Creating virtual directory '$vDirName' under '$siteName'"
    New-WebVirtualDirectory -Site $siteName -Name $vDirName -PhysicalPath $physicalPath
} else {
    Write-Output "Virtual directory '$vDirName' already exists."
}

# Enable Directory Browsing
Write-Output "Enabling Directory Browsing for '$vDirName'"
Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -PSPath "IIS:\Sites\$siteName\$vDirName" -Name "enabled" -Value $true

Write-Output "Script completed successfully!"
