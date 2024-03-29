[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/Install-WindowsTerminal?label=PowerShell%20Gallery%20downloads)](https://www.powershellgallery.com/packages/Install-WindowsTerminal)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/Install-WindowsTerminal/total?label=release%20downloads)](https://github.com/asheroto/Install-WindowsTerminal/releases)
[![Release](https://img.shields.io/github/v/release/asheroto/Install-WindowsTerminal)](https://github.com/asheroto/Install-WindowsTerminal/releases)
[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/Install-WindowsTerminal)](https://github.com/asheroto/Install-WindowsTerminal/releases)

[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto?frequency=one-time&sponsor=asheroto)
<a href="https://ko-fi.com/asheroto"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Ko-Fi Button" height="20px"></a>
<a href="https://www.buymeacoffee.com/asheroto"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=seb6596&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=asheroto&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff)" height="40px"></a>

# Install Windows Terminal from PowerShell

Install [Windows Terminal](https://github.com/microsoft/terminal), dependencies, and required fonts, entirely from PowerShell.

## Script Functionality
1. Installs [winget](https://github.com/microsoft/winget-cli) using [winget-install](https://github.com/asheroto/winget-install)
2. Installs [Windows Terminal](https://github.com/microsoft/terminal)
3. Downloads & installs the Cascadia Mono font from [Cascadia Code](https://github.com/microsoft/cascadia-code)

## Requirements

-   Requires PowerShell running with Administrator rights
-   Compatible with:
    -   Windows 10 (Version 1809 or higher)
    -   Windows 11
    -   Server 2022
    -   Windows Sandbox
-   Not compatible with:
    -   Server 2019 (winget not supported)

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

## Troubleshooting
- I'm seeing a bunch of characters like `ΓûêΓûêΓûêΓûêΓûê` on step 2.
  - This is a [known issue](https://github.com/microsoft/winget-cli/issues/2582) of `winget` and has to due with the inability to turn off winget output, despite using `--silent` and `--disable-interactivity`.
  - To help avoid this, the [Strip-Progress](https://gist.github.com/asheroto/96bcabe428e8ad134ef204573810041f) function has been implemented, and although it works for step 1, it doesn't work as well as hoped in step 2.

## TODO
- Consider hiding output by default, and having `Verbose` param show output instead.