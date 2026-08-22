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

## Passo a passo

### 1. Criar a conta no Supabase (~3 min)

1. Vá em **[supabase.com](https://supabase.com)** e crie uma conta (dá para entrar com GitHub).
2. Clique em **New project**.
3. Preencha:
   - **Name:** `pokedraft`
   - **Database Password:** gere uma e guarde (você não vai precisar dela no dia a dia)
   - **Region:** **South America (São Paulo)** — importante, é o que deixa o jogo responsivo no Brasil
4. Clique em **Create new project** e espere ~2 minutos enquanto ele provisiona.

### 2. Criar as tabelas (~1 min)

1. No menu lateral, abra **SQL Editor**.
2. Clique em **New query**.
3. Abra o arquivo **`supabase.sql`** deste projeto, copie **todo** o conteúdo e cole no editor.
4. Clique em **Run** (ou `Ctrl+Enter`).

Deve aparecer *Success. No rows returned*. É isso mesmo — o script cria tabelas, não devolve linhas.

### 3. Pegar as chaves (~1 min)

1. Menu lateral → **Project Settings** (a engrenagem) → **API**.
2. Copie dois valores:
   - **Project URL** — algo como `https://abcdefgh.supabase.co`
   - **anon / public** key — um texto longo começando com `eyJ...`

> ⚠️ **Cuidado com a Project URL.** A página da API mostra vários endereços. O certo é só o domínio:
>
> | | |
> |---|---|
> | ✅ certo | `https://abcdefgh.supabase.co` |
> | ❌ errado | `https://abcdefgh.supabase.co/rest/v1/` |
>
> Se colar o endereço com `/rest/v1`, o erro que aparece é *"Invalid path specified in request URL"*. O app corrige isso sozinho, mas melhor colar certo.

### 4. Preencher o `config.js`

Abra o arquivo `config.js` e cole os dois valores:

```js
window.POKEDRAFT_CONFIG = {
  SUPABASE_URL: 'https://abcdefgh.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...',
};
```

> A `anon key` é **pública de propósito** — ela vai no navegador de todo mundo que abrir o site. Não é segredo e não tem problema subir pro GitHub. Quem protege os dados são as regras definidas no `supabase.sql`.
>
> A chave que **nunca** pode sair do painel é a `service_role`. Não use ela aqui.

### 5. Testar na sua máquina

Na pasta do projeto:

```bash
python -m http.server 8791
```

Abra `http://localhost:8791`, vá na aba **Draft**, configure e clique em **🌐 Criar sala online**.

Para testar sozinho: copie o link do convite e abra numa **janela anônima**.

> Não adianta abrir duas abas normais: elas compartilham o mesmo armazenamento do navegador e o app vai achar que é a mesma pessoa. Janela anônima é o que separa as duas identidades.

### 6. Publicar pra galera acessar

**GitHub Pages** (grátis):

1. Crie um repositório no GitHub chamado `pokedraft`.
2. Suba os três arquivos: `index.html`, `config.js` e `supabase.sql`.
   ```bash
   git init
   git add index.html config.js supabase.sql README.md
   git commit -m "PokeDraft"
   git branch -M main
   git remote add origin https://github.com/SEU-USUARIO/pokedraft.git
   git push -u origin main
   ```
3. No repositório: **Settings → Pages**.
4. Em **Source**, escolha **Deploy from a branch**, branch `main`, pasta `/ (root)`. Salve.
5. Em ~1 minuto o site estará em `https://SEU-USUARIO.github.io/pokedraft/`.

**Alternativa sem git:** [netlify.com/drop](https://app.netlify.com/drop) — arraste a pasta inteira na página e pronto.

---

## Como jogar

A tela de Draft abre em **🌐 Online** (o padrão) e tem uma aba **🖥 Nesta tela** pra quando estiverem todos juntos no mesmo PC. No modo online não existem campos de nome de time — cada lado é a pessoa que entrou na vaga.

**Host:**
1. Aba **Draft** (já vem em Online) → configure picks, gerações, modo (Livre ou Arena), bans, inicial obrigatório e quais categorias de Pokémon entram
2. **🌐 Criar sala e convidar** → digite seu nome
3. **Copiar link do convite** e mandar no chat
4. Com 2 ou mais na sala, **▶ Iniciar Draft**

**Convidados:**
1. Abrem o link (ou usam *Entrar numa sala com código*)
2. Digitam **seu nome** na tela que aparece
3. Pronto — já estão na disputa, sem escolher time

**Não existe limite de jogadores** e você não define a quantidade antes: os times são exatamente quem estiver na sala na hora que o host apertar Iniciar. Quem entrar depois do início assiste.

Quem não quiser jogar clica em **👀 Assistir sem jogar** — e pode voltar com **🎮 Quero jogar** enquanto o draft não começou.

O nome é pedido **antes** de entrar na sala e fica salvo no navegador — nas próximas vezes já vem preenchido, é só dar Enter. Dentro do draft não existe "Time 1": cada lado é a pessoa que está jogando ali.

**Fora da sua vez você continua navegando.** A tela fica mais apagada pra deixar claro que não é sua vez, mas dá pra filtrar, buscar e abrir a ficha de qualquer Pokémon pra ir pensando no próximo pick. O botão de confirmar simplesmente não aparece — no lugar dele fica *"👀 Consultando — é a vez de Fulano"*.

**Clique em qualquer Pokémon já escolhido ou banido** para abrir a ficha completa (stats, fraquezas, golpes, passivas, evoluções, itens e uso no meta), a qualquer momento.

No fim do draft, cada time ganha um **🧩 Analisar no Comp** que joga aquele time no montador. De lá, **← Voltar ao draft** te devolve pra tela de resultado.

Durante o draft, a barra do topo mostra o código da sala, qual time é o seu e de quem é a vez. Quando não é sua vez, a área de escolha fica esmaecida e travada.

Se alguém der F5, volta para onde estava — o token fica salvo no navegador por sala.

---

## Problemas comuns

**"Supabase não configurado"**
O `config.js` está vazio ou não foi carregado. Confirme que ele está na mesma pasta do `index.html`.

**Criou a sala mas ninguém vê as jogadas**
Provavelmente o Realtime não foi ligado. Rode de novo a parte final do `supabase.sql` (a partir de `alter publication supabase_realtime`).

**"Sala não encontrada"**
O código expira: salas paradas há mais de 2 dias são apagadas quando alguém cria uma nova. É só criar outra.

**O projeto Supabase "pausou"**
No plano gratuito, projetos sem uso por ~7 dias entram em pausa. Entre no painel e clique em **Restore** — leva menos de um minuto. Se vocês jogam toda semana, isso nunca acontece.

**O draft travou no meio**
Provavelmente o host fechou a aba. Ele reabre o link e o draft continua de onde parou.

---

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | O app inteiro (HTML, CSS e JS num arquivo só) |
| `config.js` | Suas chaves do Supabase — o único arquivo que você edita |
| `supabase.sql` | Script que cria as tabelas e as permissões |

## Custo

Zero. GitHub Pages e o plano gratuito do Supabase cobrem folgado um grupo de amigos.
