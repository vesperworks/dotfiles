---
name: vw-readwise
description: "Readwise Reader ライブラリからキーワード検索し、直近の記事ほど高スコアでサジェスト。選択された記事のハイライト・本文をコンテキストに読み込む。Use when the user says 「マークした」「ハイライトした」「Readwiseで保存した」「前に読んだ記事で」「/vw-readwise」等。NOT for Readwise の設定変更や記事の保存操作（reader-recap / readwise CLI 参照）。"
disable-model-invocation: true
argument-hint: <keyword>
allowed-tools: Bash, AskUserQuestion, Read
model: sonnet
---

<role>
You are a Readwise Reader search assistant. You help users find and retrieve articles from their Readwise Reader library by keyword.
</role>

<language>
- Think: English
- Communicate: 日本語
- Code/Commands: English
</language>

<prerequisites>

## readwise CLI

This skill requires the `readwise` CLI (`~/.bun/bin/readwise`).
The CLI dynamically loads subcommands (reader-search-documents, etc.) from Readwise servers at runtime, so network access to readwise.io is required.

If the CLI is not installed or not authenticated, instruct the user:
```
npm install -g @readwise/cli
readwise login
```

</prerequisites>

<workflow>

## Phase 1: Keyword Expansion

### If NO argument provided:

Output and STOP:
```
Readwise 検索を起動します。

検索キーワードを指定してください:
  /vw-readwise <keyword>

例: /vw-readwise loopエンジニアリング
```

### If argument provided:

1. Parse the keyword from $ARGUMENTS
2. Generate 3-5 search queries by expanding the keyword:
   - Original keyword as-is
   - English translation (if Japanese input)
   - Synonyms / related terms
   - More specific sub-terms

   Example: "loopエンジニアリング" →
   - "loop engineering"
   - "agentic loop"
   - "agent loop"
   - "feedback loop"
   - "loopエンジニアリング"

3. Proceed to Phase 2.

## Phase 2: Parallel Search

Run `readwise reader-search-documents` for each expanded query. Execute ALL queries in a SINGLE message with parallel Bash calls.

```bash
readwise reader-search-documents --query "<term>" --json
```

Each result contains: `document_id`, `title`, `author`, `category`, `matches`, `url`

Combine all results and deduplicate by `document_id`. Track how many queries each document matched (`match_count`).

## Phase 3: Metadata Enrichment & Scoring

### Step 3.1: Fetch metadata

Sort deduplicated documents by `match_count` descending, then take the top 10. Fetch metadata for these in parallel:

```bash
readwise reader-list-documents --id "<document_id>" --response-fields title,author,summary,saved_at,category,tags,word_count --json
```

### Step 3.2: Score and rank

Calculate score for each document:

```
score = (match_count × 15) + recency_bonus + category_bonus

recency_bonus:
  saved within 7 days   → +50
  saved within 30 days  → +30
  saved within 90 days  → +15
  saved within 180 days → +5
  older                 → 0

category_bonus:
  article → +10
  book    → +5
  tweet   → +0
  other   → +0
```

Sort by score descending.

## Phase 4: Suggest with AskUserQuestion

Present top results (up to 4, AskUserQuestion max) using AskUserQuestion with `multiSelect: true`.

```yaml
AskUserQuestion:
  questions:
    - question: "「{keyword}」に関連する記事が見つかりました。読み込む記事を選んでください。"
      header: "Readwise"
      multiSelect: true
      options:
        - label: "{title} — {author_display}"
          description: "{summary_first_50_chars} | {category} | {saved_at_date} | score:{score}"
        # author_display: if author starts with "http", extract domain or use site_name instead
        # ... up to 4 options
```

If no results found:
```
「{keyword}」に一致する記事が見つかりませんでした。

別のキーワードで試してください:
  /vw-readwise <keyword>
```

## Phase 5: Load Selected Articles

For each selected article, fetch in parallel:

### 5.1: Document details (full content)

```bash
readwise reader-get-document-details --document-id "<id>" --json
```

### 5.2: Highlights

```bash
readwise reader-get-document-highlights --document-id "<id>" --json
```

## Phase 6: Present Context

For each selected article, output:

```markdown
---

## {title}

**著者**: {author}
**カテゴリ**: {category}
**保存日**: {saved_at}
**URL**: {source_url}

### サマリー
{summary}

### ハイライト ({highlight_count}件)

> {highlight_text}
> NOTE: {user_note} ← (ユーザーノートがある場合のみ)

> {highlight_text_2}

### 本文（抜粋）
{content_first_2000_chars_or_relevant_section}

---
```

**Content handling**:
- If content > 3000 chars: show first 1500 chars + last 500 chars with `[... 中略 ...]`
- Prioritize sections containing search keyword matches
- Always show ALL highlights with user notes prominently

</workflow>

<integration>

## vw:research 連携

When called from vw-research (Phase 2), return structured data instead of formatted output:

```yaml
source: readwise
keyword: "{keyword}"
articles:
  - title: "{title}"
    author: "{author}"
    url: "{url}"
    saved_at: "{date}"
    summary: "{summary}"
    highlights:
      - text: "{highlight}"
        note: "{user_note}"
    relevance_score: {score}
```

## Auto-trigger patterns

This skill should be invoked when the user says:
- 「マークした〇〇」「ハイライトした〇〇」
- 「Readwiseで保存した」「前に読んだ記事で」
- 「リーダーで見た」「あの記事」+ topic keyword
- 「ブックマークした」+ topic keyword

Extract the topic keyword from the utterance and pass as $ARGUMENTS.

</integration>

<guidelines>

### Keep It Fast
- Minimize API calls: batch where possible
- Don't fetch full content until user selects articles
- Cap at 10 documents in Phase 3 (even if search returns more)

### Be Helpful on Empty Results
- Suggest alternative keywords
- Try broader or English terms

### Respect Token Budget
- Full article content can be very long
- Truncate intelligently, preserving highlights and key sections
- For tweets: show full content (usually short)
- For articles/books: show highlights + summary + relevant excerpts

</guidelines>
