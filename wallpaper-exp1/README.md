# GANWALK — Exp I como wallpaper (Wallpaper Engine)

A Exp I (Visualizer) do [site do GANWALK](https://ganwalk.github.io/2026/) transformada
num wallpaper web para o Wallpaper Engine. A cena é a mesma do `App1`: icosaedro em
wireframe, grade, três linhas de onda e bloom. A diferença é de onde vem o som: em vez
de tocar `calma.mp3`, o wallpaper reage **a qualquer som que o computador estiver
reproduzindo** (Spotify, YouTube, jogos…).

## Instalar

1. Copie esta pasta (`wallpaper-exp1/`) para o seu PC.
2. No Wallpaper Engine: **Abrir wallpaper → Abrir do arquivo** e escolha o `index.html`
   desta pasta. (Ou abra o Editor do Wallpaper Engine → **Criar wallpaper** → arraste o
   `index.html`.)
3. Toque qualquer música. Se a cena não reagir, confira nas **Configurações** do
   Wallpaper Engine o dispositivo de áudio usado para capturar o som do sistema (tem que
   ser a saída que você está ouvindo). Para arrastar o icosaedro, a interação com o mouse
   precisa estar ligada nas configurações.

Tudo roda localmente (Three.js r128 e a fonte Astloch estão em `lib/` e `fonts/`), então
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
| Sensibilidade ao som | Multiplica a reação ao áudio (0–3). |
| Ganho automático | Normaliza o volume. Desligue para que músicas baixas mexam menos. |
| Girar ao contrário | Equivalente visual do botão "reverso" do site. |
| Movimento no silêncio | Rotação lenta mesmo sem som. |
| Eco Profundo, Câmara Etérea, Oscilador de Realidades, Véu Sonoro, Distorção Cósmica | Os controles do site. Não mexem mais no áudio (o som é do sistema), mas dirigem a parte visual como antes: rastro e pulsação, bloom e rastro, giro em Z, apagar a grade, achatar a forma. |
| Brilho extra (bloom) | Bloom fixo somado ao da Câmara Etérea. |
| Mostrar icosaedro / grade / ondas / texto | Liga e desliga cada camada. |
| Texto, tamanho, opacidade, brilho neon | Personaliza o "GANWALK" do centro. |
| Resolução de render | 100%, 75% ou 50%. Use 75% ou 50% em monitores 4K ou PCs mais fracos. |

O limite de FPS e a pausa (quando um app fica em tela cheia) seguem as configurações do
próprio Wallpaper Engine.

## Interação

Arraste o icosaedro para girá-lo. Um arrasto rápido na horizontal faz a forma inflar,
como acontecia ao "arranhar" a música no site.

## Arquivos

```
wallpaper-exp1/
├── index.html     # a cena + leitura do áudio do sistema + propriedades
├── project.json   # manifesto do Wallpaper Engine (tipo web, áudio ligado, propriedades)
├── preview.jpg    # miniatura mostrada no Wallpaper Engine / Workshop
├── lib/           # Three.js r128 + EffectComposer/UnrealBloomPass
└── fonts/         # Astloch Bold (SIL OFL, ver fonts/OFL.txt)
```
