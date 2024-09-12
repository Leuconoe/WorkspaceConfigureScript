###############################################################
####################### font & app list #######################
###############################################################
# some nerdfonts from https://www.nerdfonts.com/font-downloads
$FontPath = $FontPath -or @(
"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Ubuntu.zip",
"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip",
"https://github.com/Leuconoe/d2codingfont-nerd-fonts/releases/download/D2Coding-Ver1.3.2-20180524-Nerd-Fonts-v3.0.2-168/D2Coding-Ver1.3.2-20180524-Nerd-Fonts-v3.0.2-168.zip"
)

$WingetPackages = $WingetPackages -or @(
"chocolatey",
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
"Starship.Starship", 
"JanDeDobbeleer.OhMyPosh",
)

$ChocoPackages = $ChocoPackages - or @(
    "androidstudio",
	"qdir",
)

$PSModules = $PSModules -or @(
    "Terminal-Icons",  #Terminal-Icons is a PowerShell module that adds file and folder icons when displaying items in the terminal. ( https://github.com/devblackops/Terminal-Icons )
    "PSReadLine",      # PSReadLine is replaces the command line editing experience of PowerShell for versions 3 and up( https://github.com/PowerShell/PSReadLine )
    "PSFzf"            # PSFzf is a PowerShell module that wraps fzf, a fuzzy file finder for the command line. ( https://github.com/kelleyma49/PSFzf )
)

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
function Add-MultiLineTextIfMissing {
    param (
        [string]$FilePath,
        [string[]]$TextsValues
    )

    # Read the content of the file
    $content = Get-Content -Path $FilePath -Raw

    foreach ($text in $TextsValues) {
        # Convert multi-line text into a single string with line breaks preserved
        $formattedText = $text -join "`n"
        
        # Check if the multi-line text is present in the content
        if ($content -notmatch [regex]::Escape($formattedText)) {
            # Append the multi-line text to the content
            $content += "`n$formattedText"
            Write-Output "Added multi-line text."
        } else {
            Write-Output "Multi-line text already present."
        }
    }

    # Save the updated content back to the file
    Set-Content -Path $FilePath -Value $content
}

#######################################################
####################### install start #################
#######################################################
# Check if running with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If not running as administrator, re-launch PowerShell with elevated privileges
    $newProcess = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
# Your script code continues here
Write-Host "Running with administrator privileges."

Write-Host "Installing winget fonts..."
foreach ($font in $FontPath) {
	Install-FontsFromURL -downloadUrl $font
}
Write-Host "Installing winget packages..."
## Throwing a short exception because winget sometimes doesn't update its hash

winget settings --enable InstallerHashOverride
foreach ($package in $WingetPackages) {
    winget install --id=$package --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --ignore-security-hash --force
}
winget settings --disable InstallerHashOverride

Write-Host "Installing choco packages..."
foreach ($package in $ChocoPackages) {
    choco install $package -y
}

Write-Host "Installing module..."
foreach ($module in $PSModules) {
    Install-Module -Name $module -Force -AllowClobber -Repository PSGallery
}

################################################################################
####################### open $profile or modify $profile #######################
################################################################################
$profileValues = @(
    @("#Terminal-Icons", "Import-Module -Name Terminal-Icons"),
    @("#fzf", "Import-Module -Name PSFzf"),
	#@("#oh-my-posh", "oh-my-posh init pwsh --config ~/quick-term.omp.json | Invoke-Expression"),
	@("#starship", "Invoke-Expression (&starship init powershell)"),
)

Add-MultiLineTextIfMissing -FilePath $PROFILE -TextsValues $profileValues

#if using starship, add config
mkdir -p ~/.config || New-Item ~/.config/starship.toml || cd ~/.config/
starship preset gruvbox-rainbow -o starship.toml
