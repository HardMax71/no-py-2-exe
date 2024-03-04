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

# Check for the /help parameter and display script information
if ($Help) {
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "`t.\scriptName.ps1 [PARAMETERS]`n"

    Write-Host "PARAMETER DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "`t-ScanSystem`n`t`tChecks for Python presence in the entire system. Default is $true."
    Write-Host "`t`tExample: -ScanSystem:$false to disable system scan.`n"

    Write-Host "`t-ScanDrives`n`t`tSpecifies which drives to scan. Default is 'C:,D:'."
    Write-Host "`t`tExample: -ScanDrives 'E:,F:' to scan drives E: and F:.`n"

    Write-Host "`t-AllowCancel`n`t`tAllows to cancel execution. Default is $false."
    Write-Host "`t`tExample: -AllowCancel:$true to allow installation cancellation.`n"

    Write-Host "`t-InstallPython`n`t`tInstalls Python if not found. Default is $true."
    Write-Host "`t`tExample: -InstallPython:$false to not install Python.`n"

    Write-Host "`t-SetupEnvironment`n`t`tCreates and activates a virtual environment. Default is $true."
    Write-Host "`t`tExample: -SetupEnvironment:$false to not create an environment.`n"

    Write-Host "`t-InstallDependencies`n`t`tInstalls libraries from requirements.txt. Default is $true."
    Write-Host "`t`tExample: -InstallDependencies:$false to not install dependencies.`n"

    Write-Host "`t-PythonVersion`n`t`tSpecifies the Python version to install. Default is '3.11.7'."
    Write-Host "`t`tExample: -PythonVersion '3.9.1' to install Python 3.9.1.`n"

    Write-Host "`t-UpdatePip`n`t`tUpdates pip to the latest version. Default is $true."
    Write-Host "`t`tExample: -UpdatePip:$false to not update pip.`n"

    Write-Host "`t-RequiredSpaceInGB`n`t`tRequired amount of free disk space in GB. Default is 1.0."
    Write-Host "`t`tExample: -RequiredSpaceInGB 2.5 for installation if at least 2.5 GB is available.`n"

    Write-Host "`t-RecreateEnvironment`n`t`tRecreates the virtual environment if it already exists. Default is $false."
    Write-Host "`t`tExample: -RecreateEnvironment:$true to recreate the environment.`n"

    Write-Host "`t-RemoveEnvironment`n`t`tRemoves the virtual environment if it exists. Default is $false."
    Write-Host "`t`tExample: -RemoveEnvironment:$true to remove the environment.`n"

    Write-Host "`t-ScriptName`n`t`tSpecifies the Python script to execute. Default is 'main.py'."
    Write-Host "`t`tExample: -ScriptName 'script.py' to execute 'script.py'.`n"

    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "`t.\start.ps1 -ScanSystem:$false -InstallPython:$true -PythonVersion '3.8.10' -UpdatePip:$true -ScriptName 'other_script.py'" -ForegroundColor Green
    Write-Host "`t.\start.ps1 -AllowCancel:$true -SetupEnvironment:$false -ScriptName 'run_me.py'`n" -ForegroundColor Green
    Pause
    Exit
}

# Setting the character encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# To run in Windows PS ISE: execute the command below in the shell
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Write-Host "###########################################" -ForegroundColor Yellow
Write-Host "#                                         #" -ForegroundColor Yellow
Write-Host "#     Automatic Python Installation       #" -ForegroundColor Yellow
Write-Host "#                                         #" -ForegroundColor Yellow
Write-Host "###########################################" -ForegroundColor Yellow
Write-Host "#                                         #" -ForegroundColor Yellow
Write-Host "# 1. Downloading and Installing Python    #" -ForegroundColor Yellow
Write-Host "# 2. Creating a Virtual Environment       #" -ForegroundColor Yellow
Write-Host "# 3. Installing Necessary Libraries       #" -ForegroundColor Yellow
Write-Host "#                                         #" -ForegroundColor Yellow
Write-Host "###########################################" -ForegroundColor Yellow
Write-Host "`nSeveral gigabytes of free space may be required to continue the installation.`n" -ForegroundColor Red
Write-Host "Current script run parameters:" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow
Write-Host "Scan System: $ScanSystem" -ForegroundColor Yellow
Write-Host "Scan Drives: $ScanDrives" -ForegroundColor Yellow
Write-Host "Allow Cancel: $AllowCancel" -ForegroundColor Yellow
Write-Host "Install Python: $InstallPython" -ForegroundColor Yellow
Write-Host "Setup Environment: $SetupEnvironment" -ForegroundColor Yellow
Write-Host "Install Dependencies: $InstallDependencies" -ForegroundColor Yellow
Write-Host "Python Version: $PythonVersion" -ForegroundColor Yellow
Write-Host "Update Pip: $UpdatePip" -ForegroundColor Yellow
Write-Host "Required Space: $RequiredSpaceInGB GB" -ForegroundColor Yellow
Write-Host "Recreate Environment: $RecreateEnvironment" -ForegroundColor Yellow
Write-Host "Remove Environment: $RemoveEnvironment" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow

if ($AllowCancel) {
    Write-Host "Press any key to continue or X to cancel the installation." -ForegroundColor Yellow
    $userInput = Read-Host "Select action"

    if ($userInput -ieq "X") {
        Write-Host "Installation canceled by the user. You may close the window." -ForegroundColor Red
        Pause
        exit
    }
}

Write-Host "Checking for an internet connection.."
try {
    $response = Invoke-WebRequest -Uri "http://www.python.org" -UseBasicParsing -TimeoutSec 5
    Write-Host "Internet connection is available." -ForegroundColor Green
} catch {
    Write-Host "No internet connection. Check your connection." -ForegroundColor Red
    Pause
    exit
}

$scanChoice = $ScanSystem
$scanDrives = $ScanDrives.Split(",").Trim()

if ($scanChoice) {
    Write-Host "You have chosen to scan the system for python.exe." -ForegroundColor Yellow
    $pythonPaths = Get-ChildItem -Path $scanDrives -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'python[0-9.-]*\.exe$' } |
        Select-Object -ExpandProperty DirectoryName
} else {
    Write-Host "Scanning the system path for python.exe." -ForegroundColor Yellow
    $pathDirs = $env:PATH -split ';'
    $pythonPaths = $pathDirs | Where-Object { Test-Path "$_\python.exe" } | ForEach-Object { $_ }
}

if ($InstallPython -and $pythonPaths.Count -eq 0) {
    Write-Host "Python not found in standard locations. Attempting to install Python..." -ForegroundColor Red

    # Checking available disk space
    $drive = Get-PSDrive -Name (Get-Location).Drive.Name
    if ($drive.Free -lt $RequiredSpaceInGB * 1GB) {
        Write-Host "Not enough disk space to continue the installation. At least $RequiredSpaceInGB GB is required." -ForegroundColor Red
        Pause
        exit
    }

    # Maybe use winget? But it requires previous installation..
    $pythonInstaller = "python-$PythonVersion.exe"
    $pythonUrl = "https://www.python.org/ftp/python/$PythonVersion/$pythonInstaller"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
    Write-Host "Download completed." -ForegroundColor Green

    Write-Host "Installing Python..."
    Start-Process $pythonInstaller -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait -NoNewWindow
    Write-Host "Python version $PythonVersion successfully installed." -ForegroundColor Green
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
        Write-Host "You have selected Python at: $pythonPath" -ForegroundColor Green
    } else {
        Write-Host "Invalid input. Please enter a number corresponding to one of the listed paths." -ForegroundColor Red
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
        Write-Host "Python version $PythonVersion successfully installed." -ForegroundColor Green
    } else {
        throw "Python version does not match the expected: $PythonVersion"
    }
} catch {
    Write-Host "Error checking Python installation: $_" -ForegroundColor Red
    Pause
    exit
}

# Virtual environment management
$venvPath = ".\venv"
if ($RemoveEnvironment -and (Test-Path $venvPath)) {
    Write-Host "Removing existing virtual environment at $venvPath..." -ForegroundColor Yellow
    Remove-Item -Path $venvPath -Recurse -Force
    Write-Host "Virtual environment removed." -ForegroundColor Green
}

if ($SetupEnvironment -or $RecreateEnvironment) {
    if (Test-Path $venvPath) {
        if ($RecreateEnvironment) {
            Write-Host "Recreating virtual environment at $venvPath..." -ForegroundColor Yellow
            Remove-Item -Path $venvPath -Recurse -Force
            Write-Host "Old virtual environment removed." -ForegroundColor Green

            Write-Host "Creating virtual environment at $venvPath..." -ForegroundColor Yellow
            & "$pythonPath\python.exe" -m venv $venvPath
            Write-Host "Virtual environment created." -ForegroundColor Green
        } else {
            Write-Host "Virtual environment already exists at $venvPath. Using existing one." -ForegroundColor Yellow
        }
    }
}

if (Test-Path $venvPath) {
    # Activating the virtual environment
    $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        Write-Host "Activating virtual environment..." -ForegroundColor Yellow
        . $activateScript
    } else {
        Write-Host "Activation script not found: $activateScript" -ForegroundColor Red
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
    Write-Host "Error executing script $ScriptName" -ForegroundColor Red
} else {
    Write-Host "Installation and script execution for $ScriptName completed." -ForegroundColor Green
}


Pause
