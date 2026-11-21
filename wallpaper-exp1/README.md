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
| Disparar quando o grave bater forte | Além do intervalo, a onda sai na hora quando o grave dá um salto bem acima da média recente (bumbo forte, drop). A sensibilidade decide o tamanho do salto, e o tempo mínimo evita uma onda atrás da outra. |
| Intervalo, duração, largura | De quanto em quanto tempo a onda passa (10 s por padrão), quanto tempo leva para atravessar e a largura do anel. |
| Tamanho do pixel / Intensidade do retículo | O tamanho de cada ponto e quanto o fundo escuro vira pontilhado. |
| Cores do dither | "Duotone" usa as cores do tema. "Máscara de cor" é igual ao Playground do portfólio: cor original nos pontos acesos, preto no resto. |
| Origem da onda | Do icosaedro (padrão) ou, se preferir uma faixa reta, da esquerda, da direita, de cima ou na diagonal. |
| Mostrar a música tocando | Enquanto uma música toca no computador, a cada pulso de dither o "GANWALK" vira o reprodutor logo antes da onda sair do icosaedro, e volta logo depois que ela passa. Música nova também dispara um pulso. |
| Tempo do reprodutor após o pulso | Quanto o reprodutor fica na tela depois que a onda passa (0,6 s por padrão). |
| Tamanho do reprodutor / barra de progresso | Escala do reprodutor e a barra de progresso (só aparece se o player informar a posição). |
| Sensibilidade ao som | Multiplica a reação ao áudio (0–3). |
| Ganho automático | Normaliza o volume. Desligue para que músicas baixas mexam menos. |
| Girar ao contrário | Equivalente visual do botão "reverso" do site. |
| Movimento no silêncio | Rotação lenta mesmo sem som. |
| Eco Profundo, Câmara Etérea, Oscilador de Realidades, Véu Sonoro, Distorção Cósmica | Os controles do site. Não mexem mais no áudio (o som é do sistema), mas dirigem a parte visual como antes: rastro e pulsação, bloom e rastro, giro em Z, apagar a grade, achatar a forma. |
| Brilho extra (bloom) | Bloom fixo somado ao da Câmara Etérea. |
| Mostrar icosaedro / grade / ondas / texto | Liga e desliga cada camada. |
| Altura da barra de tarefas | As três linhas ficam no meio do vão entre o "GANWALK" (ou o reprodutor) e a barra de tarefas, de fora a fora na tela. Ajuste se a sua barra for maior, menor ou estiver oculta (0). |
| Texto, tamanho, opacidade, brilho neon | Personaliza o "GANWALK" do centro. |
| Descer o texto | Desce o "GANWALK" (e o reprodutor, que ocupa o mesmo lugar) sem mexer nas três linhas. 4% da altura da tela por padrão. |
| Resolução de render | 100%, 75% ou 50%. Use 75% ou 50% em monitores 4K ou PCs mais fracos. |

O limite de FPS e a pausa (quando um app fica em tela cheia) seguem as configurações do
próprio Wallpaper Engine.

## Reprodutor (tocando agora)

Usa a integração de mídia do Wallpaper Engine, que lê o que aparece no controle de
mídia do Windows (Spotify, Tidal, navegador e outros). Se o reprodutor não aparecer,
confira se a integração de mídia está ligada nas configurações do Wallpaper Engine.

O visual segue o painel de controles da Exp I: fundo escuro com desfoque, borda
fina, rótulos em Silkscreen, trilho de progresso e o mini canvas com as três ondas.
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

O icosaedro segue o mouse, sem precisar clicar: a velocidade do movimento vira giro
(com inércia) e a posição do cursor inclina a forma na direção dele. Um movimento
rápido na horizontal faz a forma inflar, como acontecia ao "arranhar" a música no
site. A intensidade fica em "Icosaedro segue o mouse" (0 desliga).

## Arquivos

```
wallpaper-exp1/
├── index.html     # a cena + leitura do áudio do sistema + propriedades
├── project.json   # manifesto do Wallpaper Engine (tipo web, áudio ligado, propriedades)
├── preview.jpg    # miniatura mostrada no Wallpaper Engine / Workshop
├── lib/           # Three.js r128 + EffectComposer/UnrealBloomPass
└── fonts/         # Astloch Bold, Inter e Silkscreen (SIL OFL, ver fonts/OFL-*.txt)
```
