# CHRONOS: Academia do Infinito (MVP)

Jogo educacional 2D em Godot com combate em turnos baseado em desafios matemáticos.

## Conteúdo do MVP
- 3 classes jogáveis: **Lógico**, **Analista** e **Sintetizador**.
- 3 mundos completos: **Aritmético**, **Algébrico** e **Geométrico**.
- Progressão com XP, nível, atributos e árvore de habilidades (3 níveis por atributo).
- Campanha com final ao derrotar os 3 bosses.
- Pós-jogo com revisita dos mundos e dificuldade aumentada.

## Como executar
1. Abra a pasta no Godot 4.x.
2. Execute a cena principal (`scenes/main.tscn`) ou rode o projeto.

## Estrutura
- `scenes/`: cena principal e stubs para expansão modular.
- `scripts/main.gd`: lógica central de UI, combate, progressão e geração procedural de perguntas.
- `worlds/`, `assets/`, `design/`: reservados para expansão de conteúdo.
