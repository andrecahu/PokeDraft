# PokeDraft

Draft de Pokémon estilo LoL — agora com **salas online**, cada pessoa no próprio computador.

O app continua funcionando 100% offline numa tela só. A parte online é opcional: se você não configurar o Supabase, o botão "Criar sala" apenas avisa que falta configurar e todo o resto segue normal.

---

## Como funciona a parte online

O navegador do **host** continua sendo o dono da lógica do draft. O Supabase serve como um quadro compartilhado:

```
Convidado clica em "pickar Garchomp"
   └→ grava um pedido na tabela `acoes`
        └→ host recebe, confere se é a vez dele e se a jogada é legal
             └→ host aplica e publica o estado novo
                  └→ todo mundo re-renderiza
```

Consequências que valem saber de antemão:

- **As regras da partida ficam travadas.** O que vale de lendário, pseudo-lendário, paradox e Ultra Beast é definido por quem cria a sala. Durante o draft esses filtros aparecem só para consulta, com um cadeado — ninguém muda no meio do jogo.
- **O host precisa manter a aba aberta.** Se fechar, o draft congela até ele voltar. O estado não se perde — está salvo no banco — mas ninguém consegue jogar enquanto ele estiver fora.
- Quem entra na sala **sem pegar um time** vira espectador: vê tudo, não joga.
- Ninguém consegue pickar fora da vez. Os controles ficam bloqueados, e mesmo que alguém force pelo console, o host recusa.

---
