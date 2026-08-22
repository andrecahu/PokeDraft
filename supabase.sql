-- ═══════════════════════════════════════════════════════════════════════════
-- PokeDraft — estrutura do banco
--
-- Cole TUDO isso no SQL Editor do Supabase e clique em RUN. Roda de uma vez só.
-- Pode rodar de novo quantas vezes quiser: ele apaga e recria.
-- ═══════════════════════════════════════════════════════════════════════════

drop table if exists acoes cascade;
drop table if exists participantes cascade;
drop table if exists salas cascade;

-- ── Sala: config do draft + estado atual ───────────────────────────────────
create table salas (
  codigo     text primary key,
  config     jsonb       not null,
  estado     jsonb       not null,
  versao     int         not null default 0,
  criado     timestamptz not null default now(),
  atualizado timestamptz not null default now()
);

-- ── Quem joga por qual time ────────────────────────────────────────────────
-- A chave primária (sala, time_idx) é o que impede duas pessoas de pegarem o
-- mesmo time: a segunda tentativa simplesmente falha.
create table participantes (
  sala     text        not null references salas(codigo) on delete cascade,
  time_idx int         not null,
  token    uuid        not null default gen_random_uuid(),
  nome     text,
  entrou   timestamptz not null default now(),
  primary key (sala, time_idx)
);

-- ── Fila de pedidos dos convidados ─────────────────────────────────────────
-- Convidado insere aqui; o host lê, valida e aplica.
create table acoes (
  id      bigserial primary key,
  sala    text        not null references salas(codigo) on delete cascade,
  token   uuid        not null,
  payload jsonb       not null,
  criado  timestamptz not null default now()
);
create index acoes_sala_idx on acoes (sala, id);

-- ═══════════════════════════════════════════════════════════════════════════
-- PERMISSÕES
--
-- É um app entre amigos: quem tem o código da sala pode entrar e jogar.
-- O ponto sensível é o `token` de cada participante — é ele que prova
-- "eu sou o Time 2". Por isso a tabela `participantes` NÃO é lida direto:
-- só as funções abaixo tocam nela, e nenhuma delas devolve token de outro.
-- ═══════════════════════════════════════════════════════════════════════════
alter table salas         enable row level security;
alter table participantes enable row level security;
alter table acoes         enable row level security;

-- Sala: quem tem o código lê (é isso que permite assistir) e escreve.
create policy salas_ler    on salas for select using (true);
create policy salas_criar  on salas for insert with check (true);
create policy salas_editar on salas for update using (true);

-- Ações: qualquer um insere um pedido; o host lê pra processar.
create policy acoes_ler   on acoes for select using (true);
create policy acoes_criar on acoes for insert with check (true);

-- participantes fica SEM policy de propósito: ninguém acessa direto.

-- Entra num time e recebe o próprio token. Se o time já tiver dono, falha.
create or replace function entrar_time(p_sala text, p_time int, p_nome text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_token uuid;
begin
  insert into participantes (sala, time_idx, nome)
  values (p_sala, p_time, p_nome)
  returning token into v_token;
  return v_token;
end $$;

-- Entra na sala pegando automaticamente a primeira vaga livre.
-- O `for update` na sala serializa: dois entrando ao mesmo tempo não pegam
-- o mesmo índice. Teto de 16 jogadores.
create or replace function entrar_auto(p_sala text, p_nome text)
returns table (idx int, tok uuid)
language plpgsql security definer set search_path = public as $$
declare v_idx int; v_token uuid;
begin
  perform 1 from salas where codigo = p_sala for update;

  select min(g.i) into v_idx
    from generate_series(0, 15) as g(i)
   where not exists (
     select 1 from participantes p where p.sala = p_sala and p.time_idx = g.i
   );
  if v_idx is null then raise exception 'sala cheia'; end if;

  insert into participantes (sala, time_idx, nome)
  values (p_sala, v_idx, p_nome)
  returning token into v_token;

  return query select v_idx, v_token;
end $$;

-- Larga o time (precisa provar que era seu, com o token).
create or replace function sair_time(p_sala text, p_token uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from participantes where sala = p_sala and token = p_token;
end $$;

-- Lista pro lobby: quem está em qual time. Sem token no retorno.
create or replace function listar_times(p_sala text)
returns table (time_idx int, nome text)
language sql security definer set search_path = public as $$
  select time_idx, nome from participantes where sala = p_sala order by time_idx;
$$;

-- O host usa isso pra descobrir de quem veio um pedido.
-- Recebe o token e devolve só o índice do time — nunca o contrário.
create or replace function time_do_token(p_sala text, p_token uuid)
returns int language sql security definer set search_path = public as $$
  select time_idx from participantes where sala = p_sala and token = p_token;
$$;

-- Troca o nome de exibição sem perder o lugar no time.
create or replace function atualizar_nome(p_sala text, p_token uuid, p_nome text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update participantes set nome = p_nome where sala = p_sala and token = p_token;
end $$;

grant execute on function entrar_time(text, int, text)  to anon, authenticated;
grant execute on function entrar_auto(text, text)       to anon, authenticated;
grant execute on function atualizar_nome(text, uuid, text) to anon, authenticated;
grant execute on function sair_time(text, uuid)         to anon, authenticated;
grant execute on function listar_times(text)            to anon, authenticated;
grant execute on function time_do_token(text, uuid)     to anon, authenticated;

-- ── Realtime ───────────────────────────────────────────────────────────────
-- Sem isso ninguém vê a jogada do outro aparecer na tela.
alter publication supabase_realtime add table salas;
alter publication supabase_realtime add table acoes;
alter table salas replica identity full;

-- ── Limpeza automática ─────────────────────────────────────────────────────
-- Salas paradas há mais de 2 dias somem quando alguém cria uma nova, pra não
-- acumular lixo no plano gratuito.
create or replace function limpar_salas_antigas() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from salas where atualizado < now() - interval '2 days';
  return new;
end $$;

create trigger salas_limpeza
  after insert on salas
  execute function limpar_salas_antigas();
