# GANWALK — Exp I como wallpaper (Wallpaper Engine)

A Exp I (Visualizer) do [site do GANWALK](https://ganwalk.github.io/2026/) transformada
num wallpaper web para o Wallpaper Engine. A cena é a mesma do `App1`: icosaedro em
wireframe, grade, três linhas de onda e bloom, agora com relógio e data em pt-BR no topo. A diferença é de onde vem o som: em vez
de tocar `calma.mp3`, o wallpaper reage **a qualquer som que o computador estiver
reproduzindo** (Spotify, YouTube, jogos…).

## Instalar

1. Copie esta pasta (`wallpaper-exp1/`) para o seu PC.
2. No Wallpaper Engine: **Abrir wallpaper → Abrir do arquivo** e escolha o `index.html`
   desta pasta. (Ou abra o Editor do Wallpaper Engine → **Criar wallpaper** → arraste o
   `index.html`.)
3. Toque qualquer música. Se a cena não reagir, confira nas **Configurações** do
   Wallpaper Engine o dispositivo de áudio usado para capturar o som do sistema (tem que
   ser a saída que você está ouvindo). Para o icosaedro seguir o mouse, a interação com o mouse
   precisa estar ligada nas configurações.

Tudo roda localmente (Three.js r128 e as fontes Astloch, Inter e Silkscreen estão em `lib/` e `fonts/`), então
não precisa de internet.

## Como o som chega

O Wallpaper Engine chama `window.wallpaperRegisterAudioListener` cerca de 30 vezes por
segundo com 128 números: 64 bandas de frequência do canal esquerdo e 64 do direito, do
grave ao agudo. O wallpaper mistura os dois canais e separa grave, médio e agudo, como
o `AnalyserNode` fazia no site. Como os valores do WE são amplitude linear (o site usava
dB), há um **ganho automático** que normaliza pelo pico recente para a cena reagir do
mesmo jeito com o volume alto ou baixo.

Aberto direto num navegador, fora do Wallpaper Engine, não existe áudio do sistema: aí
o wallpaper usa um sinal sintético só para a cena não ficar parada.

## Propriedades (painel do Wallpaper Engine)

| Propriedade | O que faz |
| :--- | :--- |
| Cor de fundo / Cor de foco | As mesmas cores da Exp I (padrão `#120c07` / `#ece0c6`). |
| Mostrar relógio | Hora grande no topo, com a data embaixo ("Quarta-feira, 18 de novembro"), em Inter fina (a mesma família do texto do site). O brilho respira com o grave. |
| Formato 24 horas / Mostrar segundos / Mostrar data | Ajustes do relógio. Com o formato 24h desligado aparece AM/PM. |
| Tamanho, distância do topo, opacidade e brilho do relógio | Posicionamento e aparência do relógio. |
| Descer a cena | Quanto a grade, o icosaedro, as ondas e o texto descem para abrir espaço ao relógio. Com o relógio desligado, a cena volta à posição original. |
| Onda de dither | De tempos em tempos uma onda nasce no icosaedro e se expande pela tela como um anel. Por onde passa, transforma tudo (cena, "GANWALK", relógio) num retículo de dither. |
| Intervalo com música tocando | Enquanto uma música toca (integração de mídia), o pulso acontece a cada 25 s em vez de 10 s. Passado esse tempo, ele espera a próxima batida forte do grave (até 3 s) para cair no tempo da música. |
| Disparar quando o grave bater forte | Além do intervalo, a onda sai na hora quando o grave dá um salto bem acima da média recente (bumbo forte, drop). A sensibilidade decide o tamanho do salto, e o tempo mínimo evita uma onda atrás da outra. |
| Intervalo, duração, largura | De quanto em quanto tempo a onda passa (10 s por padrão), quanto tempo leva para atravessar e a largura do anel. |
| Tamanho do pixel / Intensidade do retículo | O tamanho de cada ponto e quanto o fundo escuro vira pontilhado. |
| Cores do dither | "Duotone" usa as cores do tema. "Máscara de cor" é igual ao Playground do portfólio: cor original nos pontos acesos, preto no resto. |
| Origem da onda | Do icosaedro (padrão) ou, se preferir uma faixa reta, da esquerda, da direita, de cima ou na diagonal. |
| Mostrar a música tocando | Enquanto uma música toca no computador, o reprodutor ocupa o lugar do "GANWALK". A cada pulso de dither, o "GANWALK" volta logo antes da onda sair do icosaedro, fica 4 segundos e o reprodutor retorna. Música nova troca o reprodutor em dither. |
| Tempo do GANWALK durante a música | Quanto tempo o "GANWALK" fica na tela a cada pulso enquanto a música toca (4 s por padrão). |
| Tamanho do reprodutor / barra de progresso | Escala do reprodutor e a barra de progresso (só aparece se o player informar a posição). |
| Sensibilidade ao som | Multiplica a reação ao áudio (0–3). |
| Ganho automático | Normaliza o volume. Desligue para que músicas baixas mexam menos. |
| Girar ao contrário | Equivalente visual do botão "reverso" do site. |
| Movimento no silêncio | Rotação lenta mesmo sem som. |
| Eco Profundo, Câmara Etérea, Oscilador de Realidades, Véu Sonoro, Distorção Cósmica | Os controles do site. Não mexem mais no áudio (o som é do sistema), mas dirigem a parte visual como antes: rastro e pulsação, bloom e rastro, giro em Z, apagar a grade, achatar a forma. |
| Brilho extra (bloom) | Bloom fixo somado ao da Câmara Etérea. |
| Mostrar icosaedro / grade / ondas / texto | Liga e desliga cada camada. |
| Altura da barra de tarefas | As três linhas ficam no meio do vão entre o "GANWALK" (ou o reprodutor) e a barra de tarefas, de fora a fora na tela. Ajuste se a sua barra for maior, menor ou estiver oculta (0). |
| Mostrar informações do PC sem música | Liga o painel de processador, memória, discos e tempo ligado no lugar das linhas quando não há música (precisa do script da pasta `stats/`). |
| Porta do script de informações | A porta em que o script responde (7457 por padrão). |
| Mostrar temperatura da CPU e da GPU | As duas barras verticais nas laterais da grade (precisam do script e, para a CPU, do LibreHardwareMonitor). |
| Texto, tamanho, opacidade, brilho neon | Personaliza o "GANWALK" do centro. |
| Descer o texto | Desce o "GANWALK" (e o reprodutor, que ocupa o mesmo lugar) sem mexer nas três linhas. 4% da altura da tela por padrão. |
| Resolução de render | 100%, 75% ou 50%. Use 75% ou 50% em monitores 4K ou PCs mais fracos. |

O limite de FPS e a pausa (quando um app fica em tela cheia) seguem as configurações do
próprio Wallpaper Engine.

## Reprodutor (tocando agora)

Usa a integração de mídia do Wallpaper Engine, que lê o que aparece no controle de
mídia do Windows (Spotify, Tidal, navegador e outros). Se o reprodutor não aparecer,
confira se a integração de mídia está ligada nas configurações do Wallpaper Engine.

O visual segue o painel de controles da Exp I, numa faixa horizontal (capa e informações, com um espectro em barras diagonais ao lado): fundo escuro com desfoque, borda
fina, rótulos em Silkscreen, trilho de progresso e um espectro em barras diagonais: faixas a 45° que nascem nas bordas de cima e da direita do reprodutor, sem margem, e avançam pelo espaço ao lado das informações (grave no canto, agudo nas pontas), com preenchimento em dither oscilante (a mesma matriz de Bayer, mais densa na borda e rala na ponta).
A capa do álbum passa pelo mesmo dither do portfólio e cintila a cada 175 ms.

Todas as transições são em dither: o texto, o reprodutor, o relógio e a data entram
e saem ponto a ponto, na ordem da matriz de Bayer 4×4 (uma máscara CSS por nível da
matriz, de 0 a 16).

## Onda de dither

O motor é o mesmo do Playground do portfólio (`ganwalk/portifolio`,
`src/lib/dither.ts` e `src/lib/use-bayer-dither.ts`): matriz de Bayer 4×4 construída
recursivamente, luminância Rec. 601, viés de +42 no limiar e a fase da matriz
deslocada a cada 175 ms, o que dá a cintilação. Durante a passagem, o quadro inteiro
é copiado para um canvas em baixa resolução, os textos são redesenhados por cima,
e o resultado é ampliado sem suavização. A própria borda da onda também é dither:
a força da onda passa pelo mesmo limiar da matriz, então ela se dissolve em pontos
em vez de ter uma borda lisa. Fora da onda, nada disso roda.

## Interação

O icosaedro gira seguindo o mouse, sem precisar clicar e sem sair do lugar na grade:
vira de frente para o cursor e se inclina, com uma mola suave. A velocidade do
movimento ainda vira giro (com inércia), e um movimento rápido na horizontal faz a
forma inflar, como o "arranhar" da música no site. A intensidade fica em "Icosaedro
gira seguindo o mouse" (0 desliga, 3 é o máximo).

## Informações do PC (sem música)

Quando nenhuma música está tocando, o lugar das três linhas mostra processador,
memória, espaço livre dos discos e há quanto tempo o PC está ligado, com barras de
uso em dither. A temperatura da CPU e a da GPU aparecem em duas barras verticais
ao lado da grade do icosaedro (CPU à esquerda, GPU à direita), terminando acima do "GANWALK", cheias de
baixo para cima entre 30 °C e 100 °C; acima de 80 °C a barra fica mostarda. Quando a
música começa, tudo isso sai e as linhas voltam. A troca é em dither.

### Temperaturas

O Windows não entrega a temperatura da CPU de forma confiável, então o script tenta,
nesta ordem:

1. **LibreHardwareMonitor** (gratuito, recomendado): se ele estiver aberto, o script
   lê os sensores de CPU e GPU de qualquer marca. Ele precisa rodar como administrador
   para ler os sensores; dá para deixá-lo iniciar com o Windows e minimizado nas
   opções dele. O OpenHardwareMonitor também funciona.
2. **GPU NVIDIA:** sem o LibreHardwareMonitor, a temperatura da GPU vem do
   `nvidia-smi`, que já vem com o driver.
3. **CPU, último recurso:** a zona térmica do Windows, que costuma exigir administrador
   e nem sempre reflete a CPU de verdade.

Se uma das temperaturas não estiver disponível, a barra dela simplesmente não aparece.

Um wallpaper web não tem acesso ao disco, à memória nem ao processador, então quem
lê esses dados é um script pequeno do Windows que vem na pasta `stats/`:

1. Dê dois cliques em `stats/iniciar.cmd`. Ele roda o `ganwalk-stats.ps1` escondido,
   sem janela.
2. Para rodar sempre que o PC ligar: aperte Win+R, digite `shell:startup`, dê Enter e
   coloque ali um atalho para o `iniciar.cmd`.
3. Para parar: encerre o processo "Windows PowerShell" no Gerenciador de Tarefas.

**Se o painel não aparecer:**

1. Abra `http://localhost:7457/stats` no navegador. Se aparecer um texto com
   números (`{"cpu":...}`), o script está rodando. Se der erro de conexão, ele não está.
2. Rode `stats/testar.cmd`: ele abre o script com janela, mostrando qualquer erro.
3. No painel do Wallpaper Engine, ligue "Diagnóstico do script": o canto de cima
   mostra o que o wallpaper está recebendo (ou por que não está).

O script só responde dentro do próprio PC (`http://localhost:7457/stats`), recusa
pedidos vindos de sites abertos no navegador e não envia nome do computador nem do
usuário, só os números do painel. Se a porta 7457 estiver ocupada, rode o script com
`-Port` e outro número e ajuste "Porta do script de informações" no painel do
Wallpaper Engine. Sem o script rodando, nada muda: as três linhas ficam sempre no lugar.

## Arquivos

```
wallpaper-exp1/
├── index.html     # a cena + leitura do áudio do sistema + propriedades
├── project.json   # manifesto do Wallpaper Engine (tipo web, áudio ligado, propriedades)
├── preview.jpg    # miniatura mostrada no Wallpaper Engine / Workshop
├── stats/         # script do Windows que entrega as informações do PC ao wallpaper
├── lib/           # Three.js r128 + EffectComposer/UnrealBloomPass
└── fonts/         # Astloch Bold, Inter e Silkscreen (SIL OFL, ver fonts/OFL-*.txt)
```
