# Elite System Monitor

## Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/Nipfswd/Scripts
2. Navigate to the script directory:
```sh
cd your_directory
```
3. Ensure PowerShell is installed and accessible.

# Cleanup.bat

## How to use

1. Save as cleanup.bat

2. Run as Administrator (needed for Windows Temp & clearing logs)

3. Watch the progress

# Safe_Mode_Toggle.bat

## Usage
1. Run as Administrator (very important)

2. Choose 1 to enable Safe Mode boot (next reboot boots into Safe Mode)

3. Choose 2 to disable Safe Mode boot (normal boot resumes)

4. Reboot to test!

# env_diag.bat

## How to use:

1. Save as env_diag.bat

2. Run as Administrator (some info needs elevated rights)

3. Wait for it to complete

4. Find the generated log file in the same folder, named like env_diagnostics_2025-06-23.txt

# How to use:

1. Save it as looplab.bat
2. Run it
3. Set the target directory,filters,size limits,recursion
4. Enter your custom action using variables:
| Placeholder | Description                  |
|-------------|------------------------------|
| %%F         | filename (with extension)     |
| %%P         | full file path                |
| %%D         | directory                     |
| %%E         | file extension (with dot)     |
| %%N         | filename without extension    |

