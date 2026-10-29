<#
.SYNOPSIS
    WinSanitizer — Agente Autônomo Portátil de Manutenção e Organização Windows.
.DESCRIPTION
    Auto-detecta o ambiente Windows, caminhos de perfil reais (inclusive OneDrive),
    varre discos e pastas de usuário, e opcionalmente usa Ollama + Qwen localmente
    para sugerir organização semântica inteligente.
.PARAMETER UseAI
    Ativa classificação via IA local (Ollama + Qwen/LLaMA).
.PARAMETER AIModel
    Nome do modelo no Ollama (default: llama3.2:3b ou qwen2.5:14b).
.PARAMETER OllamaUrl
    URL da API do Ollama (default: http://localhost:11434).
.PARAMETER Apply
    Executa as mudanças (sem esta flag, roda em modo Dry-Run seguro).
#>

[CmdletBinding()]
param(
    [switch]$UseAI,
    [string]$AIModel = "llama3.2:3b",
    [string]$OllamaUrl = "http://localhost:11434",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "🛡️ WINSANITIZER — MANUTENÇÃO E SANIFICAÇÃO INTELIGENTE" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. AUTO-DETECÇÃO DO AMBIENTE WINDOWS
# -----------------------------------------------------------------------------
Write-Host "[*] [1/4] Auto-detectando ambiente Windows..." -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$isServer = ($os.ProductType -ne 1)

$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    $sizeGB = [math]::Round($_.Size / 1GB, 2)
    [PSCustomObject]@{
        DriveLetter = $_.DeviceID
        VolumeName  = $_.VolumeName
        FreeGB      = $freeGB
        SizeGB      = $sizeGB
        PercentFree = if ($sizeGB -gt 0) { [math]::Round(($freeGB / $sizeGB) * 100, 1) } else { 0 }
    }
}

# Resolução dinâmica das pastas do usuário via Shell (resolve OneDrive automaticamente)
$shell = New-Object -ComObject Shell.Application
$userFolders = [PSCustomObject]@{
    Profile   = $env:USERPROFILE
    Desktop   = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
    Downloads = $shell.Namespace('shell:Downloads').Self.Path
    Documents = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
    Pictures  = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
    Videos    = $shell.Namespace('shell:My Video').Self.Path
}

Write-Host "    -> Computador: $($cs.Name) | SO: $($os.Caption) (Build $($os.BuildNumber))" -ForegroundColor DarkGray
Write-Host "    -> Tipo: $(if ($isServer) { 'Windows Server' } else { 'Windows Desktop' }) | RAM: $([math]::Round($cs.TotalPhysicalMemory/1GB, 2)) GB" -ForegroundColor DarkGray
Write-Host "    -> Discos: $(($drives.DriveLetter) -join ', ')" -ForegroundColor DarkGray
Write-Host "    -> Downloads: $($userFolders.Downloads)" -ForegroundColor DarkGray
Write-Host "    -> Desktop: $($userFolders.Desktop)" -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# 2. VARREDURA DE ANOMALIAS E ARQUIVOS SUSPEITOS
# -----------------------------------------------------------------------------
Write-Host "`n[*] [2/4] Varrendo pastas em busca de anomalias..." -ForegroundColor Yellow

$suspectPatterns = @("*(*)*", "download*", "novo*", "temp*", "teste*", "*_old*", "*.tmp", "*.bak")
$excludePaths = @("*\AppData\*", "*\.git\*", "*\node_modules\*", "*\.venv*\*", "*\Windows\*", "*\Program Files*")

$targets = @(
    $userFolders.Downloads,
    $userFolders.Desktop,
    $userFolders.Documents,
    $userFolders.Pictures
) | Where-Object { $_ -and (Test-Path $_) }

$foundFiles = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($target in $targets) {
    Get-ChildItem -Path $target -File -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_
        $isExcluded = $false
        foreach ($ex in $excludePaths) {
            if ($file.FullName -like $ex) { $isExcluded = $true; break }
        }
        if ($isExcluded) { return }

        $matched = $false
        foreach ($pat in $suspectPatterns) {
            if ($file.Name -like $pat) { $matched = $true; break }
        }

        if ($matched) {
            $foundFiles.Add([PSCustomObject]@{
                NomeAtual = $file.Name
                Caminho   = $file.FullName
                Pasta     = $target
                TamanhoMB = [math]::Round($file.Length / 1MB, 2)
                Extensao  = $file.Extension.ToLower()
            })
        }
    }
}

Write-Host "    -> Total de arquivos suspeitos/duplicados: $($foundFiles.Count)" -ForegroundColor Cyan

if ($foundFiles.Count -eq 0) {
    Write-Host "`n✅ [OK] Sistema de arquivos 100% limpo! Nenhuma anomalia detectada." -ForegroundColor Green
    return
}

# -----------------------------------------------------------------------------
# 3. CLASSIFICAÇÃO SEMÂNTICA (OLLAMA/QWEN OU HEURÍSTICA NATIVA)
# -----------------------------------------------------------------------------
Write-Host "`n[*] [3/4] Gerando plano de organização..." -ForegroundColor Yellow

$plan = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($UseAI) {
    Write-Host "    -> Acionando IA Local ($AIModel via Ollama em $OllamaUrl)..." -ForegroundColor Cyan
    $prompt = @"
Você é um especialista em organização de arquivos Windows.
Analise os arquivos abaixo e retorne APENAS um JSON válido com esta estrutura:
[
  {
    "ArquivoAtual": "nome.ext",
    "NovoNome": "nome_limpo.ext",
    "Categoria": "NomeDaPasta",
    "Justificativa": "Motivo"
  }
]

Arquivos:
$($foundFiles | Select-Object NomeAtual, TamanhoMB, Extensao | ConvertTo-Json -Depth 2)
"@
    try {
        $body = @{
            model  = $AIModel
            prompt = $prompt
            stream = $false
            format = "json"
        } | ConvertTo-Json -Depth 4

        $response = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 120
        $aiJson = $response.response | ConvertFrom-Json

        # Suporta retorno direto em array ou envelopado
        $items = if ($aiJson -is [array]) { $aiJson } elseif ($aiJson.Arquivos) { $aiJson.Arquivos } else { @($aiJson) }
        foreach ($it in $items) {
            $orig = $foundFiles | Where-Object { $_.NomeAtual -eq $it.ArquivoAtual } | Select-Object -First 1
            if ($orig) {
                $plan.Add([PSCustomObject]@{
                    ArquivoAtual = $it.ArquivoAtual
                    NovoNome     = $it.NovoNome
                    Categoria    = $it.Categoria
                    CaminhoOrig  = $orig.Caminho
                    Motor        = "AI ($AIModel)"
                })
            }
        }
    } catch {
        Write-Warning "Falha ao consultar Ollama ($($_)). Recorrendo à heurística nativa."
    }
}

# Fallback heurístico caso não use IA ou ela falhe
if ($plan.Count -eq 0) {
    Write-Host "    -> Usando motor heurístico nativo..." -ForegroundColor DarkGray
    foreach ($f in $foundFiles) {
        $cleanName = $f.NomeAtual -replace '\s*\(\d+\)', '' -replace '_\(\d+\)', ''
        $cat = switch ($f.Extensao) {
            { $_ -in '.exe', '.msi' } { 'Instaladores' }
            { $_ -in '.iso', '.vmdk', '.vhdx' } { 'ISOs' }
            { $_ -in '.png', '.jpg', '.jpeg', '.webp' } { 'Imagens' }
            { $_ -in '.pdf', '.docx', '.xlsx', '.pptx' } { 'Documentos' }
            { $_ -in '.mp4', '.mkv', '.mp3' } { 'Videos_Audios' }
            default { 'Geral' }
        }
        $plan.Add([PSCustomObject]@{
            ArquivoAtual = $f.NomeAtual
            NovoNome     = $cleanName
            Categoria    = $cat
            CaminhoOrig  = $f.Caminho
            Motor        = "Heurística"
        })
    }
}

# Exibe o plano proposto
$plan | Format-Table ArquivoAtual, NovoNome, Categoria, Motor -AutoSize

# -----------------------------------------------------------------------------
# 4. EXECUÇÃO OU DRY-RUN
# -----------------------------------------------------------------------------
if (-not $Apply) {
    Write-Host "`n[INFO] Modo Dry-Run ativo (nenhum arquivo foi alterado)." -ForegroundColor Yellow
    Write-Host "Para executar a movimentação/renomeação, rode:" -ForegroundColor DarkGray
    Write-Host "  .\Invoke-WinSanitizer.ps1 -Apply" -ForegroundColor Cyan
    Write-Host "  .\Invoke-WinSanitizer.ps1 -UseAI -Apply" -ForegroundColor Cyan
} else {
    Write-Host "`n[*] [4/4] Aplicando plano de organização..." -ForegroundColor Green
    foreach ($item in $plan) {
        $destFolder = Join-Path (Split-Path -Parent $item.CaminhoOrig) $item.Categoria
        if (-not (Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        }
        $destFile = Join-Path $destFolder $item.NovoNome
        Move-Item -Path $item.CaminhoOrig -Destination $destFile -Force
        Write-Host "    [OK] $($item.ArquivoAtual) -> $($item.Categoria)\$($item.NovoNome)" -ForegroundColor Green
    }
    Write-Host "`n🎉 Organização concluída com sucesso!" -ForegroundColor Green
}
