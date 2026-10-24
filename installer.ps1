# START

Write-Host "Script Started"

#Admin privilege

Write-Host "Privilege escalation..."

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator))
{
    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    exit
}


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Apps list from JSON
$AppsConfig = Get-Content "$PSScriptRoot\Apps.json" -Raw |
              ConvertFrom-Json

# -----------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------

function Get-InstalledSoftware {

    $Software = @()

    try {
        $Software += Get-Package |
        Select-Object Name, Version
    }
    catch {}

    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($Path in $Paths) {

        $Software += Get-ItemProperty $Path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object @{
            Name = 'Name'
            Expression = { $_.DisplayName }
        },
        @{
            Name = 'Version'
            Expression = { $_.DisplayVersion }
        }
    }

    return $Software
}

function Test-AppInstalled {

    param(
        [string]$AppName,
        [array]$InstalledApps
    )

    return [bool](
        $InstalledApps |
        Where-Object {
            $_.Name -like "*$AppName*"
        }
    )
}

function Get-SelectedApps {

    param($Form)

    $Form.Controls |
    Where-Object {
        $_ -is [System.Windows.Forms.CheckBox] -and
        $_.Checked
    } |
    ForEach-Object {
        $_.Tag
    }
}

function Get-UninstallCommand {

    param(
        [string]$AppName
    )

    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($Path in $Paths)
    {
        $App = Get-ItemProperty $Path -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -like "*$AppName*"
        } |
        Select-Object -First 1

        if ($App)
        {
            return $App.UninstallString
        }
    }

    return $null
}

function Uninstall-App {

    param(
        $App,
        $LogBox
    )

    try
    {
        $UninstallString = Get-UninstallCommand $App.DetectionName

        if (!$UninstallString)
        {
            $LogBox.AppendText(
                "$(Get-Date -Format 'HH:mm:ss') No uninstall entry found for $($App.Name)`r`n"
            )

            return
        }

        $LogBox.AppendText(
            "$(Get-Date -Format 'HH:mm:ss') Removing $($App.Name)`r`n"
        )

        #
        # MSI
        #
        if ($UninstallString -match "MsiExec")
        {
            $Arguments = $UninstallString `
                -replace "MsiExec.exe","" `
                -replace "MsiExec",""

            $Arguments = "$Arguments /qn /norestart"

            Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $Arguments `
                -Wait
        }
        else
        {
            $Exe = $UninstallString.Trim('"')

            Start-Process `
                -FilePath $Exe `
                -ArgumentList "/S" `
                -Wait
        }

        #
        # Cleanup folders
        #
        if ($App.CleanupFolders)
        {
            foreach($Folder in $App.CleanupFolders)
            {
                if(Test-Path $Folder)
                {
                    Remove-Item `
                        $Folder `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }
        }

        #
        # Cleanup Registry
        #
        if ($App.CleanupRegistry)
        {
            foreach($RegKey in $App.CleanupRegistry)
            {
                if(Test-Path $RegKey)
                {
                    Remove-Item `
                        $RegKey `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }
        }

        $LogBox.AppendText(
            "$(Get-Date -Format 'HH:mm:ss') SUCCESS REMOVE $($App.Name)`r`n"
        )
    }
    catch
    {
        $LogBox.AppendText(
            "$(Get-Date -Format 'HH:mm:ss') FAILED REMOVE $($App.Name)`r`n"
        )

        $LogBox.AppendText(
            "$($_.Exception.Message)`r`n"
        )
    }
}

#Status update
function Refresh-AppStatuses {

    param(
        $AppsConfig,
        $AppStatusLabels
    )

    $InstalledApps = Get-InstalledSoftware

    foreach ($App in $AppsConfig)
    {
        $Installed = Test-AppInstalled `
            -AppName $App.DetectionName `
            -InstalledApps $InstalledApps

        if ($Installed)
        {
            $AppStatusLabels[$App.Name].Text = "INSTALLED"
            $AppStatusLabels[$App.Name].ForeColor =
                [System.Drawing.Color]::Green
        }
        else
        {
            $AppStatusLabels[$App.Name].Text = "NOT INSTALLED"
            $AppStatusLabels[$App.Name].ForeColor =
                [System.Drawing.Color]::Red
        }
    }
}

# -----------------------------------------------------
# INSTALLED APPS CACHE
# -----------------------------------------------------

Write-Host "Loading installed applications..."

$InstalledApps = Get-InstalledSoftware

# -----------------------------------------------------
# GUI
# -----------------------------------------------------

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Application Installer"
$Form.Size = New-Object System.Drawing.Size(700,700)
$Form.StartPosition = "CenterScreen"

# Install button

$InstallButton = New-Object System.Windows.Forms.Button
$InstallButton.Text = "Install Selected"
$InstallButton.Location = New-Object System.Drawing.Point(20,520)
$InstallButton.Size = New-Object System.Drawing.Size(150,35)

$Form.Controls.Add($InstallButton)

# Uninstall button

$UninstallButton = New-Object System.Windows.Forms.Button
$UninstallButton.Text = "Uninstall Selected"
$UninstallButton.Location = New-Object System.Drawing.Point(190,520)
$UninstallButton.Size = New-Object System.Drawing.Size(150,35)

$Form.Controls.Add($UninstallButton)

# Progress Bar

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(20,560)
$ProgressBar.Size = New-Object System.Drawing.Size(640,25)
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 100
$ProgressBar.Value = 0

$Form.Controls.Add($ProgressBar)

# Status Label

$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Location = New-Object System.Drawing.Point(20,590)
$StatusLabel.Size = New-Object System.Drawing.Size(640,25)
$StatusLabel.Text = "Ready"

$Form.Controls.Add($StatusLabel)

# Log window

$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location = New-Object System.Drawing.Point(20,350)
$LogBox.Size = New-Object System.Drawing.Size(640,150)
$LogBox.ReadOnly = $true

$Form.Controls.Add($LogBox)

# -----------------------------------------------------
# CHECKBOXES
# -----------------------------------------------------

$AppStatusLabels = @{}

$Top = 20

foreach ($App in $AppsConfig)
{
    Write-Host "Checking $($App.Name)"

    $Checkbox = New-Object System.Windows.Forms.CheckBox

    $Checkbox.Text = $App.Name
    $Checkbox.Tag = $App

    $Checkbox.Location = New-Object System.Drawing.Point(20,$Top)
    $Checkbox.Size = New-Object System.Drawing.Size(240,25)

    $Installed = Test-AppInstalled `
        -AppName $App.DetectionName `
        -InstalledApps $InstalledApps

    $Form.Controls.Add($Checkbox)

    $StatusLabelApp = New-Object System.Windows.Forms.Label

    $StatusLabelApp.Location =
        New-Object System.Drawing.Point(280,$Top)

    $StatusLabelApp.AutoSize = $true

    if ($Installed)
    {
        $StatusLabelApp.Text = "INSTALLED"
        $StatusLabelApp.ForeColor = [System.Drawing.Color]::Green
    }
    else
    {
        $StatusLabelApp.Text = "NOT INSTALLED"
        $StatusLabelApp.ForeColor = [System.Drawing.Color]::Red
    }

    $Form.Controls.Add($StatusLabelApp)

    $AppStatusLabels[$App.Name] = $StatusLabelApp
        $Top += 30
    }

# -----------------------------------------------------
# INSTALL BUTTON EVENT
# -----------------------------------------------------

$InstallButton.Add_Click({

    $SelectedApps = @(Get-SelectedApps $Form)

    if (!$SelectedApps)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select at least one application.",
            "No Selection"
        )

        return
    }

    $totalApps = $SelectedApps.Count
    $currentApp = 0

    foreach ($App in $SelectedApps)
    {
        $currentApp++

        $StatusLabel.Text = "Installing $($App.Name)..."

        [System.Windows.Forms.Application]::DoEvents()
        
        $InstallerPath = Join-Path $PSScriptRoot $App.Installer


        if (!(Test-Path $InstallerPath))
        {
            $LogBox.AppendText(
                "$(Get-Date) ERROR - File not found: $InstallerPath`r`n"
            )

            continue
        }

        try
        {
            Start-Process `
                -FilePath $InstallerPath `
                -ArgumentList $App.Arguments `
                -Wait `
                -ErrorAction Stop

            $LogBox.AppendText(
                "$(Get-Date -Format 'HH:mm:ss') SUCCESS - $($App.Name)`r`n"
            )
        }
        catch
        {
            $LogBox.AppendText(
                "$(Get-Date -Format 'HH:mm:ss') FAILED - $($App.Name)`r`n"
            )

            $LogBox.AppendText(
                "$($_.Exception.Message)`r`n"
            )

            Write-Host $_.Exception.Message -ForegroundColor Red
        }


        $percent = [math]::Round(
            ($currentApp / $totalApps) * 100
        )

        $ProgressBar.Value = $percent

        $StatusLabel.Text =
            "$($App.Name) completed ($percent%)"

        [System.Windows.Forms.Application]::DoEvents()
    }

    $ProgressBar.Value = 100

    $StatusLabel.Text = "Installation completed"

    [System.Windows.Forms.MessageBox]::Show(
        "All selected applications have been processed.",
        "Completed",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    Refresh-AppStatuses `
        -AppsConfig $AppsConfig `
        -AppStatusLabels $AppStatusLabels

    $Form.Controls |
    Where-Object {
        $_ -is [System.Windows.Forms.CheckBox]
    } |
    ForEach-Object {
        $_.Checked = $false
    }

})

# -----------------------------------------------------
# UNINSTALL BUTTON EVENT
# -----------------------------------------------------

$UninstallButton.Add_Click({

    $SelectedApps = @(Get-SelectedApps $Form)

    if($SelectedApps.Count -eq 0)
    {
        [System.Windows.Forms.MessageBox]::Show(
            "Select at least one application."
        )

        return
    }

    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Uninstall selected applications ?",
        "Confirmation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if($Result -ne "Yes")
    {
        return
    }

    $TotalApps = $SelectedApps.Count
    $CurrentApp = 0

    foreach($App in $SelectedApps)
    {
        $CurrentApp++

        $StatusLabel.Text =
            "Removing $($App.Name)..."

        [System.Windows.Forms.Application]::DoEvents()

        Uninstall-App `
            -App $App `
            -LogBox $LogBox

        $Percent = [math]::Round(
            ($CurrentApp / $TotalApps) * 100
        )

        $ProgressBar.Value = $Percent
    }

    $StatusLabel.Text =
        "Uninstall completed"

    [System.Windows.Forms.MessageBox]::Show(
        "All selected applications have been processed.",
        "Completed",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    Refresh-AppStatuses `
        -AppsConfig $AppsConfig `
        -AppStatusLabels $AppStatusLabels

    $Form.Controls |
    Where-Object {
        $_ -is [System.Windows.Forms.CheckBox]
    } |
    ForEach-Object {
        $_.Checked = $false
    }

})

# -----------------------------------------------------
# SHOW FORM
# -----------------------------------------------------

[void]$Form.ShowDialog()

# END