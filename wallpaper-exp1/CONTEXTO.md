# Contexto para continuar o wallpaper GANWALK numa sessão local

Este arquivo resume tudo o que foi feito numa sessão do Claude Code na nuvem, para
continuar numa sessão rodando no próprio PC (Windows), onde dá para testar o
Wallpaper Engine e o script do PowerShell de verdade.

## Onde está o código

- Repositório: `ganwalk/ganwalk`, branch **`claude/practical-albattani-xv8tip`**
  (o `main` não foi alterado). Pasta do projeto: `wallpaper-exp1/`.
- Cópia instalada no PC: `C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\ganwalk-wallpaper`
  (é o conteúdo de `wallpaper-exp1/`, extraído de `ganwalk-wallpaper.zip`).
- Origem: a "Exp I" (Visualizer, objeto `App1` em `index.htm`) do repositório
  `ganwalk/2026`, o site do artista. Sem acesso de escrita lá; por isso o
  wallpaper vive em `ganwalk/ganwalk`.
- O motor de dither veio de `ganwalk/portifolio` (`src/lib/dither.ts` e
  `src/lib/use-bayer-dither.ts`): matriz de Bayer 4×4 recursiva, luminância
  Rec. 601, `BIAS` 42, fases trocando a cada 175 ms.

```
wallpaper-exp1/
├── index.html       # tudo: cena, áudio, relógio, reprodutor, dither, painel do PC
├── project.json     # manifesto do Wallpaper Engine (tipo web, áudio ligado, propriedades)
├── preview.jpg
├── README.md        # documentação para o usuário (pt-BR)
├── CONTEXTO.md      # este arquivo
├── stats/
│   ├── ganwalk-stats.ps1   # servidor local com informações do PC (PowerShell 5.1)
│   ├── iniciar.cmd         # roda o script escondido
│   └── testar.cmd          # roda o script com janela; log em stats/ganwalk-stats.log
├── lib/             # Three.js r128 + EffectComposer/UnrealBloomPass (locais, sem CDN)
└── fonts/           # Astloch Bold, Inter (variável), Silkscreen + licenças OFL
```

## O que o wallpaper faz hoje

Módulos em `index.html` (um `<script>` só, objetos globais):

- **`Wallpaper`**: cena Three.js do site (icosaedro wireframe, grade 30×30, bloom).
  Áudio do sistema via `window.wallpaperRegisterAudioListener` (128 valores: 64
  bandas L + 64 R), separado em grave/médio/agudo, com ganho automático. Relógio
  e data em pt-BR no topo (Inter fina). O icosaedro **gira seguindo o mouse sem
  sair do lugar** (`followGroup` só com rotação). As três linhas que reagem ao som
  são desenhadas num canvas 2D (`#waves`), de fora a fora, no meio do vão entre
  o "GANWALK" e a barra de tarefas (`layoutLower`).
- **`DitherWave`**: o "pulso". Uma onda de dither em anel que nasce do icosaedro.
  Sem música: a cada 10 s e também quando o grave bate forte (detecção de salto
  sobre a média, com tempo mínimo entre disparos). Com música: a cada 25 s, e
  passado esse tempo espera a próxima batida forte (até 3 s).
- **`DitherFade`**: toda entrada e saída de elementos é em dither (máscara CSS
  com os 17 níveis da matriz de Bayer). Regra do usuário: **todas as transições
  devem ser em dither**.
- **`NowPlaying`**: integração de mídia do Wallpaper Engine (título, artista,
  capa, posição). Com música tocando, o **reprodutor** (horizontal, estilo do
  painel da Exp I, capa em dither, barras de espectro diagonais em dither nascendo
  da borda direita/superior) ocupa o lugar do "GANWALK". A cada pulso o "GANWALK"
  volta logo antes da onda, **fica 4 s** e o reprodutor retorna.
- **`SysStats`**: sem música, o lugar das três linhas mostra processador, memória,
  até 3 discos e tempo ligado (largura igual à do "GANWALK"), e duas barras
  verticais de temperatura (CPU à esquerda, GPU à direita) ao lado da grade,
  terminando acima do "GANWALK", mostarda acima de 80 °C. Os dados vêm de
  `http://localhost:7457/stats` (consulta a cada 3 s, timeout 4 s, uma por vez).
  Opção "Diagnóstico do script" mostra o status no canto superior esquerdo.

Propriedades editáveis ficam no `project.json` e são lidas em
`window.wallpaperPropertyListener.applyUserProperties`.

## Problema em aberto: o painel do PC não aparece

Histórico:

1. Primeira versão do script: respondia lendo os sensores durante o pedido; leituras
   lentas passavam do timeout do wallpaper. Corrigido (leitura em segundo plano).
2. Um erro de sintaxe (`$Port:` dentro de string) impedia o script de rodar. Corrigido.
3. Com isso **funcionou** (painel apareceu), mas a barra da CPU não aparecia
   (temperatura da CPU nula: sem LibreHardwareMonitor e sem admin).
4. Foram adicionadas fontes de temperatura (contador `Win32_PerfFormattedData_Counters_ThermalZoneInformation`
   e o servidor web do LibreHardwareMonitor em `localhost:8085/data.json`). **Aí o
   painel parou de aparecer de novo.** Hipótese: essas leituras são lentas e
   bloqueavam a resposta.
5. Última versão (commit `aec9f81`, **ainda não testada no Windows**): a leitura dos
   sensores roda num runspace separado (`[powershell]::Create()` + hashtable
   sincronizada), a cada 2 s; o laço do `HttpListener` só entrega o JSON pronto (503
   enquanto a primeira leitura não termina). Cada `Get-CimInstance` tem
   `-OperationTimeoutSec 5`. O log registra quanto tempo a primeira leitura levou.

### Como depurar localmente

1. Encerrar qualquer `powershell.exe` do script que esteja rodando.
2. Na pasta instalada, rodar `stats\testar.cmd` (ou
   `powershell -NoProfile -ExecutionPolicy Bypass -File stats\ganwalk-stats.ps1`).
3. Ler `stats\ganwalk-stats.log`: deve ter "Primeira leitura em N ms: {...}" e
   "Primeiro pedido vindo de: '<origin>' (aceito)".
4. Testar `http://localhost:7457/stats` no navegador (sem Origin é aceito).
5. No Wallpaper Engine, ligar "Diagnóstico do script" e ler a linha no canto.
6. Testar cada fonte de temperatura isoladamente e medir o tempo, por exemplo
   `Measure-Command { Get-CimInstance Win32_PerfFormattedData_Counters_ThermalZoneInformation }`.

Cuidados com o PowerShell 5.1 (o que vem no Windows):

- O `.ps1` precisa estar em **UTF-8 com BOM** (senão os acentos quebram) e CRLF.
- `"$var:"` dentro de string é erro de sintaxe: usar `${var}`.
- `ArrayList.Add` devolve um índice que vaza para a saída da função: usar `[void]`.
- Sem `??`, sem ternário (`a ? b : c`).
- O `HttpListener` usa o prefixo `http://localhost:PORT/` (sem admin). Pedidos
  para `127.0.0.1` dão 400, por isso o wallpaper usa `localhost`.
- O script recusa Origins `http(s)` que não sejam localhost (privacidade: sites
  abertos no navegador não podem ler os dados).

## Preferências do usuário (decisões já tomadas)

- Toda a comunicação, docs e commits em **português do Brasil**. No texto visível,
  sem travessão nem meia risca (regra do portfólio dele).
- Estética do site: fundo `#120c07`, foco `#ece0c6`, acento mostarda `#d99a4e`,
  Astloch no "GANWALK", Silkscreen nos rótulos, Inter nos textos e no relógio.
- Todas as transições em dither. Visual sempre na linguagem da Exp I.
- Fluxo de entrega até aqui: commit e push no branch acima, e um zip com a pasta
  `ganwalk-wallpaper/` para instalar.

## Como testar o wallpaper fora do Wallpaper Engine

Servir a pasta (`python -m http.server 8765`) e abrir `index.html` no navegador.
Sem a API do Wallpaper Engine, ele usa áudio sintético e uma música de exemplo.
Na nuvem, os testes simulavam `wallpaperRegisterAudioListener` e os listeners de
mídia com Playwright e um servidor Python falso para `/stats`.
