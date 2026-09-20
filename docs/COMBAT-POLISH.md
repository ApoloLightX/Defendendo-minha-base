# Combate: revisão de 20/09/2026

Esta revisão mantém a campanha e a economia existentes e trabalha na leitura das unidades e na correspondência entre efeitos e regras.

- Dez tipos de inimigos recebem silhuetas próprias, equipamentos e movimento articulado em `EnemyArt`. Chefes possuem cinco variantes regionais. A arte continua vetorial e desenhada em código; não é uma coleção de sprites finalizados.
- A caminhada acompanha velocidade e lentidão, para durante atordoamento e respeita o delta da simulação. Inimigos derrotados deixam uma animação breve, limitada pela quantidade de efeitos.
- `SpellArt` centraliza os raios de meteoro e gelo usados pela seleção, efeito e dano. O meteoro causa dano uma única vez, no instante em que a pedra chega ao solo. O gelo deixa de sugerir alcance maior que o real.
- Barras de vida aparecem em unidades feridas e chefes; escudos continuam visíveis quando ativos.

## Verificação

Executar com Godot 4.5.1, a partir da raiz:

```sh
godot --headless --path godot --script res://tests/regression.gd
godot --headless --path godot --script res://tests/combat_effects.gd
godot --path godot res://tests/combat_gallery.tscn
```

As regressões existentes passaram com zero falhas. Os testes novos verificam caminhada interrompida, dano sincronizado ao impacto, ausência de dano duplicado e expiração da animação de morte. A galeria executou sem erros em modo headless e inclui todos os tipos de inimigos, chefes e os dois feitiços. `git diff --check` passou.

Permanece um aviso de instâncias ObjectDB no encerramento dos testes. O ambiente não permitiu abrir um display gráfico; portanto não houve validação visual por captura nem teste em aparelho Android. Esta revisão não entrega um APK novo, não comprova 60 FPS e não encerra o trabalho de arte, balanceamento e usabilidade. A chave de assinatura original continua indisponível.
