# Importação no Roblox Studio

Este projeto foi montado como uma pipeline externa compatível com Roblox:

- `content/`: JSON editável de mapas, modelos, missões, inimigos, diálogos e balanceamento.
- `tools/build-content.ps1`: valida os JSONs e gera o módulo Luau consumido pelo jogo.
- `src/`: scripts Luau prontos para sincronizar no Roblox Studio via Rojo.
- `studio/BuildWorldInStudio.lua`: comando opcional para montar o mapa no Workspace em modo edição.

## Caminho recomendado com Rojo

1. No terminal, rode:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/build-content.ps1
   ```

2. Instale/abra o plugin Rojo no Roblox Studio.

3. Sirva o projeto a partir desta pasta:

   ```powershell
   rojo serve default.project.json
   ```

4. No Roblox Studio, conecte o plugin Rojo ao servidor local.

5. Pressione Play. O script `ServerScriptService/CivilizationWar/Main.server.lua` monta o mapa inicial, cria remotes, inicia recursos passivos, NPCs, missões e combate PvE.

## Montar o mapa em modo edição

Depois de sincronizar pelo Rojo, cole o conteúdo de `studio/BuildWorldInStudio.lua` na Command Bar do Studio. Isso chama o `WorldBuilder` e cria a pasta `Workspace/CivilizationWAR` com terreno, castelo, nós de recurso, acampamentos NPC, maravilha e NPCs de diálogo.

## Loop jogável atual

- O jogador começa com Castelo nível 1, recursos básicos e uma tropa pequena.
- Missões guiam a construção de fazenda, quartéis, academia e embaixada.
- A economia passiva roda por tick no servidor.
- Treinamento de tropas consome recursos.
- Ataques contra NPCs usam o resolvedor automático e retornam relatório.
- Diálogos de NPC aparecem por `ProximityPrompt`.

## Editando conteúdo

Altere qualquer JSON em `content/` e rode novamente:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-content.ps1
```

O arquivo `src/ReplicatedStorage/CivilizationWar/Shared/GeneratedContent.lua` será recriado. Esse arquivo é gerado; edite os JSONs, não ele.
