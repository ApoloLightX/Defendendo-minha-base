# Aetherfall Defense — projeto recuperado

Projeto Godot 4.5.1 recuperado do APK visual 0.2.0 e integrado às correções de
gameplay de 17/09/2026. Este repositório passa a ser a base de continuidade.

## Abrir e testar

Abra `godot/project.godot` no Godot 4.5.1. Após importar os recursos:

```sh
XDG_DATA_HOME=/tmp/aetherfall-qa godot --headless --path godot --script res://tests/regression.gd
```

Os testes gravam progresso: use um perfil isolado, como no comando acima.

## Recuperação

Fonte: `aetherfall-defense-visual.apk`, versão 0.2.0, pacote
`com.apololightx.aetherfalldefense`. Oito scripts foram recuperados com GDRE
Tools 2.6.4. As imagens PNG foram extraídas das texturas compiladas pelo Godot,
preservando os pixels. Os SVGs vetoriais originais não são recuperáveis por esse
processo. Scripts recuperados podem não manter comentários e formatação.

## Correções integradas

- HUD sem sobreposição no cabeçalho e detalhes da torre no painel lateral.
- Campo com transformação de entrada correspondente, sem áreas mortas de construção.
- Meteoro, gelo e bombardeio com escolha de alvo e cancelamento sem gastar recarga.
- Movimento especial do herói substitui a ordem anterior.
- Ultimate de Lyra respeita pausa, velocidade e troca de batalha.
- Barras de progresso na altura correta, custos visíveis e rótulos em português.
- Intervalo entre ondas inicia a próxima onda automaticamente.
- Artes de heróis, torres, skins e terreno da 0.2.0 preservadas.

Validação: importação no Godot 4.5.1 sem erros; regressão headless com zero falhas.
Um aviso de objetos pendentes ao encerrar ainda precisa de investigação.
Não houve validação gráfica em aparelho nem medição de FPS nesta recuperação.

## Pendências

Este é um resgate da base, não uma versão final para apresentação empresarial.
Continuam pendentes o redesign de inimigos/chefes, animações e efeitos,
playtest de diversão e balanceamento, e revisão visual no Android.

A chave privada de assinatura e os presets Android não estavam no APK.
Não há garantia de instalar uma futura build sobre a anterior sem a chave
original. Não desinstale o jogo antes de preservar o progresso.

Não versionar APKs, caches, saves ou chaves privadas neste repositório.
