# CivilizationWAR para Roblox

## Documento de implementação, PRD, GDD e pacote de prompts de imagem

Versão: 1.0

Objetivo: transformar a referência de jogo de estratégia mobile em uma experiência Roblox simples, modular, visualmente próxima do estilo isométrico e viável tecnicamente.

Observação legal: este documento usa a lógica de design de jogos de estratégia como referência. Não se deve copiar nome, interface, ícones, arte, personagens, screenshots, marcas ou layout exato de outro jogo. A identidade visual precisa ser própria.

# 1. Decisão principal

Não crie o mundo inteiro primeiro. O caminho correto é criar uma fatia vertical jogável, com um reino inicial, uma pequena área de mapa mundial, alguns recursos, uma marcha de coleta e um combate PvE simples. Depois o mundo é expandido por dados e biomas.

A adaptação para Roblox deve aproveitar o avatar e a presença 3D, mas sem abandonar a lógica de estratégia isométrica. O jogador deve nascer fisicamente em uma sala de comando ou área interna do próprio reino. A partir dali, a câmera é controlada por script e alterna entre a visão Reino e a visão Mapa Mundial.

# 2. Como adaptar a perspectiva ao Roblox

No Roblox, o jogador normalmente nasce como avatar em um espaço 3D. Para esse projeto, isso não deve virar um RPG de terceira pessoa comum. O avatar deve existir como comandante do reino, mas a experiência principal deve ser estratégica.

Modelo recomendado:

- Visão Reino: área interna detalhada, com castelo, prédios, NPCs e produção. A câmera fica isométrica fixa ou semi fixa.
- Visão Mundo: mapa compartilhado em grade, com castelos de outros jogadores, recursos, acampamentos NPC, tropas em marcha e biomas. Essa visão pode ser uma UI 2.5D ou uma câmera elevada sobre um mapa físico simplificado.
- Avatar: usado no Reino como presença, tutorial, interação com NPC e sensação Roblox. No Mapa Mundial, o avatar pode ficar congelado/oculto enquanto a UI estratégica controla a navegação.

O ponto técnico mais importante é tratar o Mapa Mundial como dados persistentes, não como um gigantesco cenário carregado inteiro no Workspace. Cada castelo, recurso, marcha e inimigo existe como registro de dados. O cliente renderiza apenas a região visível.

# 3. PRD resumido e melhorado

Produto: CivilizationWAR, jogo Roblox de estratégia persistente com construção de reino, mapa mundial, coleta de recursos, tropas, pesquisa, civilizações, alianças e PvE/PvP progressivo.

Problema: jogos de estratégia mobile têm ciclo forte de retenção, mas são pouco naturais no Roblox quando copiados diretamente. É preciso manter o ciclo estratégico, porém com uma entrada simples, avatar, câmera controlada e ativos leves em PNG/2.5D.

Público inicial: jogadores Roblox que gostam de construir, evoluir base, disputar mapa e participar de clãs ou alianças.

Proposta: o jogador nasce como comandante em seu reino, evolui a cidade, escolhe civilização, envia marchas ao mapa mundial, coleta recursos, derrota acampamentos e se aproxima de alianças.

Requisitos P0:

- Login e criação automática de Reino.
- Câmera isométrica controlada por script.
- Castelo inicial, Fazenda, Serraria, Pedreira, Mina, Quartel e Academia.
- Recursos: comida, madeira, pedra, ferro, prata e ouro.
- Produção passiva e coleta manual.
- Mapa mundial pequeno com castelo do jogador, recursos e acampamentos NPC.
- Marcha de coleta e marcha de ataque PvE.
- Salvamento persistente do progresso.

Requisitos P1:

- Escolha de civilização após etapa do tutorial.
- Pesquisa tecnológica.
- Teleporte de castelo.
- Relatórios de batalha.
- Defesas básicas e hospital.

Requisitos P2:

- Alianças, ajuda de construção e ataques coordenados.
- Eventos de mundo.
- Relíquias/conselheiros.
- PvP controlado com escudo inicial.
- Monetização por cosméticos, passes e aceleração moderada.
# 4. GDD resumido

Loop principal: construir -> produzir -> pesquisar -> treinar -> explorar -> coletar/atacar -> receber recompensa -> evoluir castelo -> liberar novos sistemas.

O castelo é o eixo de progressão. A evolução do castelo libera níveis de prédios, tropas, mapa, civilização, pesquisa, teleporte e alianças. A escolha de civilização não deve acontecer no primeiro minuto. Ela deve ser uma recompensa narrativa após o jogador entender o ciclo básico.

Progressão sugerida:

- Castelo Nível 1: tutorial, coleta local, Fazenda e Serraria.
- Castelo Nível 2: Quartel, treino de infantaria e primeiro ataque NPC.
- Castelo Nível 3: Academia, primeira pesquisa e Pedreira.
- Castelo Nível 4: Mapa Mundial, marcha de coleta externa e acampamento de bandidos.
- Castelo Nível 5: escolha de civilização.
- Castelo Nível 6: fim do escudo inicial e abertura de teleporte.
- Castelo Nível 8: aliança.
- Castelo Nível 10: PvP limitado.
# 5. Visões do jogo

Visão Reino: é a tela interna do jogador. Ela deve ter prédios em PNG/2.5D ou 3D simples, com câmera isométrica. O jogador vê seu castelo, recursos, prédios, NPCs e botões. Essa visão pode ser individual, mesmo com outros jogadores no mesmo servidor.

Visão Mundo: mostra castelos de outros jogadores como ícones ou modelos simplificados. As marchas aparecem como marcadores animados. O jogador não anda com o avatar pelo mundo. Ele navega com câmera/arrasto/zoom, como em jogo de estratégia.

Transição: um botão alterna entre Reino e Mundo. Não precisa trocar de Place no MVP. Basta ocultar/mostrar camadas e mudar a câmera.

# 6. Sistemas técnicos

- **PlayerDataService:** Carrega e salva PlayerState, Reino, recursos, prédios, tropas, civilização e pesquisas.
- **KingdomService:** Controla prédios internos, upgrades, filas de construção, produção passiva e estado do castelo.
- **WorldMapService:** Mantém coordenadas de castelos, recursos, acampamentos NPC, biomas e eventos do mapa mundial.
- **MarchService:** Cria, atualiza e finaliza marchas de coleta, exploração, ataque NPC e ataque jogador.
- **CombatService:** Resolve batalhas por fórmula, counters de tropa, relatório e perdas.
- **CivilizationService:** Aplica bônus da civilização escolhida e trava a escolha após confirmação.
- **ResearchService:** Controla tecnologias, tempo, custo e bônus permanentes.
- **CameraController:** Alterna visão Reino, visão Mapa Mundial e foco em missões.
- **UIController:** Mostra recursos, botões, painéis, relatórios e navegação entre modos.
- **AssetRegistry:** Mapeia IDs Roblox de imagens e modelos para nomes lógicos usados pelo jogo.

# 7. Dados principais

PlayerState mínimo:

```lua
PlayerState = {
  userId = 0,
  kingdomId = "k_000001",
  castleLevel = 1,
  civilization = nil,
  resources = { food = 500, wood = 500, stone = 0, iron = 0, silver = 0, gold = 0 },
  buildings = { Castle = 1, Farm = 1, Sawmill = 1, Barracks = 0, Academy = 0 },
  troops = { Infantry = 0, Spearman = 0, Archer = 0, Cavalry = 0, Siege = 0 },
  research = {},
  worldPosition = { x = 12, y = 48 },
  shieldUntil = 0,
  activeMarches = {}
}
```

WorldCell mínimo:

```lua
WorldCell = {
  x = 12,
  y = 48,
  biome = "plains",
  occupantType = "playerCastle",
  occupantId = "k_000001",
  resourceNode = nil,
  npcCamp = nil,
  lastUpdated = os.time()
}
```

# 8. Construções

| Construção | Função | Descrição | Prioridade |
|---|---|---|---|
| Castelo | Centro de progressão | Define nível máximo dos demais prédios, libera sistemas, protege dados centrais da cidade. | MVP |
| Fazenda | Comida | Produz comida passiva e libera missões de coleta de alimento. | MVP |
| Serraria | Madeira | Produz madeira passiva e reduz gargalos iniciais de construção. | MVP |
| Pedreira | Pedra | Produz pedra para muralhas, castelo e torres. | MVP |
| Mina de ferro | Ferro | Produz ferro para tropas avançadas e cerco. | MVP |
| Quartel | Infantaria | Treina espadachins e lanceiros. | MVP |
| Campo de arqueiros | Arqueiros | Treina arqueiros e besteiros. | P1 |
| Estábulo | Cavalaria | Treina cavalaria e aumenta velocidade de marcha. | P1 |
| Oficina de cerco | Cerco | Treina aríetes e catapultas. | P2 |
| Academia | Pesquisa | Permite pesquisar economia, batalha, defesa e logística. | MVP |
| Armazém | Proteção | Protege parte dos recursos em caso de saque. | P1 |
| Hospital | Recuperação | Converte parte das perdas em feridos recuperáveis. | P1 |
| Muralha e torres | Defesa | Aumenta defesa passiva contra ataques. | P1 |
| Embaixada | Aliança | Habilita ajuda de aliados e proximidade de aliança. | P2 |
| Salão de Guerra | Ataques conjuntos | Permite rally e ataques coordenados. | P2 |
| Taverna | Recompensas | Missões diárias, baús e minijogos simples. | P2 |
| Museu de Relíquias | Bônus permanentes | Armazena artefatos que alteram estatísticas. | P2 |

# 9. Fases de implementação

| Fase | Nome | O que fazer | Critério de pronto |
|---|---|---|---|
| 0 | Fundação técnica | Criar projeto Rojo, estrutura de pastas, módulos Shared/Server/Client, RemoteEvents, DataStore de teste e câmera controlada. | Projeto abre no Roblox Studio, carrega UI inicial e salva dados básicos. |
| 1 | Fatia vertical do Reino | Criar sala de comando, câmera isométrica, castelo, fazenda, serraria, recursos e botões Construir/Evoluir. | Jogador entra, vê o reino, coleta produção, evolui castelo uma vez. |
| 2 | Pipeline de assets PNG | Criar manifest, prompts, geração automática, limpeza, aprovação e AssetRegistry. | 30 assets PNG importados e usados no Studio com nomes padronizados. |
| 3 | Economia e construção | Implementar filas, tempos, custos, produção offline simples e requisitos de prédio. | Construções levam tempo e recursos persistem entre sessões. |
| 4 | Mapa Mundial mínimo | Criar grade 64x64 ou 128x128, biomas, castelos, recursos, acampamentos NPC e câmera/overlay de mapa. | Jogador alterna entre Reino e Mundo e vê seu castelo no mapa. |
| 5 | Marchas e coleta | Enviar trabalhador/tropa para recurso, esperar tempo, retornar com recurso, bloquear marcha duplicada. | Marcha aparece no mapa e recompensa é recebida no retorno. |
| 6 | PvE de acampamentos | Criar batedores, acampamentos de bandidos, fórmula de combate e relatório. | Jogador ataca NPC, recebe relatório e recompensa. |
| 7 | Escolha de civilização | Liberar escolha após Castelo Nível 5 ou missão final do tutorial, com bônus e visual próprio. | Jogador escolhe civilização e recebe bônus aplicado. |
| 8 | Teleporte de castelo | Permitir mover coordenada do castelo para célula livre com item de teleporte. | Castelo muda de posição no mapa e mantém o mesmo Reino interno. |
| 9 | Aliança simples | Criar aliança, entrar, ajuda em construção e localização próxima por teleporte de aliança. | Jogadores de uma aliança aparecem próximos e conseguem ajudar. |
| 10 | PvP e eventos | Ataque a castelos, escudo inicial, proteção de recursos, eventos temporários e ranking. | Servidor tem loop competitivo básico com proteção anti abuso. |

# 10. Pipeline de imagens com IA e Codex

Codex deve funcionar como operador da fábrica de assets. Ele não cria a imagem sozinho. Ele lê o manifest, gera prompts, chama o modelo integrado de geração de imagens, salva PNGs, limpa, gera galeria de revisão e monta o AssetRegistry para Roblox.

Fluxo: manifest -> prompt builder -> geração -> limpeza -> revisão -> upload Roblox -> AssetRegistry.lua -> uso no jogo.

Manifest exemplo:

```json
{
  "id": "castle_lv01",
  "category": "building",
  "variants": 4,
  "size": "1024x1024",
  "transparent_background": true,
  "prompt": "Small beginner medieval stone castle with wooden scaffolding..."
}
```

# 11. Prompt mestre

Prompt base para quase todos os assets:

```text
isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI
```

Prompt negativo:

```text
no realistic photograph, no text, no letters, no logo, no watermark, no UI screenshot, no copied game interface, no messy background, no cropped object, no extra characters, no deformed perspective, no modern gun, no sci-fi unless requested
```

# 12. Pacote de prompts por asset

| Asset | Categoria | Prompt |
|---|---|---|
| castle_lv01 | building | Small beginner medieval stone castle with wooden scaffolding, simple walls, early kingdom stage, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| castle_lv02 | building | Improved medieval castle with higher stone walls, banners, small towers, prosperous kingdom stage, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| castle_lv03 | building | Grand fortified medieval citadel with tall towers, golden banners, advanced kingdom stage, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| farm_lv01 | building | Small farm with crop field, wooden fence, tiny hut, early settlement resource production building, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| sawmill_lv01 | building | Medieval sawmill with stacked logs, wooden wheel, small work shed, resource production building, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| quarry_lv01 | building | Stone quarry with carved rocks, wooden crane, carts, early mining structure, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| iron_mine_lv01 | building | Iron mine entrance built into a rocky hill, wooden beams, ore carts, orange mineral highlights, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| barracks_lv01 | building | Small medieval barracks with training yard, weapon rack, red banners, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| archery_range_lv01 | building | Archery range with straw targets, wooden platform, bow racks, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| stable_lv01 | building | Cavalry stable with horses, hay, wooden roof, training pen, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| siege_workshop_lv01 | building | Siege workshop with unfinished catapult, gears, timber, workbench, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| academy_lv01 | building | Small research academy with scrolls, blue roof, observatory detail, civilized medieval building, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| embassy_lv01 | building | Alliance embassy building with two banners, stone steps, diplomatic hall, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| warehouse_lv01 | building | Resource warehouse with crates, barrels, sacks and reinforced wooden door, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| hospital_lv01 | building | Medieval field hospital building with white cloth canopy, healer symbol, clean and friendly, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| watchtower_lv01 | building | Wooden watchtower with ladder, small roof, signal fire, defensive structure, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| wall_segment_lv01 | defense | Short stone wall segment with wooden reinforcements, medieval strategy game, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| city_gate_lv01 | defense | Small fortified city gate with wooden doors and stone arch, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| market_lv01 | building | Medieval market stall cluster with fabric awnings, crates, coins, friendly trade mood, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| tavern_lv01 | building | Cozy medieval tavern with warm lights, wooden sign without text, barrels, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| museum_relics_lv01 | building | Small relic museum with ancient columns, display pedestal, golden artifact glow, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| portal_trials_01 | event | Mystical stone portal with blue magical energy, ancient runes without readable text, PvE challenge entrance, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| tree_oak_01 | nature | Large stylized oak tree, lush green canopy, thick trunk, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| tree_pine_01 | nature | Tall stylized pine tree, dark green needles, mountain biome prop, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| tree_dead_01 | nature | Dead twisted tree for ruined battlefield biome, dramatic silhouette, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| rock_small_01 | nature | Small mossy rock cluster, forest map prop, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| rock_mountain_01 | nature | Large sharp mountain rock formation, gray stone, snow dust on top, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| river_straight_01 | terrain | Straight isometric river tile, clear blue water, grassy riverbanks, seamless edges, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| river_curve_01 | terrain | Curved isometric river tile, clear blue water, grassy riverbanks, seamless edges, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| road_straight_01 | terrain | Straight dirt road tile for medieval strategy map, clean edges, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| road_curve_01 | terrain | Curved dirt road tile for medieval strategy map, clean edges, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| bridge_wood_01 | terrain | Small wooden bridge crossing a river, medieval strategy map prop, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| wood_node_01 | resource | Collectable wood resource node, stacked logs and axe, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| food_node_01 | resource | Collectable food resource node, baskets of wheat, apples and sacks, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| stone_node_01 | resource | Collectable stone resource node, pile of cut stones and pickaxe, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| iron_node_01 | resource | Collectable iron resource node, dark ore stones with metallic shine, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| silver_chest_01 | reward | Small treasure chest with silver coins and faint sparkle, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| gold_relic_01 | reward | Ancient golden relic on small pedestal, magical glow, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| bandit_camp_lv01 | enemy | Small bandit camp with two tents, campfire, wooden stakes, no characters, enemy map objective, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| bandit_camp_lv03 | enemy | Fortified bandit camp with barricades, tents, watch post, enemy map objective, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| rebel_general_camp_01 | enemy | Elite rebel general camp with red banners, command tent, guard posts, boss map objective, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| wolf_den_01 | enemy | Wild wolf den with cave entrance, bones, forest rocks, PvE objective, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| ancient_ruins_01 | landmark | Ancient ruined temple with broken columns, vines, mysterious glowing stone, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| world_castle_icon_01 | world_icon | Miniature castle icon for world map, clear silhouette, top down isometric symbol, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| march_army_icon_01 | world_icon | Small marching army marker with banner and dust trail, world map icon, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| worker_gather_icon_01 | world_icon | Small worker gathering marker with backpack and tools, world map icon, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| infantry_t1_icon | troop_icon | Medieval infantry soldier icon with sword and shield, stylized, readable small size, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| spearman_t1_icon | troop_icon | Medieval spearman soldier icon with long spear and small shield, stylized, readable small size, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| archer_t1_icon | troop_icon | Medieval archer soldier icon with bow and hood, stylized, readable small size, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| cavalry_t1_icon | troop_icon | Medieval cavalry unit icon with horse and lance, stylized, readable small size, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| siege_t1_icon | troop_icon | Small wooden catapult unit icon, stylized, readable small size, isometric 3/4 top-down mobile strategy game asset, stylized medieval fantasy, hand-painted low-poly look, clean silhouette, soft ambient occlusion, warm sunlight, slightly exaggerated shapes, high readability at small size, centered object, transparent background, no text, no logo, no watermark, original design, not based on any existing game UI |
| resource_food_icon | ui_icon | Simple UI icon of wheat and bread for food resource, polished mobile game icon, transparent background, no text |
| resource_wood_icon | ui_icon | Simple UI icon of logs for wood resource, polished mobile game icon, transparent background, no text |
| resource_stone_icon | ui_icon | Simple UI icon of gray stones for stone resource, polished mobile game icon, transparent background, no text |
| resource_iron_icon | ui_icon | Simple UI icon of dark iron ore for iron resource, polished mobile game icon, transparent background, no text |
| resource_silver_icon | ui_icon | Simple UI icon of silver coin stack for silver resource, polished mobile game icon, transparent background, no text |
| resource_gold_icon | ui_icon | Simple UI icon of golden coin stack for premium currency, polished mobile game icon, transparent background, no text |
| button_upgrade | ui | Blue and gold fantasy strategy game upgrade button background, empty center, no text, transparent corners, 9 slice friendly |
| panel_dark_wood | ui | Dark translucent medieval wood and metal panel background for strategy game UI, no text, no icons, 9 slice friendly |

# 13. Organização de pastas

```text
CivilizationWAR/
  game-design/
    GDD.md
    PRD.md
    economy.md
    combat.md
    camera.md
  asset-pipeline/
    manifest/assets_manifest.json
    prompts/generated_prompts.json
    output/raw/
    output/cleaned/
    output/approved/
    tools/generate_images.py
    tools/clean_images.py
    tools/make_review_gallery.py
    tools/upload_to_roblox.py
  roblox/
    default.project.json
    src/client/
    src/server/
    src/shared/
      Config/
      Assets.lua
      Types.lua
```

# 14. Por onde começar agora

Comece pela fase 0 e fase 1. Não crie todos os biomas. Não gere 300 PNGs. Não implemente PvP. O primeiro objetivo é uma fatia vertical com castelo, produção, upgrade, mapa mundial pequeno e uma marcha.

Tarefa inicial para Codex:

```text
Crie a estrutura Rojo de um jogo Roblox chamado CivilizationWAR. Implemente um CameraController com câmera isométrica Scriptable, uma UI simples de recursos, um PlayerDataService com dados mockados, um KingdomService com Castelo, Fazenda e Serraria, e botões para coletar recursos e evoluir castelo. Não implemente PvP ainda. Use arquitetura modular e dados em tabelas Lua.
```

Depois disso, a segunda tarefa é criar o mapa mundial mínimo com grade 16x16, castelo do jogador, três recursos e um acampamento NPC.

# 15. Fontes consultadas

- Google Play, Reign of Empire: Civ. war: https://play.google.com/store/apps/details?hl=en&id=com.cle.roc
- App Store, Reign of Empires: War Conquest: https://apps.apple.com/br/app/reign-of-empires-war-conquest/id1372651865?l=en-GB
- BlueStacks, Building Guide: https://www.bluestacks.com/blog/game-guides/civilization-war-battle-strategy-war-game/cwbswg-building-guide-en.html
- BlueStacks, Power Guide: https://www.bluestacks.com/blog/game-guides/reign-of-empires/cwbswg-power-guide-en.html
- Roblox, Camera: https://create.roblox.com/docs/workspace/camera
- Roblox, Camera API: https://create.roblox.com/docs/reference/engine/classes/Camera
- Roblox, Assets: https://create.roblox.com/docs/projects/assets
- Roblox, ImageLabel: https://create.roblox.com/docs/reference/engine/classes/ImageLabel
- Roblox, Decal: https://create.roblox.com/docs/reference/engine/classes/Decal
- Roblox, Open Cloud Assets API: https://create.roblox.com/docs/cloud/guides/usage-assets
- Roblox, Data Stores: https://create.roblox.com/docs/cloud-services/data-stores
- Roblox, Memory Stores: https://create.roblox.com/docs/cloud-services/memory-stores
