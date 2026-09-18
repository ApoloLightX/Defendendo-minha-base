# Aetherfall Defense · Android / Godot

Projeto nativo em Godot 4.5.1 para Android em modo paisagem, usando o renderizador Compatibility e input de toque. O campo é desenhado por código para manter uma linguagem visual consistente, baixa dependência de assets e boa legibilidade em ondas grandes.

## Executar no editor

1. Abra esta pasta no Godot 4.5.1.
2. Execute `scenes/Main.tscn` ou pressione Run Project.
3. Para testar o fluxo completo no editor, use a build de desenvolvimento: o botão `DEV` do combate expõe ouro, pular onda, limpar inimigos e invocar boss.

## Exportar APK

1. Instale o export template Android do Godot 4.5.1.
2. Configure o Android SDK/JDK em Editor → Manage Export Templates / Editor Settings.
3. Em Project → Export, adicione Android, mantenha `arm64-v8a` e `armeabi-v7a` ativos e exporte como APK.
4. O projeto já está configurado para 1280×720, paisagem, Compatibility, filtro nearest e sem permissão de internet.

O runtime desta sessão não possui o executável do Godot nem o Android SDK, então o APK binário precisa ser gerado no editor/CI Godot. A estrutura, cena principal e configurações de exportação estão prontas para essa etapa.

## Organização

- `scripts/main.gd`: composição das cenas e navegação entre menu, mapa e combate.
- `scripts/data/game_data.gd`: mundos, fases, torres, especializações, inimigos, heróis, bosses, missões e loja.
- `scripts/game/battle_controller.gd`: ondas, IA, path, combate, projéteis, habilidades, bosses, partículas e feedback.
- `scripts/ui/main_ui.gd`: HUD touch, telas, loja, progressão, resultado, configurações e ferramentas DEV.
- `scripts/visual/backdrop.gd`: cenário animado de menu/mapa.
- `scripts/core/save_manager.gd`: save automático em `user://aetherfall_save.json`.
- `scripts/core/audio_manager.gd`: música procedural, SFX e mixagem.
