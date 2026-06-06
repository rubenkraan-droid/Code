# Update n8n werkdocument

Append documentation for a new or updated n8n flow to the Notion n8n werkdocument.

**Page ID (never search, use directly):** `3732a868-d6bc-8171-9943-c0612dcde835`

Use `notion-update-page` with `command: insert_content` and `position: {type: end"}` — do NOT fetch or read the page first.

## What to include per flow

Write a section using this exact structure:

```
---
## Flow N — [Naam]
**Doel:** [één zin wat de flow doet]

**Trigger:** [wat de flow start]

**Wat de flow doet:**
1. [stap]
2. [stap]
...

**Config node — vul in per park:**
[welke waarden moeten worden ingevuld en waar je ze vindt]

**n8n nodes in volgorde:**
1. [node naam]
2. [node naam]
...
```

## When to call this skill

- After building or significantly modifying an n8n flow
- After changing the Config node structure
- After adding a new park

## What NOT to do

- Do not fetch the page before appending
- Do not rewrite existing sections unless explicitly asked
- Do not document dashboard HTML changes here (those go in the dashboard itself)
