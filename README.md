# CivilizationWAR for Roblox

Migração da compatibilidade para a iluminação de voxels
A Iluminação de compatibilidade está sendo aposentada, então sua experiência foi migrada da Iluminação de compatibilidade para a Iluminação de voxels.
Sua estética original foi combinada tanto quanto possível, mas você ainda pode ver pequenas diferenças nas luzes locais.
Encontre todos os detalhes no comunicado do DevForum.

Primeira base jogável de CivilizationWAR, derivada do PRD em `prd.md`, preparada para importação no Roblox Studio.

## O que já existe

- Projeto Rojo em `default.project.json`.
- Conteúdo-fonte em JSON: civilizações, edifícios, tropas, inimigos, missões, diálogos, Greatmen, tecnologias, prefabs e mapa inicial.
- Gerador externo `tools/build-content.ps1`, que transforma `content/` em `GeneratedContent.lua`.
- Importador/construtor de mundo em Luau (`WorldBuilder`) que monta o cenário com Parts, prefabs, NPCs, prompts e labels.
- Servidor com economia passiva, estado do jogador, upgrades, treinamento, pesquisa, exploração e combate automático PvE.
- Cliente com HUD simples para recursos, missão atual, tropas e comandos principais.

## Estrutura

```text
content/
  data/                 Balanceamento e narrativa em JSON
  maps/                 Blueprints de mapas
  models/               Blueprints de prefabs feitos com Parts
src/
  ReplicatedStorage/    Config, conteúdo gerado e módulos compartilhados
  ServerScriptService/  Main server e serviços
  StarterPlayer/        HUD e chamadas de remotes
tools/
  build-content.ps1     Pipeline JSON -> Luau
studio/
  BuildWorldInStudio.lua
docs/
  importacao_roblox_studio.md
```

## Gerar conteúdo

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-content.ps1
```

## Importar no Roblox Studio

Veja [docs/importacao_roblox_studio.md](docs/importacao_roblox_studio.md).

## Próximos marcos sugeridos

1. Persistência com DataStore e migração de versão de save.
2. UI de cidade com slots reais de construção.
3. Marchas com tempo de viagem no mapa.
4. Alianças, ajuda de construção e rally.
5. Sistema de Greatmen com fragmentos, cargos e risco de captura.
