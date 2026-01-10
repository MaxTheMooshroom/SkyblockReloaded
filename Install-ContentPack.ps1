<#
.SYNOPSIS
  Installs one or more parts of the merged resource pack and datapack ("Content Pack")

.DESCRIPTION
  For each specified install type, installs the corresponding section of the content pack.
  '-Assets' is used for ResourcePacks, and '-Data' for DataPacks.

.PARAMETER SaveName
  Type: String
  Required when installing the datapack, this is the world name to install to. 

.PARAMETER ContentName
  Type: String
  If so desired, the top-level folder name that this installs to can be overridden.

.PARAMETER WorldNew
  Type: Flag
  Instance path becomes the direct install path for the Datapack, because it's being
  installed to a world that's being created.

.PARAMETER InstancePath
  Type: Path
  The minecraft instance's path. Typically this is `%APPDATA%\.minecraft`

.PARAMETER Assets
  Type: Flag
  Install the assets as a ResourcePack.

.PARAMETER Data
  Type: Flag
  Install the data as a DataPack.

.EXAMPLE
  Install-ContentPack -SaveName my-world %APPDATA%\.minecraft -Assets -Data
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="If a datapack is being installed, what world should it be installed to?")]
    [string] $SaveName,

    [Parameter(HelpMessage="If so desired, the top-level folder name that this installs to can be overridden.")]
    [string] $ContentName="Skyblock_Reloaded",

    [Parameter(HelpMessage="Instance path becomes the direct install path for the Datapack. -SaveName is no longer required.")]
    [switch] $WorldNew,

    # ======================================================================================================

    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory,
        Position=0,
        HelpMessage="Specifies the minecraft instance's path."
    )]
    [string] $InstancePath,

    # ======================================================================================================

    [Parameter(HelpMessage="Install the assets as a ResourcePack")]
    [switch] $Assets,

    [Parameter(HelpMessage="Install the data as a DataPack.")]
    [switch] $Data
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"]

$InstancePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    [Environment]::ExpandEnvironmentVariables($InstancePath)
)

function Write-Info {
    param([Parameter(Mandatory, Position=0)] [string] $msg)

    if ($Verbose) {
        Write-Host "[INFO]: ${msg}"
    }
}

function Install-Assets {
    param(
        [Parameter(Mandatory, Position=0)]
        [string] $InstancePath
    )

    if (-not (Test-Path "assets")) {
        throw "local assets directory is required for resource-pack installation, but it's not found! Aborting install!"

    } elseif (-not (Test-Path "assets/pack.mcmeta")) {
        throw "pack.mcmeta is required for resource-pack installation, but it's not found! Aborting install!"
    }

    Write-Info "Installing assets..."

    if ($WorldNew) {
        throw "Cannot install ContentPack assets in -WorldNew mode!"
    }

    $PacksPath = Join-Path $InstancePath "resourcepacks"
    if (-not (Test-Path $PacksPath)) {
        Write-Info "Instance's 'resourcepacks' folder not found, creating..."
        New-Item -Path $PacksPath -ItemType Directory -Force
    }

    $ContentPath = Join-Path $PacksPath $ContentName
    if (-not (Test-Path $ContentPath)) {
        Write-Info "ResourcePack's folder ('${ContentName}') not found, creating..."
        New-Item -Path $ContentPath -ItemType Directory -Force
    }

    $Meta = Join-Path $ContentPath "pack.mcmeta"
    Copy-Item -Path "assets/pack.mcmeta" -Destination $Meta -Force
    Write-Info "Copied 'assets/pack.mcmeta' -> '${Meta}'"

    $AssetPath = Join-Path $ContentPath "assets"
    if (-not (Test-Path $AssetPath)) {
        Write-Info "ResourcePack's top-level 'assets' folder not found, creating..."
        New-Item -Path $AssetPath -ItemType Directory -Force
    }

    Get-ChildItem -Path "assets" -Exclude "pack.mcmeta" | ForEach-Object {
        $BaseName = $_.BaseName
        $Destination = Join-Path $AssetPath $BaseName

        if (Join-Path $AssetPath $BaseName | Test-Path) {
            Remove-Item -Path $Destination -Recurse -Force
        }

        Copy-Item -Path $_.FullName -Destination $AssetPath -Recurse
        Write-Info "Copied namespace '${BaseName}' :: '${Destination}'"
    }
}

function Install-Data {
    param(
        [Parameter(Mandatory, Position=0)]
        [string] $InstancePath,

        [Parameter(Position=1)]
        [string] $SaveName
    )

    if (-not (Test-Path "data")) {
        throw "local data directory is required for datapack installation, but it's not found! Aborting install!"

    } elseif (-not (Test-Path "data/pack.mcmeta")) {
        throw "pack.mcmeta is required for datapack installation, but it's not found! Aborting install!"
    }

    Write-Info "Installing data..."

    if (-not $WorldNew) {
        $SavePath = Join-Path $InstancePath "saves"
        if (-not (Test-Path $SavePath)) {
            Write-Info "Instance's 'saves' folder not found, creating..."
            New-Item -Path $SavePath -ItemType Directory -Force
    
            # If we had to create this folder, we know it has no contents. We can fail early.
            throw "full save-path value '${SavePath}' could not be found. Aborting install!"
        }
    
        $SavePath = Join-Path $SavePath $SaveName
        if (-not (Test-Path $SavePath)) {
            throw "full save-path value '${SavePath}' could not be found. Aborting install!"
        }
    
        $PacksPath = Join-Path $SavePath "datapacks"
        if (-not (Test-Path $PacksPath)) {
            Write-Info "Save's 'datapacks' folder not found, creating..."
            New-Item -Path $PacksPath -ItemType Directory -Force
        }
    } else {
        if (-not (Test-Path $InstancePath)) {
            throw "New world's temp folder for datapacks not found: '${InstancePath}'"
        }
        $PacksPath = $InstancePath
    }

    $ContentPath = Join-Path $PacksPath $ContentName
    if (-not (Test-Path $ContentPath)) {
        Write-Info "Datapack's folder ('${ContentName}') not found, creating..."
        New-Item -Path $ContentPath -ItemType Directory -Force > $null
    }

    $Meta = Join-Path $ContentPath "pack.mcmeta"
    Copy-Item -Path "data/pack.mcmeta" -Destination $Meta -Force > $null
    Write-Info "Copied 'data/pack.mcmeta' -> '${Meta}'"

    $DataPath = Join-Path $ContentPath "data"
    if (-not (Test-Path $DataPath)) {
        Write-Info "Datapack's top-level 'data' folder not found, creating..."
        New-Item -Path $DataPath -ItemType Directory -Force > $null
    }

    Get-ChildItem -Path "data" -Exclude "pack.mcmeta" | ForEach-Object {
        $BaseName = $_.BaseName
        $Destination = Join-Path $DataPath $BaseName

        if (Join-Path $DataPath $BaseName | Test-Path) {
            Remove-Item -Path $Destination -Recurse -Force
        }

        Copy-Item -Path $_.FullName -Destination $DataPath -Recurse
        Write-Info "Copied namespace '${BaseName}' :: '${Destination}'"
    }
}

function Main {
    if (-not (Test-Path $InstancePath)) {
        throw "InstancePath value '${InstancePath}' could not be found. Aborting install!"
    }

    if ($Assets) { Install-Assets $InstancePath }
    if ($Data) { Install-Data $InstancePath $SaveName }

    if (-not $Assets -and -not $Data) { Get-Help -Detailed .\Install-ContentPack.ps1 }

    Write-Host
}

Main
