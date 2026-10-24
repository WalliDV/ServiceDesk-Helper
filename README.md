# ServiceDesk Helper

**Config-driven PowerShell software deployment utility for Windows IT Support teams**

ServiceDesk Helper is a lightweight Windows desktop utility designed to simplify repetitive software installation and removal tasks for Service Desk and IT Support technicians.

The application uses an external JSON configuration file to define available software, installer paths, silent installation arguments, detection names and optional cleanup actions.

New applications can be added to the catalogue without modifying the main PowerShell script.

<p align="center">
  <img width="682" height="688" alt="image" src="https://github.com/user-attachments/assets/1ae8bb9c-a077-4771-b4fa-c6dbb2ed113f" />
</p>

---

## Overview

ServiceDesk Helper was created to solve a common support problem: technicians frequently need to install or remove the same applications across Windows endpoints, but manually locating installers, checking installation status and running different installation commands adds unnecessary repetitive work.

The tool provides a simple graphical interface where technicians can:

- view available applications;
- see whether software is already installed;
- select one or more applications;
- install selected software;
- uninstall selected software;
- monitor operation status and progress.

Application definitions are stored separately from the main script, making the software catalogue easy to maintain.

---

## Features

- **PowerShell WinForms GUI**
- **JSON-driven application catalogue**
- **Installed software detection**
- **Install / uninstall workflows**
- **Multiple application selection**
- **Per-application silent installation arguments**
- **Automatic administrator elevation**
- **Installation progress indicator**
- **On-screen operation log**
- **Post-operation status refresh**
- **Optional filesystem cleanup definitions**
- **Optional registry cleanup definitions**
- **Simple launcher for easier execution**
- **No third-party installer binaries distributed with the project**

---

## How It Works

```text
Apps.json
    │
    ▼
Application definitions
    │
    ▼
ServiceDesk Helper
    │
    ├── Detect installed software
    ├── Display application status
    ├── Install selected applications
    └── Uninstall selected applications
    │
    ▼
Windows Endpoint
```

The PowerShell application reads the local application catalogue from `Apps.json`.

Each application definition contains information such as:

- display name;
- software detection name;
- installer location;
- silent installation arguments;
- optional folders to clean after removal;
- optional registry entries to clean after removal.

This separates configuration from application logic and allows the catalogue to be changed without editing `installer.ps1`.

---

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell
- Administrator permissions for operations
- Local installer packages
- Correct silent installation parameters for configured applications

The application is intended for Windows environments.

---

## Getting Started

### 1. Download the project

Clone the repository or download it as a ZIP archive.

### 2. Create your local configuration

Configure:

```text
Apps.json
```

`Apps.json` is intentionally excluded from Git so that each environment can maintain its own local software catalogue.
Configure the applications using the appropriate installer paths, detection names and silent installation arguments.

### 3. Add installer packages

Place your software packages inside the `Installers` directory.

Example:

```text
Installers/
├── 7Zip/
│   └── 7zip-installer.exe
│
├── NotepadPP/
│   └── notepadpp-installer.exe
│
└── ExampleMSI/
    └── application.msi
```

### 4. Start the application

Run:

```text
RUNME.bat
```

or start `installer.ps1` from PowerShell with the required permissions.

---

## Application Configuration

Example application definition:

```json
{
  "Name": "7-Zip",
  "DetectionName": "7-Zip",
  "Installer": "Installers\\7Zip\\7zip-installer.exe",
  "Arguments": "/S",
  "CleanupFolders": [
    "C:\\Program Files\\7-Zip"
  ],
  "CleanupRegistry": [
    "HKLM:\\SOFTWARE\\7-Zip"
  ]
}
```

### Configuration Fields

| Field | Purpose |
|---|---|
| `Name` | Name displayed in the ServiceDesk Helper interface |
| `DetectionName` | Name used when checking whether the application is installed |
| `Installer` | Relative path to the installer package |
| `Arguments` | Command-line arguments used during installation |
| `CleanupFolders` | Optional folders that may be removed during cleanup |
| `CleanupRegistry` | Optional registry locations that may be removed during cleanup |

---

## Adding a New Application

Adding software does not require modifying the PowerShell application.

Example workflow:

```text
1. Add installer package
        ↓
2. Add application definition to Apps.json
        ↓
3. Start ServiceDesk Helper
        ↓
4. Application appears in the GUI
```

Silent installation parameters vary between applications and must be verified before use.

---

## Installer Packages

Third-party software installation packages are **not included** in this repository.

Users must provide their own installer files and ensure that they have appropriate licenses and redistribution rights.

This project does not grant any rights to distribute third-party software.

---

## Security Considerations

ServiceDesk Helper executes installer packages and may perform operations requiring administrative privileges.

Before using the tool in a managed or enterprise environment, administrators should review:

- installer origin and integrity;
- silent installation parameters;
- requested privileges;
- cleanup paths;
- cleanup registry entries;
- software licensing;
- application compatibility;
- organizational security policies.

Only trusted installation packages should be used.

The optional launcher changes the execution context only for starting the application and should be reviewed before use in managed environments.

---

## Important Cleanup Warning

`CleanupFolders` and `CleanupRegistry` can remove configured files or registry entries during application removal.

Incorrect configuration may remove unrelated data.

Always test cleanup definitions in a controlled environment before using them on production endpoints.

For applications that do not require additional cleanup, use empty arrays:

```json
"CleanupFolders": [],
"CleanupRegistry": []
```

---

## Intended Use

ServiceDesk Helper is designed as a lightweight technician utility for:

- IT Service Desk teams;
- desktop support;
- internal IT departments;
- lab environments;
- small IT teams;
- repetitive software deployment tasks.

---

## License

ServiceDesk Helper is released under the **MIT License**.

You may use, modify and distribute the project for personal, educational and commercial purposes, including internal enterprise use, subject to the terms of the license.

Third-party software installers are not covered by this license and remain subject to their respective licensing terms.

---

## Author

**Dmytro Vashkevych — WalliDV**

[GitHub](https://github.com/WalliDV)  
[LinkedIn](https://www.linkedin.com/in/dmytro-vashkevych)

---

*Built as a practical PowerShell automation project for Windows IT Support workflows.
