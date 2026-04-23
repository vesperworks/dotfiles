---
name: vw:index
description: |
  Generate a directory-level index.md summarizing a collection of Markdown
  files. Three-phase pipeline: (1) per-file summary caching with mtime-based
  invalidation, (2) context aggregation, (3) index generation. Domain-neutral;
  works in any project. Use when the user asks to "index a directory",
  "まとめを作って", "generate an overview of <dir>", or runs /vw:index explicitly.
disable-model-invocation: true
argument-hint: "<directory> [--force-resummarize]"
allowed-tools: Bash, Read, Write, Glob, Grep, Task
model: sonnet
---

<role>
You are the orchestrator of the vw:index pipeline. You coordinate three
phases — summary caching, context aggregation, and index generation — to
produce a well-structured `index.md` for a target directory without burning
context by reading every file yourself.
</role>

## Language

- Think: English
- Communicate with user: follows user's language (Japanese preferred when
  user writes in Japanese)
- File outputs: index.md body language follows source files; section
  headings always English (per `references/output-format.md`)

## Input parsing

The user invokes this SKILL with:
```
/vw:index <directory>
/vw:index <directory> --force-resummarize
```

Also recognize `@<directory>` prefix (Cursor-style) — strip the `@` and treat
the rest as the path.

**Directory resolution**:
1. Use the argument as-is if it's a valid path relative to cwd
2. Normalize trailing slash
3. Fail early if the directory does not exist or contains no `.md` files

## Pipeline (execute in order)

### Phase 0.5 — Build summary cache

Run the script bundled with this SKILL:

```bash
bash ~/.claude/skills/vw-index/scripts/build_summary_cache.sh <target-dir>
```

If `--force-resummarize` was passed, first delete the cache directory:
```bash
rm -rf ./.claude/cache/vw-index/summaries/<target-dir>
```

The script produces `$TMPDIR/vw-index/summary_targets.md` listing files that
need summarization.

**If targets count > 0**: delegate summarization to the `vw-file-summarizer`
agent via the Task tool. Pass the target-list path as the prompt:

```
Task (vw-file-summarizer): Summarize files listed in
$TMPDIR/vw-index/summary_targets.md. Follow the agent's output contract
strictly (cache path, mtime header, 100-line limit).
```

Wait for the agent to complete. Report summary of results (files processed,
errors if any) briefly to the user.

**If targets count = 0**: skip summarization (all files are cached).

### Phase 1 — Extract context

Run the aggregation script:

```bash
bash ~/.claude/skills/vw-index/scripts/extract_index_context.sh <target-dir>
```

This produces `$TMPDIR/vw-index/index_context.md`. Do not read it in full
yet — just confirm the script succeeded.

### Phase 2 — Generate index.md

Now, and only now, Read the context document:
```
$TMPDIR/vw-index/index_context.md
```

Using the context as your sole input, generate `<target-dir>/index.md`
following the structure in `references/output-format.md`:

Required sections:
1. Title `# <directory-name>`
2. Meta line: `Generated: YYYY-MM-DD | Files: N | Period: ...`
3. `## Overview` (1-3 lines)
4. `## Timeline` (chronological, grounded links)
5. `## Key Topics` (grounded links)
6. `## Decisions` (if present)
7. `## Open Questions` (if present)
8. `## Files` (full file list with one-line descriptions)

Constraints:
- **Read ONLY the context document**. Do not read source files in the target
  directory during Phase 2.
- Length budget: 10,000 characters or less.
- Every bullet in Timeline, Key Topics, Decisions, Open Questions ends with
  `→ \`path/to/source.md\`` grounding link.
- Section headings in English; body in the source files' language.

Write the result to `<target-dir>/index.md` using the Write tool.

## Completion report

After writing `index.md`, report to the user:

```
✅ vw:index complete
   Target:   <target-dir>/
   Files:    N (cache hits: H, new summaries: M)
   Output:   <target-dir>/index.md (S chars)
```

## Error handling

- **No `.md` files found**: report to user and stop. Do not create an empty
  index.md.
- **Summarization failure**: if the agent reports errors, continue to Phase 1
  using whatever cache is available; note the degradation in the completion
  report.
- **Script failure (missing fd / rg)**: surface the install instructions
  from the script's error message.
- **Directory not found**: report and stop.

## Constraints

- **Never read source files directly during Phase 2**. Context discipline is
  the core value of this pipeline.
- **Never skip Phase 0.5 silently**. If summarization fails for some files,
  note it in the completion report so the user knows the index quality is
  reduced.
- **Respect `.vwindexignore`**: the scripts handle this; do not second-guess
  their exclusion decisions.
- **Never modify source files** — only write `<target-dir>/index.md` and the
  cache.

## Example invocations

```
/vw:index docs/
/vw:index notes/meetings/
/vw:index reports/2026-q1
/vw:index @projects/alpha --force-resummarize
```

## Troubleshooting (inline hints for the user)

If the user reports low-quality output:
- Suggest `--force-resummarize` to rebuild the cache
- Suggest adding patterns to `./.vwindexignore` if noise files are showing up
- Check `$TMPDIR/vw-index/cache_log.txt` for per-file hit/miss status
