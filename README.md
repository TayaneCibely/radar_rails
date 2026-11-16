# Radar

Dois bots num projeto só: um avisa de vagas de Ruby on Rails Júnior, o outro de editais de mestrado.

## Arquitetura

```
config/vagas.yml ───┐
                    ├─> Fontes ──> Filtro ──> Store ──────> Notificador
config/editais.yml ─┘   coletam    palavras   já foi visto?  Telegram ou terminal
```

Cada bot é um arquivo em `config/`. O fluxo (`lib/radar/pipeline.rb`) é o mesmo para todos.

| Peça | Onde | O que faz |
|---|---|---|
| Fonte | `lib/radar/sources/` | Busca dados e devolve uma lista de `Item` |
| Filtro | `lib/radar/filters/keyword.rb` | Mantém só o que casa com as palavras-chave |
| Store | `lib/radar/store.rb` | SQLite com o que já foi avisado |
| Notificador | `lib/radar/notifiers/` | Envia o aviso |

Fontes disponíveis: `github_issues`, `rss`, `json_api` (qualquer API que devolva uma lista em JSON) e `page_watch` (vigia links novos numa página).

Regras do filtro: `all_of` procura no anúncio inteiro, `headline_all_of` só no título e nas etiquetas, e `none_of` elimina pelo título.

## Rodar

Requer Ruby 3.1 ou mais novo.

```bash
bundle install
ruby bin/radar vagas --dry-run   # mostra no terminal, sem gravar nada
ruby bin/radar all               # roda todos os bots e grava o que foi visto
ruby bin/radar editais --seed    # marca tudo como visto, sem avisar
```

Testes:

```bash
ruby -Ilib -Itest test/filter_test.rb
ruby -Ilib -Itest test/pipeline_test.rb
ruby -Ilib -Itest test/sources_test.rb
```

## Telegram

1. No Telegram, converse com o `@BotFather`, envie `/newbot` e guarde o token.
2. Envie uma mensagem qualquer para o seu bot e abra `https://api.telegram.org/bot<TOKEN>/getUpdates` para achar o `chat.id`.
3. Defina as variáveis `TELEGRAM_BOT_TOKEN` e `TELEGRAM_CHAT_ID`.

Sem essas variáveis, os avisos saem no terminal.

## Agendar no GitHub Actions

Suba o projeto para um repositório e cadastre `TELEGRAM_BOT_TOKEN` e `TELEGRAM_CHAT_ID` em Settings → Secrets and variables → Actions. O workflow em `.github/workflows/radar.yml` roda três vezes ao dia e grava `data/radar.db` de volta no repositório.

## Estender

- **Nova fonte**: crie uma classe em `lib/radar/sources/` com um método `fetch` que devolve `Item`s e registre em `SOURCES` (`lib/radar.rb`).
- **Novo bot**: crie outro arquivo em `config/`.
