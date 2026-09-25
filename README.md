# PromptLint

A Swift CLI that analyzes a prompt before you send it to an LLM and points out where you can cut tokens without losing meaning — filler phrases, repeated instructions, badly formatted JSON, and context resent for no reason between turns of a conversation.

Runs 100% locally by default: no API calls, no API key required.

## Build

```bash
git clone https://github.com/Luan-Aiezza/PromptLint.git
cd PromptLint
swift build
```

Tests (34, covering the parser, every rule, token counting, and `--fix`):

```bash
swift test
```

## Basic usage

```bash
swift run promptlint check path/to/file.md
```

With no argument, or with `-`, it reads from standard input:

```bash
echo "I would like you to please review this." | swift run promptlint
```

Typical output:

```
Current tokens (estimate): 294 (~US$ 0.000588 on claude-sonnet-5)
Potential savings: 55 tokens (-18%) (~US$ 0.000110 on claude-sonnet-5)

⚠ Lines 1-1 [filler-phrase]
   Filler phrase: "I would like you to please" → suggestion: "please"
   → suggestion: please

⚠ Lines 7-25 [whitespace-json] [auto-fix available: --fix]
   JSON block with unnecessary indentation/whitespace.
   → suggestion: {"key":"value"}
```

## Implemented rules

| Rule | What it detects | Fixed by `--fix`? |
|---|---|---|
| `filler-phrase` | Common filler phrases in EN/PT-BR ("I would like you to please...") | No — manual suggestion only, since rewording could change meaning |
| `redundant-instruction` | Paragraphs with a repeated request (Jaccard similarity) in the same prompt | No |
| `whitespace-json` | A ` ```json ` block with unnecessary indentation/whitespace | Yes |
| `duplicate-context` | A block identical to one already sent in the previous turn of the same session (`--session`) | Yes |

The token count shown in findings is always an **offline estimate** (not Anthropic's real tokenizer, which isn't public). For the exact number in the report, use `--exact`.

## Flags

```
swift run promptlint check <file|-> [options]
```

| Flag | Effect |
|---|---|
| `--exact` | Uses the real token count via the API (`POST /v1/messages/count_tokens`) instead of the offline estimate |
| `--model <id>` | Model used by `--exact` and to compute the USD cost (default: `claude-sonnet-5`) |
| `--api-key <key>` | Anthropic API key. If omitted, falls back to the `ANTHROPIC_API_KEY` environment variable |
| `--session <id>` | Enables the `duplicate-context` rule, comparing against the last prompt saved for that session |
| `--fix` | Automatically applies the safe fixes (`whitespace-json`, `duplicate-context`) |
| `--json` | Emits the report as JSON (for scripts/CI) instead of human-readable text |

### Exact token counting via the API

```bash
export ANTHROPIC_API_KEY="your_key_here"
swift run promptlint check file.md --exact
```
or passing the key directly, without an environment variable:
```bash
swift run promptlint check file.md --exact --api-key "your_key_here"
```

Models supported in the built-in pricing table (`PricingTable`): `claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4-5`. No `ANTHROPIC_API_KEY`? Create one at [console.anthropic.com](https://console.anthropic.com) → Settings → API Keys (a separate account from a Claude Pro/Max chat subscription).

### Chat session (duplicate context across turns)

```bash
swift run promptlint check turn1.md --session my-conversation
swift run promptlint check turn2.md --session my-conversation
```

If `turn2.md` resends a block identical to one in `turn1.md` (e.g. the same system header), the second command flags it as `duplicate-context`. Each session's last prompt is saved to `~/.promptlint/sessions/<id>.txt`.

### Applying automatic fixes

```bash
swift run promptlint check file.md --fix
```

Rewrites the file in place, compacting JSON and removing duplicate context blocks. If the input is stdin (no file), the fixed text is printed to the terminal instead of being written anywhere.

For scripting, there's also a dedicated subcommand that applies the safe fixes and prints *only* the resulting text, with no report:

```bash
cat file.md | swift run promptlint fix -
```

### JSON output

```bash
swift run promptlint check file.md --json
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

Combine `--json` with `--fix`: if there's no file to write to (stdin), the fixed text comes back in the `fix.fixedText` field.

## Shell integration (optional)

This isn't part of the package — it's a `zsh` function you can add to your own `~/.zshrc` to have PromptLint automatically review one-shot prompts before they reach the `claude` CLI (Claude Code). It's not something you install by running a script; you copy the block below and adjust one path.

```bash
git clone https://github.com/Luan-Aiezza/PromptLint.git
cd PromptLint
swift build -c release   # a release build starts faster than `swift run` on every call
```

Then add this to `~/.zshrc`, replacing `/path/to/PromptLint` with wherever you cloned the repo:

```bash
# >>> PromptLint wrapper for the `claude` command >>>
# Intercepts only one-shot invocations (`claude -p "..."` or piped stdin)
# to run the prompt through PromptLint before actually sending it.
# Interactive sessions (running `claude` without -p) pass straight through,
# no interception — there's no safe way to "lint" a REPL this way. To
# disable: comment out/delete this block and run `source ~/.zshrc`.
claude() {
  local promptlint_bin="/path/to/PromptLint/.build/release/promptlint"
  [[ -x "$promptlint_bin" ]] || promptlint_bin="/path/to/PromptLint/.build/debug/promptlint"

  if [[ ! -x "$promptlint_bin" ]]; then
    print -u2 -- "⚠️  promptlint not found at $promptlint_bin — calling claude directly, without linting."
    command claude "$@"
    return $?
  fi

  local -a args=("$@")
  local prompt_index=-1
  local i
  for ((i = 1; i <= $#args; i++)); do
    if [[ "${args[i]}" == "-p" || "${args[i]}" == "--print" ]]; then
      if (( i + 1 <= $#args )); then
        prompt_index=$((i + 1))
      fi
      break
    fi
  done

  local prompt_text="" from_stdin=0
  if (( prompt_index > 0 )); then
    prompt_text="${args[prompt_index]}"
  elif [[ ! -t 0 ]]; then
    prompt_text="$(cat)"
    from_stdin=1
  fi

  if [[ -z "$prompt_text" ]]; then
    command claude "$@"
    return $?
  fi

  local report
  report="$("$promptlint_bin" check - <<< "$prompt_text")"

  if [[ "$report" == *"No issues found."* ]]; then
    if (( from_stdin )); then
      print -r -- "$prompt_text" | command claude "${args[@]}"
    else
      command claude "${args[@]}"
    fi
    return $?
  fi

  print -- "── PromptLint ──"
  print -- "$report"
  print -- "────────────────"
  print -n -- "Send anyway? [Enter]=yes  f=auto-fix  c=cancel: "

  local answer
  read -r answer < /dev/tty

  case "$answer" in
    f|F)
      prompt_text="$("$promptlint_bin" fix - <<< "$prompt_text")"
      print -- "(prompt automatically fixed before sending)"
      ;;
    c|C)
      print -- "Cancelled."
      return 1
      ;;
  esac

  if (( prompt_index > 0 )); then
    args[prompt_index]="$prompt_text"
    command claude "${args[@]}"
  else
    print -r -- "$prompt_text" | command claude "${args[@]}"
  fi
}
# <<< PromptLint wrapper for the `claude` command <<<
```

Reload your shell (`source ~/.zshrc`) and it's active:

```bash
claude -p "I would like you to please review this."
```
A clean prompt passes straight through with no prompt. One with findings shows the report and asks `[Enter]=yes  f=auto-fix  c=cancel`. If the `promptlint` binary can't be found at the configured path, it warns on stderr and falls back to calling `claude` directly — it never silently blocks your normal usage.

**Known limitation:** since this reads confirmation from `/dev/tty`, it needs a real interactive terminal — it won't work unattended inside a script or CI pipeline (which is intentional: an automated pipeline shouldn't block waiting for a keypress).

## Known limitations

- `redundant-instruction` uses lexical similarity (Jaccard) — it catches repetition with similar wording, not paraphrasing with entirely different words.
- `duplicate-context` compares blocks by exact text equality, not similarity.
- The offline token estimate is an approximation; use `--exact` for exact numbers.
- `SafeFix` (the engine behind `--fix`) edits raw text line by line, and doesn't follow a per-rule `AutoFixer` protocol — this works fine for the current cases, but is less extensible if a future rule needs a fix more complex than replacing/removing lines.

## Project structure

```
Sources/
├── PLCore/              library (parsing, rules, token counting, sessions, pricing, fixing)
└── promptlint/          CLI (ArgumentParser)
Tests/PLCoreTests/       34 unit tests
```
