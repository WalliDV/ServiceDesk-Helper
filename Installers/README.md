# Installer Repository

Place third-party software installation packages in this directory.

Installer binaries are intentionally not included in the public repository.

Example structure:

```text
Installers/
├── 7Zip/
│   └── 7zip-installer.exe
├── NotepadPP/
│   └── notepadpp-installer.exe
└── ExampleMSI/
    └── application.msi
```

Application paths must match the values configured in `Apps.json`.

Users are responsible for obtaining software installation packages from legitimate sources and complying with the respective software licenses and distribution terms.

Only trusted installer packages should be used.
