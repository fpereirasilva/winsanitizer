# 🛡️ WinSanitizer: Como Construí um Agente Autônomo com PowerShell e LLMs Locais (Qwen + Ollama) para Sanificar Discos e Servidores de Arquivos Windows

> *Uma abordagem prática sobre auto-detecção de ambiente, limpeza inteligente de anomalias semânticas, governança de storage corporativo e inferência 100% offline com IA local.*  
> **Autor:** [Fábio Silva](https://telapreta.dev.br) — *Microsoft MVP DevOps · MCT · Arquiteto de Soluções Multi-Cloud & IA*

---

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B%20%7C%205.1-blue.svg?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Ollama](https://img.shields.io/badge/AI-Ollama%20%7C%20Qwen2.5-black.svg?logo=ollama)](https://ollama.com)
[![Windows Server](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server%202022%2F2025-0078D6.svg?logo=windows)](https://microsoft.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Multi-Assistant](https://img.shields.io/badge/Compatibility-Claude%20%7C%20Copilot%20%7C%20Codex%20%7C%20Qwen-green.svg)](#-compatibilidade-universal)

---

## 💡 O Problema que Todo SysAdmin e Desenvolvedor Conhece

Seja na sua workstation de desenvolvimento ou em um **Servidor de Arquivos Corporativo (File Server / SMB)** com dezenas de departamentos, o ciclo da desorganização sempre se repete:

* `Relatorio_Final (1).xlsx`, `Contrato_Revisado (2) (cópia).docx`, `backup_final_v2_novo.zip`.
* Instaladores `.exe` e `.msi` esquecidos desde 2021 consumindo gigabytes de SSD/NVMe caro.
* Prints de tela genéricos (`Screenshot_2026-10-28...png`, `download (3).png`) acumulados nas pastas de download e rede.
* Pastas com caminhos complexos que variam de máquina para máquina — especialmente agora que o Windows frequentemente move `Desktop`, `Documents` e `Pictures` para o **OneDrive** sem aviso prévio.

Fazer essa triagem manualmente consome horas. Criar scripts ingênuos com caminhos fixos (`C:\Users\...`) quebra facilmente e, pior: pode acidentalmente deletar arquivos de sistema, quebrar repositórios `.git` ou corromper permissões NTFS de rede.

Para resolver isso de forma definitiva, criei o **WinSanitizer**.

---

## 🧠 A Arquitetura: Três Camadas de Resolução

O projeto foi desenhado sob 3 premissas fundamentais:
1. **Auto-Descoberta Total do SO:** Ninguém deve precisar configurar se a máquina é Windows 10, 11 ou Server, nem onde estão os discos ou o OneDrive.
2. **Motor Híbrido (Heurística + LLMs Locais):** Roda instantâneo e offline, mas pode consultar modelos locais como **Qwen 2.5** ou **LLaMA 3.2** via **Ollama** para entender o contexto do arquivo e propor nomes inteligentes.
3. **Segurança Militar e Zero Danos:** Modo Dry-Run ativo por padrão, com lista negra inegociável de arquivos de sistema e de controle de versão.

```text
      ┌──────────────────────────────────────────────────────────────┐
      │                 INTERFACES DE CONTROLE                       │
      │                                                              │
      │   • Terminal PowerShell / Prompt do Windows                  │
      │   • Skills de Terminal (/manutencao)                         │
      │   • GitHub Copilot no VS Code (@workspace)                   │
      │   • OpenAI Codex / ChatGPT Desktop                           │
      └──────────────────────────────┬───────────────────────────────┘
                                     │
                                     ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │                       WINSANITIZER CORE ENGINE                       │
  │                                                                      │
  │  [CAMADA 1: DETECÇÃO DINÂMICA]                                       │
  │  • Shell SpecialFolders API ➔ Resolve OneDrive / Desktop / Downloads │
  │  • WMI / CIM ➔ Descobre discos físicos (C:, E:, H:), NVMe, ReFS/NTFS │
  │                                                                      │
  │  [CAMADA 2: VARREDURA E FILTRAGEM]                                   │
  │  • Busca padrões: (*), download*, temp*, *_old*, órfãos na raiz      │
  │  • Blindagem: ignora C:\Windows, Program Files, .git, .venv, etc.    │
  │                                                                      │
  │  [CAMADA 3: DECISÃO SEMÂNTICA]                                       │
  │  • Heurística Nativa: limpa sufixos e agrupa por tipo de extensão    │
  │  • IA Local (Ollama + Qwen2.5:14b / LLaMA): analisa contexto e       │
  │    gera nomes semânticos em JSON estruturado                         │
  │                                                                      │
  │  [CAMADA 4: EXECUÇÃO CONTROLADA]                                     │
  │  • Modo Dry-Run: exibe tabela Antes ➔ Depois sem alterar nada        │
  │  • Modo Apply: executa movimentação preservando integridade NTFS     │
  └──────────────────────────────────────────────────────────────────────┘
```

---

## 🏢 Funciona em Servidores de Arquivos (File Server)?

**Sim, e é um dos principais casos de uso!**

Em servidores Windows Server (2019/2022/2025) que gerenciam compartilhamentos SMB corporativos:

* **Elevação Obrigatória:** Para escanear e organizar arquivos de múltiplos usuários e departamentos diferentes, o PowerShell deve ser executado **como Administrador** (ou com credenciais do grupo *Operadores de Backup / Domínio*), garantindo acesso a todas as ACLs NTFS sem erros de `Access Denied`.
* **Preservação de Herança NTFS:** Ao mover arquivos dentro do volume do servidor, os itens herdam as permissões da pasta pai de destino, mantendo a governança de acesso intacta.
* **Suporte a Múltiplos Volumes:** Varre automaticamente unidades de dados secundárias (`D:`, `E:`, `H:`, volumes SAN/iSCSI ou ReFS).

```powershell
# Execução em Servidor de Arquivos (abra o PowerShell como Administrador):
.\Invoke-WinSanitizer.ps1
```

---

## 🤖 Como Funciona a IA Local com Ollama + Qwen

Ao passar a flag `-UseAI`, o script não manda nenhum dado para a nuvem. Ele se conecta via HTTP na porta `11434` do seu **Ollama local**:

```powershell
# Usando Qwen 2.5 (14B) local:
.\Invoke-WinSanitizer.ps1 -UseAI -AIModel "qwen2.5:14b"

# Usando LLaMA 3.2 (3B) para execução ultra-rápida:
.\Invoke-WinSanitizer.ps1 -UseAI -AIModel "llama3.2:3b"
```

O modelo recebe a lista de metadados e responde com um plano JSON estruturado:

```json
[
  {
    "ArquivoAtual": "Setup_Docker_Desktop (1).exe",
    "NovoNome": "Setup_Docker_Desktop.exe",
    "Categoria": "Instaladores",
    "Justificativa": "Removido sufixo duplicado e agrupado em pasta de executaveis"
  },
  {
    "ArquivoAtual": "Certificado_CKA (2).pdf",
    "NovoNome": "Certificado_CKA_Kubernetes.pdf",
    "Categoria": "Certificacoes",
    "Justificativa": "Removido contador e adicionado nome semantico claro"
  }
]
```

Se o Ollama não estiver aberto, o script possui **fallback automático** e aplica a heurística nativa instantaneamente.

---

## ⚡ Passo a Passo: Demonstração Real

### 1. Auto-Detecção do Ambiente

```powershell
.\detect-environment.ps1
```

**Saída Real:**
```json
{
  "ComputerName": "X-WING",
  "OSName": "Microsoft Windows 11 Enterprise (Build 26300)",
  "OSType": "Windows Desktop",
  "TotalRAM_GB": 31.71,
  "Drives": [
    { "DriveLetter": "C:", "FreeGB": 225.8, "SizeGB": 952.2, "Status": "OK" },
    { "DriveLetter": "E:", "FreeGB": 464.8, "SizeGB": 1907.7, "Status": "OK" },
    { "DriveLetter": "H:", "FreeGB": 1704.4, "SizeGB": 1863.0, "Status": "OK" }
  ],
  "UserFolders": {
    "Downloads": "C:\Users\FabioSilva\Downloads",
    "Desktop": "C:\Users\FabioSilva\OneDrive - Microsoft 365\Área de Trabalho"
  }
}
```

### 2. Varredura com Simulação Segura (Dry-Run)

```powershell
.\Invoke-WinSanitizer.ps1
```

O console gera a tabela completa comparando o **Antes ➔ Depois ➔ Pasta Destino**, permitindo validação visual prévia.

### 3. Aplicação Definitiva

```powershell
.\Invoke-WinSanitizer.ps1 -Apply
```

Todos os arquivos são movidos com segurança para pastas dedicadas (`Instaladores`, `Documentos`, `Certificações`, `Imagens`, `Vídeos`), zerando a desorganização.

---

## 🌐 Compatibilidade Universal

| Assistente | Como Utilizar |
| :--- | :--- |
| **CLI / Terminal** | Use as skills integradas `/manutencao` ou `/manutencaocomputador` |
| **GitHub Copilot** | Instrução global em `.github/copilot-instructions.md` (chame com `@workspace organize os arquivos`) |
| **OpenAI Codex** | Executa o script nativo direto no terminal integrado |
| **Ollama + Qwen** | Totalmente autônomo via API REST local na porta `:11434` |

---

## 🛡️ Matriz de Segurança (O que NUNCA é Tocado)

O WinSanitizer possui uma lista de exclusão protegida no código-fonte:

* ❌ `C:\Windows` e subdiretórios (Kernel, System32, Drivers)
* ❌ `C:\Program Files` e `C:\Program Files (x86)`
* ❌ `AppData` (configurações de apps, cookies e dados de sessão)
* ❌ Pastas de desenvolvimento e versionamento: `.git`, `node_modules`, `.venv*`, `.terraform`, `.claude`
* ❌ Arquivos essenciais do sistema: `pagefile.sys`, `swapfile.sys`, `bootmgr`, `DumpStack.log`

---

## 📦 Estrutura do Repositório

```text
winsanitizer/
├── Invoke-WinSanitizer.ps1    # Script principal com suporte a Heurística, Ollama e Dry-Run
├── detect-environment.ps1   # Auto-detecção de hardware, discos e Shell SpecialFolders
├── ask-qwen.ps1             # Integração REST com Ollama (Qwen2.5 / LLaMA3.2)
├── README.md                # Artigo completo e documentação técnica
├── LICENSE                  # Licença MIT
├── .gitignore               # Ignora temporários e artefatos do PowerShell
└── POST_LINKEDIN.md         # Post pronto para publicação no LinkedIn e no X
```

---

## 📄 Licença

Este projeto é software livre sob a licença [MIT](LICENSE).

---

**Gostou do projeto? Deixe uma ⭐️ no repositório!**  
Conecte-se comigo no [LinkedIn](https://linkedin.com/in/fpereirasilva) e conheça a plataforma de labs práticos em [telapreta.dev.br](https://telapreta.dev.br).
