<#
.SYNOPSIS
    Auto-detecção completa do ambiente Windows para o WinSanitizer.
.DESCRIPTION
    Identifica versão do Windows, edição, build, todos os discos montados,
    caminhos reais das pastas de usuário (mesmo com OneDrive/redirecionamento),
    e gera um manifesto JSON do ambiente.
#>

function Get-WinEnvironment {
    [CmdletBinding()]
    param()

    # 1. Informações do Sistema Operacional
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    $isServer = ($os.ProductType -ne 1) # 1 = Workstation, 2 = Domain Controller, 3 = Server
    $osType   = if ($isServer) { "Windows Server" } else { "Windows Desktop" }

    # 2. Detecção de todos os discos físicos e partições fixas
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $freeGB  = [math]::Round($_.FreeSpace / 1GB, 2)
        $sizeGB  = [math]::Round($_.Size / 1GB, 2)
        $usedGB  = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
        $percentFree = if ($sizeGB -gt 0) { [math]::Round(($freeGB / $sizeGB) * 100, 1) } else { 0 }

        [PSCustomObject]@{
            DriveLetter = $_.DeviceID
            VolumeName  = $_.VolumeName
            FileSystem  = $_.FileSystem
            SizeGB      = $sizeGB
            FreeGB      = $freeGB
            UsedGB      = $usedGB
            PercentFree = $percentFree
            Status      = if ($percentFree -lt 10) { "CRÍTICO" } elseif ($percentFree -lt 20) { "ALERTA" } else { "OK" }
        }
    }

    # 3. Resolução dos caminhos reais das pastas do usuário via Shell SpecialFolders
    # (Garante funcionamento mesmo se o usuário redirecionou para D:, OneDrive, etc.)
    $userFolders = [PSCustomObject]@{
        Profile   = $env:USERPROFILE
        Desktop   = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
        Downloads = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
        Documents = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
        Pictures  = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
        Videos    = (New-Object -ComObject Shell.Application).Namespace('shell:My Video').Self.Path
        Music     = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyMusic)
    }

    # 4. Compilação do Manifesto
    $manifest = [PSCustomObject]@{
        Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ComputerName  = $cs.Name
        UserName      = $env:USERNAME
        OSName        = $os.Caption
        OSVersion     = $os.Version
        OSBuild       = $os.BuildNumber
        OSArchitecture= $os.OSArchitecture
        OSType        = $osType
        IsServer      = $isServer
        TotalRAM_GB   = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        SystemDrive   = $os.SystemDrive
        WindowsDir    = $os.WindowsDirectory
        Drives        = $drives
        UserFolders   = $userFolders
    }

    return $manifest
}

# Execução direta para teste
$env_info = Get-WinEnvironment
$env_info | ConvertTo-Json -Depth 4
