# PromptLint

CLI em Swift que analisa um prompt antes de você mandar pra uma IA e aponta onde dá pra cortar tokens sem perder o sentido — frases de enchimento, instruções repetidas, JSON mal formatado e contexto reenviado à toa entre turnos de uma conversa.

Feito 100% local: por padrão não faz nenhuma chamada de API, nem precisa de chave.

## Build

```bash
cd ~/Documents/PromptLint
swift build
```

Os testes (34, cobrindo parser, cada regra, contagem de tokens e o `--fix`):

```bash
swift test
```

## Uso básico

```bash
swift run promptlint check caminho/do/arquivo.md
```

Sem argumento, ou com `-`, lê da entrada padrão:

```bash
echo "Eu gostaria que você pudesse revisar isso." | swift run promptlint
```

Saída típica:

```
Tokens atuais (estimativa): 294 (~US$ 0.000588 em claude-sonnet-5)
Economia potencial: 55 tokens (-18%) (~US$ 0.000110 em claude-sonnet-5)

⚠ Linhas 1-1 [filler-phrase]
   Frase de enchimento: "Eu gostaria que você pudesse" → sugestão: "faça"
   → sugestão: faça

⚠ Linhas 7-25 [whitespace-json] [correção automática disponível: --fix]
   Bloco JSON com indentação/espaços desnecessários.
   → sugestão: {"chave":"valor"}
```

## Regras implementadas

| Regra | O que detecta | Corrige com `--fix`? |
|---|---|---|
| `filler-phrase` | Frases de enchimento comuns em PT-BR/EN ("eu gostaria que você pudesse...") | Não — sugestão manual, trocar palavras pode mudar o sentido |
| `redundant-instruction` | Parágrafos com pedido repetido (similaridade de Jaccard) no mesmo prompt | Não |
| `whitespace-json` | Bloco ` ```json ` com indentação/espaços desnecessários | Sim |
| `duplicate-context` | Bloco idêntico a um já enviado no turno anterior da mesma sessão (`--session`) | Sim |

A contagem de tokens usada nos achados é sempre uma **estimativa offline** (não é o tokenizer real da Anthropic, que não é público). Para o número exato do relatório, use `--exact`.

## Flags

```
swift run promptlint check <arquivo|-> [opções]
```

| Flag | Efeito |
|---|---|
| `--exact` | Usa a contagem real via API (`POST /v1/messages/count_tokens`) em vez da estimativa offline |
| `--model <id>` | Modelo usado por `--exact` e para calcular o custo em USD (padrão: `claude-sonnet-5`) |
| `--api-key <chave>` | Chave da API Anthropic. Se omitida, usa a variável de ambiente `ANTHROPIC_API_KEY` |
| `--session <id>` | Ativa a regra `duplicate-context`, comparando com o último prompt salvo dessa sessão |
| `--fix` | Aplica automaticamente as correções seguras (`whitespace-json`, `duplicate-context`) |
| `--json` | Emite o relatório em JSON (para scripts/CI) em vez de texto legível |

### Contagem exata via API

```bash
export ANTHROPIC_API_KEY="sua_chave_aqui"
swift run promptlint check arquivo.md --exact
```
ou passando a chave direto, sem variável de ambiente:
```bash
swift run promptlint check arquivo.md --exact --api-key "sua_chave_aqui"
```

Modelos suportados na tabela de preço interna (`PricingTable`): `claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4-5`. Sem `ANTHROPIC_API_KEY`? Crie uma em [console.anthropic.com](https://console.anthropic.com) → Settings → API Keys (conta separada de uma assinatura de chat Claude Pro/Max).

### Sessão de chat (contexto duplicado entre turnos)

```bash
swift run promptlint check turno1.md --session minha-conversa
swift run promptlint check turno2.md --session minha-conversa
```

Se `turno2.md` reenviar um bloco idêntico ao de `turno1.md` (ex: o mesmo cabeçalho de sistema), o segundo comando aponta isso como `duplicate-context`. O último prompt de cada sessão fica salvo em `~/.promptlint/sessions/<id>.txt`.

### Aplicando correções automáticas

```bash
swift run promptlint check arquivo.md --fix
```

Reescreve o próprio arquivo, compactando JSON e removendo blocos de contexto duplicado. Se a entrada for stdin (sem arquivo), o texto corrigido é impresso no terminal em vez de gravado.

### Saída em JSON

```bash
swift run promptlint check arquivo.md --json
```

```json
{
  "model": "claude-sonnet-5",
  "originalTokens": 294,
  "originalCostUSD": 0.000588,
  "potentialSavings": 55,
  "potentialSavingsUSD": 0.00011,
  "findings": [
    { "ruleID": "whitespace-json", "startLine": 7, "endLine": 25, "autoFixable": true, "...": "..." }
  ],
  "fix": null
}
```

Combine `--json` com `--fix`: se não houver arquivo pra gravar (stdin), o texto corrigido vem no campo `fix.fixedText`.

## Limitações conhecidas

- `redundant-instruction` usa similaridade léxica (Jaccard) — pega repetição com vocabulário parecido, não paráfrase com palavras totalmente diferentes.
- `duplicate-context` compara blocos por igualdade exata de texto, não por similaridade.
- A estimativa offline de tokens é uma aproximação; para números exatos, use `--exact`.
- `SafeFix` (o motor por trás do `--fix`) edita o texto por linha diretamente, e não segue um protocolo `AutoFixer` por regra — funciona bem para os casos atuais, mas é menos extensível se uma futura regra precisar de uma correção mais complexa que substituir/remover linhas.

## Estrutura do projeto

```
Sources/
├── PLCore/              biblioteca (parsing, regras, contagem de tokens, sessão, preço, fix)
└── promptlint/          CLI (ArgumentParser)
Tests/PLCoreTests/       34 testes unitários
```
