<#
.SYNOPSIS
    Ponte de Inteligência Local com Ollama + Qwen para o WinSanitizer.
.DESCRIPTION
    Envia os arquivos detectados para o modelo Qwen2.5 local via Ollama HTTP API
    e recebe um plano semântico estruturado de renomeação e organização.
#>

param(
    [string]$OllamaUrl = "http://localhost:11434",
    [string]$Model = "qwen2.5:14b",
    [Parameter(Mandatory=$true)]
    [array]$FilesToClassify
)

$prompt = @"
Você é um especialista em organização e sanitização de sistemas de arquivos Windows.
Analise a lista de arquivos abaixo (com nome atual, extensão e tamanho) e gere um plano de organização estritamente seguro.

Regras:
1. NUNCA sugira mover ou renomear arquivos de sistema, drivers ou pastas .git/.venv.
2. Para arquivos com sufixos duplicados como (1), (2), proponha a remoção do sufixo ou nome semântico claro.
3. Para instaladores (.exe, .msi), direcione para a categoria 'Instaladores'.
4. Para imagens/fotos, proponha nomes legíveis em português sem caracteres especiais.
5. Para cursos e documentos, agrupe na categoria correta.

Retorne EXCLUSIVAMENTE um array JSON válido (sem blocos markdown adicionais, apenas o JSON puro) com a seguinte estrutura para cada arquivo:
[
  {
    "ArquivoAtual": "nome_original.ext",
    "NovoNome": "nome_limpo.ext",
    "Categoria": "NomeDaPastaDestino",
    "Justificativa": "Breve motivo"
  }
]

Arquivos para analisar:
$($FilesToClassify | ConvertTo-Json -Depth 3)
"@

Write-Host "[*] Enviando $($FilesToClassify.Count) arquivo(s) para o modelo local $Model via Ollama..." -ForegroundColor Cyan

$body = @{
    model  = $Model
    prompt = $prompt
    stream = $false
    format = "json"
} | ConvertTo-Json -Depth 5

try {
    $response = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 180
    $planJson = $response.response

    # Converte o retorno do Qwen para objetos do PowerShell
    $plan = $planJson | ConvertFrom-Json
    return $plan
} catch {
    Write-Error "Erro ao comunicar com o Ollama em ${OllamaUrl}: $_"
    return $null
}
