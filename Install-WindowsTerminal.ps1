<#PSScriptInfo

.VERSION 0.0.2

.GUID 98cb59b3-0489-4609-9c31-4f85be9433ea

.AUTHOR asheroto

.COMPANYNAME asheroto

.TAGS PowerShell Windows Terminal install installer script

.PROJECTURI https://github.com/asheroto/Install-WindowsTerminal

.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Adjust UpdateSelf function to reset PSGallery to original state if it was not trusted.

#>

<#
.SYNOPSIS
	Installs winget and Windows Terminal.
.DESCRIPTION
	Installs winget and Windows Terminal.
.EXAMPLE
	Install-WindowsTerminal
.PARAMETER Force
    Ensures installation of winget and its dependencies, even if already present.
.PARAMETER UpdateSelf
    Updates the script to the latest version on PSGallery.
.PARAMETER CheckForUpdate
    Checks if there is an update available for the script.
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the full help information for the script.
.NOTES
	Version      : 0.0.2
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/Install-WindowsTerminal
#>
[CmdletBinding()]
param (
    [switch]$Version,
    [switch]$Help,
    [switch]$CheckForUpdate,
    [switch]$UpdateSelf,
    [switch]$Force
)

# Version
$CurrentVersion = '0.0.2'
$RepoOwner = 'asheroto'
$RepoName = 'Install-WindowsTerminal'
$PowerShellGalleryName = 'Install-WindowsTerminal'

# Preferences
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)
$ConfirmPreference = 'None' # Suppress confirmation prompts

# Display version if -Version is specified
if ($Version.IsPresent) {
    $CurrentVersion
    exit 0
}

# Display full help if -Help is specified
if ($Help) {
    Get-Help -Name $MyInvocation.MyCommand.Source -Full
    exit 0
}

# Display $PSVersionTable and Get-Host if -Verbose is specified
if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose']) {
    $PSVersionTable
    Get-Host
}

# Set debug preferences if -Debug is specified
if ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
    $ConfirmPreference = 'None'
}

function CheckForUpdate {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [version]$CurrentVersion,
        [string]$PowerShellGalleryName
    )

    $Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

    Write-Output ""
    Write-Output ("Repository:       {0,-40}" -f "https://github.com/$RepoOwner/$RepoName")
    Write-Output ("Current Version:  {0,-40}" -f $CurrentVersion)
    Write-Output ("Latest Version:   {0,-40}" -f $Data.LatestVersion)
    Write-Output ("Published at:     {0,-40}" -f $Data.PublishedDateTime)

    if ($Data.LatestVersion -gt $CurrentVersion) {
        Write-Output ("Status:           {0,-40}" -f "A new version is available.")
        Write-Output "`nOptions to update:"
        Write-Output "- Download latest release: https://github.com/$RepoOwner/$RepoName/releases"
        if ($PowerShellGalleryName) {
            Write-Output "- Run: $RepoName -UpdateSelf"
            Write-Output "- Run: Install-Script $PowerShellGalleryName -Force"
        }
    } else {
        Write-Output ("Status:           {0,-40}" -f "Up to date.")
    }
    exit 0
}

function Write-Section($text) {
    <#
        .SYNOPSIS
        Prints a text block surrounded by a section divider for enhanced output readability.

        .DESCRIPTION
        This function takes a string input and prints it to the console, surrounded by a section divider made of hash characters.
        It is designed to enhance the readability of console output.

        .PARAMETER text
        The text to be printed within the section divider.

        .EXAMPLE
        Write-Section "Downloading Files..."
        This command prints the text "Downloading Files..." surrounded by a section divider.
    #>
    Write-Output ""
    Write-Output ("#" * ($text.Length + 4))
    Write-Output "# $text #"
    Write-Output ("#" * ($text.Length + 4))
    Write-Output ""
}

function Strip-ProgressIndent {
    param(
        [ScriptBlock]$ScriptBlock,
        [int]$Indentation = 4
    )

    # Function identical to Strip-Progress function by asheroto, but with an additional parameter to specify the indentation level
    # https://gist.github.com/asheroto/96bcabe428e8ad134ef204573810041f

    # Regex pattern to match spinner characters and progress bar patterns, now accounting for one or more spaces
    $progressPattern = 'Γû[Æê]\s*|^\s*[-\\|/]\s*$'

    # Adjusted regex pattern for size formatting to ensure it can handle variable spacing around the "/"
    $sizePattern = '(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB)\s*/\s*(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB)'

    $previousLineWasEmpty = $false # Track if the previous line was empty

    & $ScriptBlock 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            "ERROR: $($_.Exception.Message)"
        } elseif ($_ -match '^\s*$') {
            if (-not $previousLineWasEmpty) {
                Write-Output ""
                $previousLineWasEmpty = $true
            }
        } else {
            $line = $_ -replace $progressPattern, '' -replace $sizePattern, '$1 $3 / $4 $6'
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $previousLineWasEmpty = $false
                (' ' * $Indentation) + $line
            }
        }
    }
}

function Get-CascadiaMonoUrl {
    <#
        .SYNOPSIS
        Retrieves the download URL for the latest release of the Cascadia Mono font.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of the Cascadia Mono font, including its version and the date it was published. It then returns the download URL for the latest release.

        .PARAMETER Match
        The pattern to match in the asset names.

        .EXAMPLE
        Get-CascadiaMonoUrl
    #>

    $uri = "https://api.github.com/repos/microsoft/cascadia-code/releases"
    $releases = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop

    foreach ($release in $releases) {
        if ($release.name -match "preview") {
            continue
        }
        $data = $release.assets | Where-Object name -Like "CascadiaCode*.zip"
        if ($data) {
            return $data.browser_download_url
        }
    }

    Write-Debug "Falling back to the latest release..."
    $latestRelease = $releases | Select-Object -First 1
    $data = $latestRelease.assets | Where-Object name -Match ".zip"
    return
}

function Get-GitHubRelease {
    <#
        .SYNOPSIS
        Fetches the latest release information of a GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of a specified repository, including its version and the date it was published.

        .PARAMETER Owner
        The GitHub username of the repository owner.

        .PARAMETER Repo
        The name of the repository.

        .EXAMPLE
        Get-GitHubRelease -Owner "asheroto" -Repo "winget-install"
        This command retrieves the latest release version and published datetime of the winget-install repository owned by asheroto.
    #>
    [CmdletBinding()]
    param (
        [string]$Owner,
        [string]$Repo
    )
    try {
        $url = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $response = Invoke-RestMethod -Uri $url -ErrorAction Stop

        $latestVersion = $response.tag_name
        $publishedAt = $response.published_at

        # Convert UTC time string to local time
        $UtcDateTime = [DateTime]::Parse($publishedAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $PublishedLocalDateTime = $UtcDateTime.ToLocalTime()

        [PSCustomObject]@{
            LatestVersion     = $latestVersion
            PublishedDateTime = $PublishedLocalDateTime
        }
    } catch {
        Write-Error "Unable to check for updates.`nError: $_"
        exit 1
    }
}

function CheckForUpdate {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [version]$CurrentVersion,
        [string]$PowerShellGalleryName
    )

    $Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

    Write-Output ""
    Write-Output ("Repository:       {0,-40}" -f "https://github.com/$RepoOwner/$RepoName")
    Write-Output ("Current Version:  {0,-40}" -f $CurrentVersion)
    Write-Output ("Latest Version:   {0,-40}" -f $Data.LatestVersion)
    Write-Output ("Published at:     {0,-40}" -f $Data.PublishedDateTime)

    if ($Data.LatestVersion -gt $CurrentVersion) {
        Write-Output ("Status:           {0,-40}" -f "A new version is available.")
        Write-Output "`nOptions to update:"
        Write-Output "- Download latest release: https://github.com/$RepoOwner/$RepoName/releases"
        if ($PowerShellGalleryName) {
            Write-Output "- Run: $RepoName -UpdateSelf"
            Write-Output "- Run: Install-Script $PowerShellGalleryName -Force"
        }
    } else {
        Write-Output ("Status:           {0,-40}" -f "Up to date.")
    }
    exit 0
}

function UpdateSelf {
    try {
        # Get PSGallery version of script
        $psGalleryScriptVersion = (Find-Script -Name $PowerShellGalleryName).Version

        # If the current version is less than the PSGallery version, update the script
        if ($CurrentVersion -lt $psGalleryScriptVersion) {
            Write-Output "Updating script to version $psGalleryScriptVersion..."

            # Install NuGet PackageProvider if not already installed
            Install-PackageProvider -Name "NuGet" -Force

            # Trust the PSGallery if not already trusted
            $psRepoInstallationPolicy = (Get-PSRepository -Name 'PSGallery').InstallationPolicy
            if ($psRepoInstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted | Out-Null
            }

            # Update the script
            Install-Script $PowerShellGalleryName -Force

            # If PSGallery was not trusted, reset it to its original state
            if ($psRepoInstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy $psRepoInstallationPolicy | Out-Null
            }

            Write-Output "Script updated to version $psGalleryScriptVersion."
            exit 0
        } else {
            Write-Output "Script is already up to date."
            exit 0
        }
    } catch {
        Write-Output "An error occurred: $_"
        exit 1
    }
}

function Write-Section($text) {
    <#
        .SYNOPSIS
        Prints a text block surrounded by a section divider for enhanced output readability.

        .DESCRIPTION
        This function takes a string input and prints it to the console, surrounded by a section divider made of hash characters.
        It is designed to enhance the readability of console output.

        .PARAMETER text
        The text to be printed within the section divider.

        .EXAMPLE
        Write-Section "Downloading Files..."
        This command prints the text "Downloading Files..." surrounded by a section divider.
    #>
    Write-Output ""
    Write-Output ("#" * 80)
    Write-Output "# $text #"
    Write-Output ("#" * 80)
    Write-Output ""
}

function Get-WingetStatus {
    <#
        .SYNOPSIS
        Checks if winget is installed.

        .DESCRIPTION
        This function checks if winget is installed.

        .EXAMPLE
        Get-WingetStatus
    #>

    # Check if winget is installed
    $winget = Get-Command -Name winget -ErrorAction SilentlyContinue

    # If winget is installed, return $true
    if ($null -ne $winget) {
        return $true
    }

    # If winget is not installed, return $false
    return $false
}

function Get-WindowsTerminalStatus {
    <#
        .SYNOPSIS
        Checks if Windows Terminal is installed.

        .DESCRIPTION
        This function checks if Windows Terminal is installed.

        .EXAMPLE
        Get-WindowsTerminalStatus
    #>

    # Check if Windows Terminal is installed
    $windowsTerminal = Get-Command -Name wt -ErrorAction SilentlyContinue

    # If Windows Terminal is installed, return $true
    if ($null -ne $windowsTerminal) {
        return $true
    }

    # If Windows Terminal is not installed, return $false
    return $false
}

function Get-CascadiaMonoStatus {
    $systemFontDir = [System.IO.Path]::Combine($ENV:SystemRoot, "Fonts")
    $userFontDir = [System.IO.Path]::Combine($ENV:USERPROFILE, "AppData", "Local", "Microsoft", "Windows", "Fonts")
    $fontFileName = "CascadiaMono.ttf"

    $systemFontPath = [System.IO.Path]::Combine($systemFontDir, $fontFileName)
    $userFontPath = [System.IO.Path]::Combine($userFontDir, $fontFileName)

    return (Test-Path -Path $systemFontPath) -or (Test-Path -Path $userFontPath)
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Checks if the script is running with Administrator privileges. Returns $true if running with Administrator privileges, $false otherwise.

    .DESCRIPTION
        This function checks if the current PowerShell session is running with Administrator privileges by examining the role of the current user. It returns $true if the current user is an Administrator, $false otherwise.

    .EXAMPLE
        Test-AdminPrivileges

    .NOTES
        This function is particularly useful for scripts that require elevated permissions to run correctly.
    #>
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $true
    }
    return $false
}

function New-TemporaryDirectory {
    <#
    .SYNOPSIS
    Creates a new temporary directory.

    .DESCRIPTION
    This function generates a new directory with a unique name in the system's temporary path.
    #>

    # Get the system's temporary path
    $parent = [System.IO.Path]::GetTempPath()

    # Confirm the parent directory exists
    if (-not (Test-Path -Path $parent)) {
        Write-Error "Parent directory does not exist: $parent"
        return
    }

    # Create a new directory with a unique name
    $name = [System.Guid]::NewGuid().ToString()
    $newTempDir = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine($parent, $name))

    # Return the path to the new directory
    return $newTempDir.FullName
}

Function Install-Font {
    <#
    .SYNOPSIS
    Installs fonts from a specified path on Windows systems.

    .DESCRIPTION
    The Install-Font function supports handling individual font files, directories containing multiple fonts, and wildcard paths. It also supports recursive search for font files in the specified path and all its subdirectories. The function is capable of installing both TTF and OTF font types.

    .PARAMETER Path
    Specifies the path to the font file(s). This can be a path to an individual font file, a directory containing font files, or a wildcard path. The function accepts both relative and absolute paths.

    .PARAMETER Recursive
    When specified, the function will recursively search for font files in the specified path and all its subdirectories. This is useful for bulk installations from directories with nested subfolders.

    .EXAMPLE
    Install-Font -Path ".\MyFont.ttf"
    This example installs a single font file named 'MyFont.ttf' located in the current directory.

    .EXAMPLE
    Install-Font -Path ".\MyFont.otf"
    This example installs a single font file named 'MyFont.otf' located in the current directory.

    .EXAMPLE
    Install-Font -Path "C:\Users\User\Downloads\*.ttf"
    This example installs all TTF fonts located in the 'Downloads' folder of the 'User' directory.

    .EXAMPLE
    Install-Font -Path "*.ttf" -Recursive
    This example installs all TTF fonts found in the current directory and its subdirectories.
    #>
    param (
        [string]$Path,
        [switch]$Recursive
    )
    # Get the path to the Fonts folder
    $SystemFontsPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Fonts)

    # Find all font files based on the given path
    $fontFiles = Get-ChildItem -Path $Path -Recurse:$Recursive -File | Where-Object { $_.Extension -eq '.ttf' -or $_.Extension -eq '.otf' }

    foreach ($file in $fontFiles) {
        Write-Output "Installing $($file.Name)"

        # Construct the path to the font file in the Fonts folder
        $FontDestination = Join-Path -Path $SystemFontsPath -ChildPath $file.Name

        # Get font name from font file
        $ShellFolder = (New-Object -COMObject Shell.Application).Namespace($file.DirectoryName)
        $ShellFile = $ShellFolder.ParseName($file.Name)
        $FontType = $ShellFolder.GetDetailsOf($ShellFile, 2)
        $FontName = $ShellFolder.GetDetailsOf($ShellFile, 21)

        # Check if the file is a font file
        If (-not ($FontType -Like '*font*')) {
            Write-Output "  $($file.Name) is not a recognized font file"
            Continue
        }

        # If the font file doesn't exist in the Fonts folder
        if (-not (Test-Path -Path $FontDestination)) {
            # Copy the font file to the Fonts folder
            Copy-Item -Path $file.FullName -Destination $FontDestination

            # Register the font in the registry for persistence
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            if ($null -ne $FontName) {
                $null = Set-ItemProperty -Path $registryPath -Name "$FontName (TrueType)" -Value $file.Name
            }
            Write-Output "  Installed `"$FontName``"
        } else {
            Write-Output "  `"$FontName`" is already installed"
        }
    }
}

# ============================================================================ #
# Initial checks
# ============================================================================ #

# First heading
Write-Output "Install-WindowsTerminal $CurrentVersion"

# Check for updates if -CheckForUpdate is specified
if ($CheckForUpdate) { CheckForUpdate -RepoOwner $RepoOwner -RepoName $RepoName -CurrentVersion $CurrentVersion -PowerShellGalleryName $PowerShellGalleryName }

# Update the script if -UpdateSelf is specified
if ($UpdateSelf) { UpdateSelf }

# Heading
Write-Output "To check for updates, run Install-WindowsTerminal -CheckForUpdate"

# ============================================================================ #
# Confirm running as administrator
# ============================================================================ #

if (!(Test-AdminPrivileges)) {
    Write-Output "Please run this script as an administrator."
    exit 1
}

# ============================================================================ #
# Install winget
# ============================================================================ #

# Heading
Write-Section "Prerequisites"

# Install winget if not already installed
if ((-not (Get-WingetStatus)) -or $Force) {
    Write-Output "Installing winget..."

    # Indent the process
    Strip-ProgressIndent -ScriptBlock {
        # Install NuGet PackageProvider
        Install-PackageProvider -Name NuGet -Force -Confirm:$false | Out-Null

        # Trust the PSGallery if not already trusted
        $psRepoInstallationPolicy = (Get-PSRepository -Name 'PSGallery').InstallationPolicy
        if ($psRepoInstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted | Out-Null
        }

        # Install winget
        Install-Script -Name winget-install -Force
        winget-install -Force

        # If PSGallery was not trusted, reset it to its original state
        if ($psRepoInstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy $psRepoInstallationPolicy | Out-Null
        }
    }

    # Confirm winget is installed
    if (Get-WingetStatus) {
        Write-Output "winget is installed."
    } else {
        Write-Warning "There was an issue installing winget which Windows Terminal depends on. Please try again."
        exit 1
    }
} else {
    Write-Output "winget is already installed."
}

# ============================================================================ #
# Install Windows Terminal
# ============================================================================ #

# Heading
Write-Section "Windows Terminal"

# Install Windows Terminal if not already installed
if ((-not (Get-WindowsTerminalStatus)) -or $Force) {
    # Install Windows Terminal
    Write-Output "Installing Windows Terminal..."

    # Indent the process
    Strip-ProgressIndent -ScriptBlock {
        winget install Microsoft.WindowsTerminal --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity
    }

    # Confirm Windows Terminal is installed
    if (Get-WindowsTerminalStatus) {
        Write-Output "Windows Terminal is installed."
    } else {
        # Install Windows Terminal using winget from the Microsoft Store
        Write-Warning "Windows Terminal was not installed. Trying another method..."

        # Indent the process
        Strip-ProgressIndent -ScriptBlock {
            winget install "windows terminal" --source "msstore" --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity
        }

        if (Get-WindowsTerminalStatus) {
            Write-Output "Windows Terminal is installed."
        } else {
            Write-Warning "There was an issue installing Windows Terminal. Please refer to any error messages above for more information."
            exit 1
        }
    }
} else {
    Write-Output "Windows Terminal is already installed."
}

# ============================================================================ #
# Install Cascadia Mono font
# ============================================================================ #

# Heading
Write-Section "Cascadia Mono font"

# Confirm that the Cascadia Mono font is not already installed system or user
if ((-not (Get-CascadiaMonoStatus)) -or $Force) {
    Write-Output "Installing Cascadia Mono (includes Cascadia Code)..."

    # Indent the process
    Strip-ProgressIndent -ScriptBlock {

        # Define vars
        $ProgressPreference = 'SilentlyContinue'
        $url = Get-CascadiaMonoUrl

        # Create a new folder for the download
        $downloadFolder = New-TemporaryDirectory

        # Download the zip file
        $zipFile = [System.IO.Path]::Combine($downloadFolder, "CascadiaCode.zip")
        Invoke-WebRequest -Uri $url -OutFile $zipFile

        # Extract the zip file
        Expand-Archive -Path $zipFile -DestinationPath $downloadFolder

        # Set ttf path
        $ttfPath = [System.IO.Path]::Combine($downloadFolder, "ttf")

        # Install the font (not recursive to avoid installing static fonts)
        Install-Font -Path $ttfPath

        # Clean up
        Remove-Item -Path $downloadFolder -Recurse -Force
    }

    # Confirm the font is installed
    if (Get-CascadiaMonoStatus) {
        Write-Output "Cascadia Mono font installed successfully."
    } else {
        Write-Warning "There was an issue installing the Cascadia Mono font. Please refer to any error messages above for more information."
        exit 1
    }
} else {
    Write-Output "Cascadia Mono font is already installed."
}

# ============================================================================ #
# Complete
# ============================================================================ #

# Heading
Write-Section "Complete"
Write-Output "Windows Terminal is now installed and ready to use."