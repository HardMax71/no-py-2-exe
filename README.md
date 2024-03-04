# NoPy2Exe: Native Python Script Execution with PowerShell

NoPy2Exe is a PowerShell script that allows you to directly execute Python scripts on 
Windows without needing to bundle them into stand-alone EXE files. 
This avoids the hassle, increased complexity, and larger file sizes that come with 
converting Python code to executables.

## Key Features
- Automatically installs Python and sets up a virtual environment
- Handles all dependency installation requirements
- Activates the virtual environment transparently
- Executes target Python scripts natively from PowerShell
- Easy customization of Python version and scripts

NoPy2Exe dramatically simplifies deploying and running Python scripts - 
just point it at your code and go! No more troublesome exe wrapping getting in the way.

# Getting Started
To use NoPy2Exe, simply download `start.ps1` and execute:

```powershell
.\start.ps1 -ScriptName your_script.py
```

By default, NoPy2Exe is configured to:

- Scan C: and D: drives for existing Python installations
- Install `Python 3.11.7` if not found
- Create a `.\venv` virtual environment
- Install all dependencies from `requirements.txt`
- Execute a script called `main.py`

> See the help docs in start.ps1 for additional default values.

---

## Limitations

- Requires Windows and PowerShell to run
- Requires admin rights when installing downloaded Python version to the system