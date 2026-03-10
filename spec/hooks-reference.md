# How Claude Code Hooks Work

*Reference for Phase 2 design and Phase 3 implementation. Compiled from official docs and research, March 2026.*

---

## What Hooks Are

Hooks are user-defined handlers (shell commands, HTTP endpoints, LLM prompts, or subagents) that fire automatically at specific points in Claude Code's lifecycle. They provide **deterministic** control — they run regardless of what Claude thinks is relevant. This is their core value: hooks enforce outcomes; instructions govern behavior.

Configuration lives in `settings.json` (global: `~/.claude/settings.json`, project: `.claude/settings.json`).

---

## Complete Event Reference (18 events)

| Event | When it fires | Blocking | Matcher filters on |
|---|---|---|---|
| `SessionStart` | Session begins or resumes | No | `startup`, `resume`, `clear`, `compact` |
| `UserPromptSubmit` | User submits a prompt, before Claude processes it | Yes | *(no matcher — always fires)* |
| `PreToolUse` | Before any tool call executes | Yes | tool name |
| `PermissionRequest` | Permission dialog appears | Yes | tool name |
| `PostToolUse` | After a tool call succeeds | No* | tool name |
| `PostToolUseFailure` | After a tool call fails | No | tool name |
| `Notification` | Claude Code sends a notification | No | notification type (`permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`) |
| `SubagentStart` | Subagent spawned via Task tool | No | agent type |
| `SubagentStop` | Subagent finishes | Yes | agent type |
| `Stop` | Claude finishes a response turn | Yes | *(no matcher — always fires)* |
| `TeammateIdle` | Agent team teammate about to go idle | No | *(no matcher)* |
| `TaskCompleted` | Task being marked complete | No | *(no matcher)* |
| `InstructionsLoaded` | CLAUDE.md or rules/*.md file loaded into context | No | unknown — fires at session start and on lazy loads |
| `ConfigChange` | A config file changes during a session | Yes | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
| `WorktreeCreate` | Worktree being created | No | *(no matcher)* |
| `WorktreeRemove` | Worktree being removed | No | *(no matcher)* |
| `PreCompact` | Before context compaction runs | No | `manual`, `auto` |
| `SessionEnd` | Session terminates | No | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |

*PostToolUse cannot undo the action — the tool already ran.

**Blocking** means the hook can prevent the action from proceeding (via exit code or JSON decision). Non-blocking hooks run as side effects.

---

## How Hooks Communicate

### Input

Every hook receives a JSON blob on stdin. Common fields on all events:

```json
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse"
}
```

Event-specific additions:
- `PreToolUse` / `PostToolUse` — `tool_name`, `tool_input`, (PostToolUse also has `tool_response`)
- `UserPromptSubmit` — `prompt`
- `SessionStart` — `source` (`startup`, `resume`, `clear`, `compact`)
- `Stop` — `stop_hook_active` (boolean — see infinite loop pitfall below)

### Output — Exit Codes

| Exit code | Meaning |
|---|---|
| `0` | Proceed. For `SessionStart` and `UserPromptSubmit`, anything on stdout is injected into Claude's context. |
| `2` | Block the action. Write reason to stderr; Claude receives it as feedback and adjusts. |
| anything else | Proceed, but log the error. Claude never sees stderr. Silent failure. |

**Critical:** Exit 2 and JSON output are mutually exclusive. Claude Code ignores JSON when you exit 2.

### Output — Structured JSON (exit 0 + JSON to stdout)

More granular control than exit codes alone. Shape varies by event:

- `PreToolUse` — return `hookSpecificOutput.permissionDecision`: `"allow"`, `"deny"`, or `"ask"`, plus `permissionDecisionReason`
- `PostToolUse` / `Stop` — return top-level `decision: "block"`
- `UserPromptSubmit` — return `additionalContext: "..."` to inject text into Claude's context
- `PermissionRequest` — return `hookSpecificOutput.decision.behavior`

---

## Hook Types

| Type | What it does |
|---|---|
| `command` | Runs a shell command. Default and most common. |
| `http` | POSTs event JSON to an HTTP endpoint. Response body uses same JSON format as command hooks. HTTP status codes alone cannot block actions. |
| `prompt` | Single LLM call (Haiku by default). Returns `{"ok": true}` or `{"ok": false, "reason": "..."}`. Use when deterministic rules aren't enough but judgment is. |
| `agent` | Spawns a subagent with full tool access. Same ok/reason format. 60s default timeout, up to 50 turns. Use when you need to inspect files or run commands to verify a condition. |

---

## Matchers

Matchers are **case-sensitive regex patterns** that filter when a hook fires within its event type.

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "..." }]
    }
  ]
}
```

What each event matches on:

| Events | Matches on |
|---|---|
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` | tool name (`Bash`, `Edit`, `Write`, `mcp__server__tool`) |
| `SessionStart` | session source (`startup`, `resume`, `clear`, `compact`) |
| `SessionEnd` | termination reason |
| `Notification` | notification type |
| `SubagentStart`, `SubagentStop` | agent type |
| `PreCompact` | `manual` or `auto` |
| `ConfigChange` | config source |
| `UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove` | **no matcher support** — always fires |

Empty string matcher (`""`) matches all occurrences.

MCP tools: `mcp__<server>__<tool>` — match all tools from a server with `mcp__github__.*`.

---

## Critical Distinctions

### `Stop` vs `SessionEnd` — The Capture Hook Confusion

This distinction is the source of a confirmed failure mode in the current ecosystem.

- **`Stop`** — fires when Claude finishes **any response turn**. Runs repeatedly throughout a session. Blocking.
- **`SessionEnd`** — fires **once** when the session terminates. Non-blocking.

For writing `last-active.md` at session end: **`SessionEnd` is correct**. Using `Stop` writes after every response (expensive and noisy). Using event names that don't exist (`SessionStop`, `SessionCapture`) means the hook silently never fires.

### `SessionStart` with `compact` matcher — Critical for Long Sessions

`SessionStart` fires with `source: "compact"` when context compaction occurs mid-session. A hook with `matcher: "compact"` re-injects context specifically after compaction events. This is the primary mechanical tool for preventing context loss in long sessions.

### `UserPromptSubmit` vs `SessionStart` for Context Injection

- `SessionStart` — fires once per session start. Context injected at the beginning.
- `UserPromptSubmit` — fires on every prompt, before Claude processes it. `additionalContext` is injected fresh each turn.

`UserPromptSubmit` has near-100% injection reliability throughout a session. `SessionStart` context loses salience as the session grows. The tradeoff: `UserPromptSubmit` adds tokens on every turn — filter aggressively.

---

## What Hooks Can and Cannot Enforce

### Can enforce mechanically

- Inject compass.md at session start (`SessionStart` stdout)
- Block writes to protected files (`PreToolUse` + exit 2)
- Write session summary at termination (`SessionEnd`)
- Re-inject context after compaction (`SessionStart` with `compact` matcher)
- Validate note schema on write (`PostToolUse`)
- Block a tool call and explain why (`PreToolUse` + JSON deny)
- Force Claude to keep working until a condition is met (`Stop` + prompt/agent hook)
- Log all Bash commands (`PostToolUse` with `Bash` matcher)

### Cannot enforce mechanically

- "Check memory before doing archaeology" — no hook intercepts Claude's reasoning. `PreToolUse` can intercept a Read of a specific file, but not the intent to start investigation.
- "Capture the insight at the moment it occurs" — no hook fires on insight generation. Mid-session capture requires Claude to take a deliberate write action.
- "Detect manifest semantic drift" — no hook fires on "vault evolved." Can only detect path existence changes.

---

## Pitfalls and Failure Modes

### Shell profile contamination (silent JSON failure)

Hooks run in non-interactive shells that still source `~/.zshrc` / `~/.bashrc`. Unconditional `echo` statements in those files prepend text to hook JSON output, causing parse failures. Claude Code shows a JSON error; the hook does nothing.

Fix:
```bash
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"
fi
```

### Stop hook infinite loop

A `Stop` hook that returns `decision: "block"` causes Claude to keep working. If the hook always fires, Claude never stops. The hook must check `stop_hook_active`:

```bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of hook logic
```

### Case-sensitive matchers

`edit|write` won't match — it must be `Edit|Write`. Spaces around pipes also break matching. Failure is silent — the hook just doesn't fire.

### `PermissionRequest` doesn't fire in non-interactive mode

In headless / automated Claude Code (`-p` flag), `PermissionRequest` hooks don't fire. Use `PreToolUse` instead for automated permission decisions.

### Wrong event name = silent no-op

Event names are exact strings. `SessionStop`, `SessionCapture`, `OnStop`, `AfterSession` — none of these exist. The hook is registered but never fires. No error is shown.

### Over-injection degrades performance

Injecting large context on every `UserPromptSubmit` can trigger "lost in the middle" — Claude's attention to injected content decreases when surrounded by too much other context. Filter by relevance. Don't inject everything always.

### Manual settings file edits don't hot-reload

If you edit `settings.json` directly while Claude Code is running, the changes don't take effect until you open `/hooks` or restart the session. Hooks added via the `/hooks` menu take effect immediately.

---

## Configuration Scope

| Location | Scope | Shared |
|---|---|---|
| `~/.claude/settings.json` | All projects on this machine | No |
| `.claude/settings.json` | This project | Yes — can be committed |
| `.claude/settings.local.json` | This project | No — gitignored |
| Plugin `hooks/hooks.json` | When plugin is active | Yes — bundled with plugin |
| Skill/agent frontmatter | While skill/agent is active | Yes — in component file |

---

## Async Hooks

Add `"async": true` to a hook to run it without blocking Claude Code. Use for side effects (logging, backups, notifications) that shouldn't slow down the main flow. Async hooks cannot influence decisions — they cannot block or modify behavior.

---

## Security Note

Hook configs in `.claude/settings.json` committed to shared repos are a supply chain attack vector. A malicious repo can inject hook commands that execute when a user opens the project in Claude Code. CVE-2025-59536 (code injection via project load), CVE-2026-21852 (API key exfiltration). Anthropic added warning dialogs for untrusted hook configs; hardening ongoing. Review committed hook files before opening unfamiliar repos.

---

## Debugging

- Toggle verbose mode with `Ctrl+O` to see hook stdout/stderr in transcript
- Run `claude --debug` for full execution details including which hooks matched and their exit codes
- Test a hook manually: `echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh && echo $?`
- `/hooks` menu shows all registered hooks per event — if your hook isn't listed, the config isn't loading

---

*Sources: [Hooks reference](https://code.claude.com/docs/en/hooks), [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide), [Guaranteed context injection — DEV](https://dev.to/sasha_podles/claude-code-using-hooks-for-guaranteed-context-injection-2jg), [Complete lifecycle guide — claudefa.st](https://claudefa.st/blog/tools/hooks/hooks-guide)*
