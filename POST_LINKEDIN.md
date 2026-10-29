# 📢 Posts Prontos para Divulgação: LinkedIn & X (Twitter)

---

## 💼 1. Post para o LinkedIn (Formato Artigo / Storytelling Técnico)

```text
Como um script ingênuo de limpeza pode quebrar um servidor de arquivos — e como resolvi isso unindo PowerShell e IA Local (Qwen + Ollama). 🚀

Todo profissional de TI já viveu esse cenário:

Um Servidor de Arquivos corporativo (File Server) ou uma workstation com dezenas de gigabytes consumidos por:
→ "Relatorio_Final (1).xlsx", "Contrato_Revisado (2) (cópia).docx"
→ Instaladores .exe esquecidos desde 2021 em pastas de rede
→ Capturas de tela genéricas e zips de backup soltos na raiz dos discos

O problema? Scripts comuns de automação costumam cometer 3 erros clássicos:
1. Usam caminhos fixos (hardcoded) e quebram quando o Windows redireciona pastas para o OneDrive;
2. Não entendem o contexto semântico do arquivo para renomeá-lo de forma inteligente;
3. Podem acidentalmente tocar em pastas de repositórios (.git), ambientes virtuais (.venv) ou arquivos de sistema.

Para resolver isso de ponta a ponta, desenvolvi e abri o código do WinSanitizer: um agente autônomo e portátil em PowerShell que une auto-detecção de ambiente com inferência local via IA.

🔥 O que o WinSanitizer faz:

1️⃣ Auto-Detecção Completa do SO:
Resolve dinamicamente caminhos reais via Windows Shell SpecialFolders API (funciona mesmo com OneDrive), detecta todos os discos físicos (C:, D:, E:...) e diferencia Windows Desktop de Windows Server.

2️⃣ Motor Híbrido com IA 100% Local (Ollama + Qwen 2.5):
O agente consulta um modelo local (como Qwen 2.5 de 14B ou LLaMA 3.2 de 3B) rodando na própria máquina via Ollama. A IA analisa o metadado, sugere o novo nome semântico e a pasta correta — sem enviar um único byte para a nuvem.

3️⃣ Segurança Militar e File Server Ready:
• Modo Dry-Run ativo por padrão (você valida o Antes ➔ Depois antes de aplicar);
• Blindagem estrita: NUNCA toca em C:\Windows, Program Files, AppData, .git ou swap do kernel;
• Em servidores de arquivos, preserva a herança de permissões NTFS de rede ao mover os arquivos.

4️⃣ Compatibilidade Universal:
Funciona direto no terminal PowerShell, como Skill integrada (/manutencao), no GitHub Copilot (@workspace) e no OpenAI Codex.

O projeto é 100% Open Source sob licença MIT! ⭐

🔗 Repositório oficial no GitHub: https://github.com/fpereirasilva/winsanitizer

Como vocês lidam com governança de storage e organização de arquivos na infraestrutura de vocês? Me conta nos comentários!

#DevOps #PowerShell #WindowsServer #SysAdmin #OpenSource #Ollama #Qwen #AI #ArtificialIntelligence #CloudArchitecture #Storage #Automation #TelaPreta
```

---

## 🐦 2. Post / Thread para o X (antigo Twitter)

```text
Criei um agente autônomo em PowerShell para sanificar discos e servidores de arquivos Windows usando IA local (Qwen2.5 + Ollama) 🛡️

Resolve dinamicamente caminhos reais (inclusive OneDrive), audita volumes (C:, E:, H:) e organiza anomalias sem tocar em arquivos de sistema.

100% offline e open source:
🔗 https://github.com/fpereirasilva/winsanitizer

#PowerShell #SysAdmin #Ollama #Qwen #DevOps #WindowsServer
```
