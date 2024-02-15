# Install Windows Terminal from PowerShell

Install [Windows Terminal](https://github.com/microsoft/terminal) entirely from PowerShell.

## Script Functionality
1. Installs [winget](https://github.com/microsoft/winget-cli) using [winget-install](https://github.com/asheroto/winget-install)
2. Installs [Windows Terminal](https://github.com/microsoft/terminal)
3. Downloads & installs the Cascadia Mono font from [Cascadia Code](https://github.com/microsoft/cascadia-code)

## Setup

### Method 1 - PowerShell Gallery

> [!TIP]
>If you want to trust PSGallery so you aren't prompted each time you run this command, or if you're scripting this and want to ensure the script isn't interrupted the first time it runs...
>```powershell
>Install-PackageProvider -Name "NuGet" -Force
>Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
>```

**This is the recommended method, because it always gets the public release that has been tested, it's easy to remember, and supports all parameters.**

Open PowerShell as Administrator and type

```powershell
Install-Script Install-WindowsTerminal -Force
```

Follow the prompts to complete the installation (you can tap `A` to accept all prompts or `Y` to select them individually.

**Note:** `-Force` is optional but recommended, as it will force the script to update if it is outdated. If you do not use `-Force`, it will _not_ overwrite the script if outdated.

#### Usage

```powershell
Install-WindowsTerminal
```

If Windows Terminal is already installed, you can use the `-Force` parameter to force the script to run anyway.

The script is published on [PowerShell Gallery](https://www.powershellgallery.com/packages/Install-WindowsTerminal) under `Install-WindowsTerminal`.

### Method 2 - One Line Command (Runs Immediately)

The URL [asheroto.com/terminal](https://asheroto.com/terminal) always redirects to the [latest code-signed release](https://github.com/asheroto/Install-WindowsTerminal/releases/latest/download/Install-WindowsTerminal.ps1) of the script.

If you just need to run the basic script without any parameters, you can use the following one-line command:

#### Option A:

```powershell
irm asheroto.com/terminal | iex
```

Due to the nature of how PowerShell works, you won't be able to use any parameters like `-Force` with this command line. Use this instead:

```powershell
&([ScriptBlock]::Create((irm asheroto.com/terminal))) -Force
```

#### Option B:

Alternatively, you can of course use the latest code-signed release URL directly:

```powershell
irm https://github.com/asheroto/Install-WindowsTerminal/releases/latest/download/Install-WindowsTerminal.ps1 | iex
```

### Method 3 - Download Locally and Run

As a more conventional approach, download the latest [Install-WindowsTerminal.ps1](https://github.com/asheroto/Install-WindowsTerminal/releases/latest/download/Install-WindowsTerminal.ps1) from [Releases](https://github.com/asheroto/Install-WindowsTerminal/releases), then run the script as follows:

```powershell
.\Install-WindowsTerminal.ps1
```

> [!TIP]
> If for some reason your PowerShell window closes at the end of the script and you don't want it to, or don't want your other scripts to be interrupted, you can wrap the command in a `powershell "COMMAND HERE"`. For example, `powershell "irm asheroto.com/terminal | iex"`.

## Parameters

**No parameters are required** to run the script, but there are some optional parameters to use if needed.

| Parameter         | Description                                                                                                                                                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-Force`          | Ensures installation of Windows Terminal and its dependencies, even if already present.                                                                                                                                                                          |
| `-CheckForUpdate` | Checks if there is an update available for the script.                                                                                                                                                                                                 |
| `-UpdateSelf`     | Updates the script to the latest version.                                                                                                                                                                                                              |
| `-Version`        | Displays the version of the script.                                                                                                                                                                                                                    |
| `-Help`           | Displays the full help information for the script.                                                                                                                                                                                                     |

### Example Parameters Usage

```powershell
Install-WindowsTerminal -Force
```