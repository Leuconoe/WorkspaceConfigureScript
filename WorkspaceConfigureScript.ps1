# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Leuconoe/WorkspaceConfigureScript/main/WorkspaceConfigureScript.ps1'))



###############################################################
####################### font & app list #######################
###############################################################
# some nerdfonts from https://www.nerdfonts.com/font-downloads
if (-not $FontPath) {
	$FontPath = @(
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Ubuntu.zip",
		#"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip",
		"https://github.com/Leuconoe/d2codingfont-nerd-fonts/releases/download/D2Coding-Ver1.3.2-20180524-Nerd-Fonts-v3.0.2-168/D2Coding-Ver1.3.2-20180524-Nerd-Fonts-v3.0.2-168.zip"
	)
}
if (-not $WingetPackages) {
	$WingetPackages = @(
		"nerd-fonts-FiraMono",
		"nerd-fonts-CascadiaCode",
		"Bandisoft.Bandizip",
		"Bandisoft.Honeyview",
		"Anaconda.Anaconda3", 
		"CoreyButler.NVMforWindows",
		"Notepad\u002B\u002B.Notepad\u002B\u002B",
		"Google.GoogleDrive",
		"Google.Chrome",
		"Google.ChromeRemoteDesktopHost",
		"Unity.UnityHub",
		"Git.Git",
		"TortoiseGit.TortoiseGit",
		"TortoiseSVN.TortoiseSVN",
		"Microsoft.VisualStudioCode",
		"Microsoft.VisualStudio.2022.Community",
		"Microsoft.PowerShell",
		"Microsoft.WindowsTerminal",
		"tailscale.tailscale",
		"junegunn.fzf",
		"DeepL.DeepL",
		"Starship.Starship", 
		"JanDeDobbeleer.OhMyPosh"
	)
}
if (-not $ChocoPackages) {
	$ChocoPackages = @(
		"androidstudio",
		"qdir"
	)
}
if (-not $PSModules) {
	$PSModules = @(
		"PowerShellGet",   # PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.
		"Terminal-Icons",  # Terminal-Icons is a PowerShell module that adds file and folder icons when displaying items in the terminal. ( https://github.com/devblackops/Terminal-Icons )
		"PSReadLine",      # PSReadLine is replaces the command line editing experience of PowerShell for versions 3 and up( https://github.com/PowerShell/PSReadLine )
		"PSFzf"            # PSFzf is a PowerShell module that wraps fzf, a fuzzy file finder for the command line. ( https://github.com/kelleyma49/PSFzf )
	)
}

Read-Host -Prompt "Press Enter to continue"

#########################################################
####################### FUNCTIONS #######################
#########################################################
# Function to download, extract and install fonts from a given URL
function Install-FontsFromURL {
    param (
        [string]$downloadUrl  # URL to download the zip file
    )

    # Create temp folder for download
    $tempFolder = "$env:TEMP\DownloadFonts"
    $zipFilePath = "$tempFolder\downloadedFile.zip"

    if (-not (Test-Path -Path $tempFolder)) {
        New-Item -Path $tempFolder -ItemType Directory | Out-Null
    }

    try {
        # Download the file
        Write-Host "Downloading file from $downloadUrl..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath

        # Unzip the file to temp folder
        Write-Host "Extracting files..."
        Expand-Archive -Path $zipFilePath -DestinationPath $tempFolder -Force

        # Find and install OTF/TTF fonts
        Write-Host "Installing fonts..."
        Get-ChildItem -Path $tempFolder -Recurse -Include *.otf, *.ttf | ForEach-Object {
            $fontPath = $_.FullName
            $fontName = $_.Name

            # Install the font by copying to the Windows Fonts directory
            Copy-Item -Path $fontPath -Destination "$env:SystemRoot\Fonts" -Force

            # Add font to the registry
            $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            New-ItemProperty -Path $fontRegistryPath -Name $fontName -Value $fontName -PropertyType String -Force
        }

        Write-Host "Fonts installed successfully!"

    } catch {
        Write-Host "An error occurred: $_"
    } finally {
        # Clean up by deleting the temp folder
        if (Test-Path -Path $tempFolder) {
            Write-Host "Cleaning up temporary files..."
            Remove-Item -Path $tempFolder -Recurse -Force
        }
    }
}
function AddPowershellProfile {
    param (
        [string]$FilePath,
        [array]$TextsValues
    )

    # Ensure the profile file exists
    if (-not (Test-Path $FilePath)) {
        New-Item -Path $FilePath -ItemType "file" -Force
    }

    # Read the content of the profile file. Use -ErrorAction to handle empty files gracefully.
    $content = ""
    if ((Get-Item $FilePath).Length -gt 0) {
        $content = Get-Content -Path $FilePath -Raw
    }

    foreach ($textValue in $TextsValues) {
        $comment = $textValue[0]
        $code = $textValue[1]

        # Check if the profile file contains the comment or code
        if ($content -notmatch [regex]::Escape($comment)) {
            # Append the comment and code block to the profile
            "`n$comment`n$code" | Add-Content -Path $FilePath
            Write-Output "Added: $comment and $code"
        } else {
            Write-Output "Already present: $comment"
        }
    }
}
#######################################################
####################### install start #################
#######################################################
# Check if running with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Write-Host "Run as Administrator..."
    # If not running as administrator, re-launch PowerShell with elevated privileges
    #$newProcess = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Running with administrator privileges."

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;

Write-Host "Installing fonts..."
foreach ($font in $FontPath) {
	Install-FontsFromURL -downloadUrl $font
}

Write-Host "Installing chocolatey..."
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Write-Host "update winget from chocolatey..."
choco install winget -y

Write-Host "Installing winget packages..."
winget settings --enable InstallerHashOverride
foreach ($package in $WingetPackages) {
	Write-Host "Installing $package..."
    winget install --id=$package --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force
}
winget settings --disable InstallerHashOverride

Write-Host "Installing choco packages..."
foreach ($package in $ChocoPackages) {
	Write-Host "Installing $package..."
    choco install $package -y
}

Write-Host "Installing module..."
foreach ($module in $PSModules) {
	Write-Host "Installing $module..."
    Install-Module -Name $module -Force -AllowClobber -Repository PSGallery
}

################################################################################
####################### open $profile or modify $profile #######################
################################################################################
$PowershellProfileValues = @(
    @("#Terminal-Icons", "Import-Module -Name Terminal-Icons"),
    @("#fzf", "Import-Module -Name PSFzf"),
	@("#PSReadLine", "Set-PSReadLineOption -PredictionSource History`nSet-PSReadLineOption -PredictionViewStyle ListView"),
    @("#oh-my-posh", "#oh-my-posh init pwsh --config ~/quick-term.omp.json | Invoke-Expression"),
    @("#starship", "Invoke-Expression (&starship init powershell)")
)

AddPowershellProfile -FilePath $PROFILE -TextsValues $PowershellProfileValues

#if using starship, add config
mkdir -p ~/.config;New-Item ~/.config/starship.toml;cd ~/.config/
starship preset gruvbox-rainbow -o starship.toml


Read-Host -Prompt "Press Enter to continue"