param (
    [switch]$ScanSystem = $true,
    [string]$ScanDrives = "C:,D:",
    [switch]$AllowCancel = $false,
    [switch]$Help,
    [switch]$InstallPython = $true,
    [switch]$SetupEnvironment = $true,
    [switch]$RecreateEnvironment = $false,
    [switch]$RemoveEnvironment = $false,
    [switch]$InstallDependencies = $true,
    [string]$PythonVersion = "3.11.7",
    [switch]$UpdatePip = $true,
    [double]$RequiredSpaceInGB = 1.0,
    [string]$ScriptName = "main.py"
)

function WriteError([string] $message)
{
    Write-Host $message -ForegroundColor Red
}

function WriteWarning([string] $message)
{
    Write-Host $message -ForegroundColor Yellow
}

function WriteSuccess([string] $message)
{
    Write-Host $message -ForegroundColor Green
}

# Check for the /help parameter and display script information
if ($Help) {
    WriteWarning @"
USAGE:
    .\scriptName.ps1 [PARAMETERS]

PARAMETER DESCRIPTION:
    -ScanSystem
        Checks for Python presence in the entire system. Default is $true.
        Example: -ScanSystem:$false to disable system scan.

    -ScanDrives
        Specifies which drives to scan. Default is 'C:,D:'.
        Example: -ScanDrives 'E:,F:' to scan drives E: and F:.

    -AllowCancel
        Allows to cancel execution. Default is $false.
        Example: -AllowCancel:$true to allow installation cancellation.

    -InstallPython
        Installs Python if not found. Default is $true.
        Example: -InstallPython:$false to not install Python.

    -SetupEnvironment
        Creates and activates a virtual environment. Default is $true.
        Example: -SetupEnvironment:$false to not create an environment.

    -InstallDependencies
        Installs libraries from requirements.txt. Default is $true.
        Example: -InstallDependencies:$false to not install dependencies.

    -PythonVersion
        Specifies the Python version to install. Default is '3.11.7'.
        Example: -PythonVersion '3.9.1' to install Python 3.9.1.

    -UpdatePip
        Updates pip to the latest version. Default is $true.
        Example: -UpdatePip:$false to not update pip.

    -RequiredSpaceInGB
        Required amount of free disk space in GB. Default is 1.0.
        Example: -RequiredSpaceInGB 2.5 for installation if at least 2.5 GB is available.

    -RecreateEnvironment
        Recreates the virtual environment if it already exists. Default is $false.
        Example: -RecreateEnvironment:$true to recreate the environment.

    -RemoveEnvironment
        Removes the virtual environment if it exists. Default is $false.
        Example: -RemoveEnvironment:$true to remove the environment.

    -ScriptName
        Specifies the Python script to execute. Default is 'main.py'.
        Example: -ScriptName 'script.py' to execute 'script.py'.

EXAMPLES:
    .\start.ps1 -ScanSystem:$false -InstallPython:$true -PythonVersion '3.8.10' -UpdatePip:$true -ScriptName 'other_script.py'
    .\start.ps1 -AllowCancel:$true -SetupEnvironment:$false -ScriptName 'run_me.py'

"@ 

    Pause
    Exit
}

# Setting the character encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# To run in Windows PS ISE: execute the command below in the shell
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

WriteWarning = @"
###########################################
#                                         #
#     Automatic Python Installation       #
#                                         #
###########################################
#                                         #
# 1. Downloading and Installing Python    #
# 2. Creating a Virtual Environment       #
# 3. Installing Necessary Libraries       #
#                                         #
###########################################

"@

WriteError "Several gigabytes of free space may be required to continue the installation."

WriteWarning @"

Current script run parameters:
---------------------------------
Scan System: $ScanSystem
Scan Drives: $ScanDrives
Allow Cancel: $AllowCancel
Install Python: $InstallPython
Setup Environment: $SetupEnvironment
Install Dependencies: $InstallDependencies
Python Version: $PythonVersion
Update Pip: $UpdatePip
Required Space: $RequiredSpaceInGB GB
Recreate Environment: $RecreateEnvironment
Remove Environment: $RemoveEnvironment
---------------------------------
"@ 

if ($AllowCancel) {
    WriteWarning "Press any key to continue or X to cancel the installation."
    $userInput = Read-Host "Select action"

    if ($userInput -ieq "X") {
        WriteError "Installation canceled by the user. You may close the window." 
        Pause
        exit
    }
}

Write-Host "Checking for an internet connection.."
try {
    $response = Invoke-WebRequest -Uri "http://www.python.org" -UseBasicParsing -TimeoutSec 5
    WriteSuccess "Internet connection is available."
} catch {
    WriteError "No internet connection. Check your connection."
    Pause
    exit
}

$scanChoice = $ScanSystem
$scanDrives = $ScanDrives.Split(",").Trim()

if ($scanChoice) {
    WriteWarning "You have chosen to scan the system for python.exe."
    $pythonPaths = Get-ChildItem -Path $scanDrives -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'python[0-9.-]*\.exe$' } |
        Select-Object -ExpandProperty DirectoryName
} else {
    WriteWarning "Scanning the system path for python.exe."
    $pathDirs = $env:PATH -split ';'
    $pythonPaths = $pathDirs | Where-Object { Test-Path "$_\python.exe" } | ForEach-Object { $_ }
}

if ($InstallPython -and $pythonPaths.Count -eq 0) {
    WriteError "Python not found in standard locations. Attempting to install Python..." 

    # Checking available disk space
    $drive = Get-PSDrive -Name (Get-Location).Drive.Name
    if ($drive.Free -lt $RequiredSpaceInGB * 1GB) {
        WriteError "Not enough disk space to continue the installation. At least $RequiredSpaceInGB GB is required."
        Pause
        exit
    }

    # Maybe use winget? But it requires previous installation..
    $pythonInstaller = "python-$PythonVersion.exe"
    $pythonUrl = "https://www.python.org/ftp/python/$PythonVersion/$pythonInstaller"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
    WriteSuccess "Download completed."

    Write-Host "Installing Python..."
    Start-Process $pythonInstaller -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait -NoNewWindow
    WriteSuccess "Python version $PythonVersion successfully installed."
} elseif ($pythonPaths.Count -eq 1) {
    $pythonPath = $pythonPaths[0]
    Write-Host "Found Python at: $pythonPath"
} else {
    Write-Host "Multiple Python installations found:"
    $i = 1
    foreach ($path in $pythonPaths) {
        Write-Host "$i`: $path"
        $i++
    }

    $selectedPythonIndex = Read-Host "Enter the number of the desired Python installation"
    if ($selectedPythonIndex -and $selectedPythonIndex -match '^\d+$' -and $selectedPythonIndex -le $pythonPaths.Count) {
        $pythonPath = $pythonPaths[$selectedPythonIndex - 1]
        WriteSuccess "You have selected Python at: $pythonPath"
    } else {
        WriteError "Invalid input. Please enter a number corresponding to one of the listed paths."
        Pause
        exit
    }
}

# Path where Python is expected to be after installation
$pythonExecutable = Join-Path -Path $pythonPath -ChildPath "python.exe"

# Checking for presence
try {
    $pythonVersionOutput = & "$pythonPath\python.exe" --version
    if ($pythonVersionOutput -like "Python $PythonVersion*") {
        WriteSuccess "Python version $PythonVersion successfully installed."
    } else {
        throw "Python version does not match the expected: $PythonVersion"
    }
} catch {
    WriteError "Error checking Python installation: $_"
    Pause
    exit
}

# Virtual environment management
$venvPath = ".\venv"
if ($RemoveEnvironment -and (Test-Path $venvPath)) {
    WriteWarning "Removing existing virtual environment at $venvPath..." 
    Remove-Item -Path $venvPath -Recurse -Force
    WriteSuccess "Virtual environment removed."
}

if ($SetupEnvironment -or $RecreateEnvironment) {
    if (Test-Path $venvPath) {
        if ($RecreateEnvironment) {
            WriteWarning "Recreating virtual environment at $venvPath..."
            Remove-Item -Path $venvPath -Recurse -Force
            WriteSuccess "Old virtual environment removed." 

            WriteWarning "Creating virtual environment at $venvPath..."
            & "$pythonPath\python.exe" -m venv $venvPath
            WriteSuccess "Virtual environment created." 
        } else {
            WriteWarning "Virtual environment already exists at $venvPath. Using existing one." 
        }
    }
}

if (Test-Path $venvPath) {
    # Activating the virtual environment
    $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        WriteWarning "Activating virtual environment..."
        . $activateScript
    } else {
        WriteError "Activation script not found: $activateScript"
    }
}


# Updating pip
if ($SetupEnvironment) {
    & "$pythonPath\python.exe" -m pip install --upgrade pip
}

# Installing dependencies
if ($InstallDependencies) {
    Write-Host "Installing necessary libraries..."
    & "$pythonPath\python.exe" -m pip install -r requirements.txt
}

# Running the specified script
Write-Host "Launching script $ScriptName..."
& "$pythonExecutable" $ScriptName
if ($LASTEXITCODE -ne 0) {
    WriteError "Error executing script $ScriptName"
} else {
    WriteSuccess "Installation and script execution for $ScriptName completed."
}


Pause
